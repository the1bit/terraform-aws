terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}


data "aws_iam_policy_document" "logging_custom_trust_policy" {
  statement {
    sid     = "federated"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::004770426262:root"]
    }
  }

}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.6"

  bucket                   = "cm-s3-logging-2025"
  create_bucket            = true
  force_destroy            = true
  acl                      = "log-delivery-write"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true # required for directory buckets
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  logging = {
    target_bucket = "cm-s3-logging-2025"
    target_prefix = "log/cm-s3-logging-2025-logs/"
  }

  # Bucket policies
  attach_policy = true
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Id": "cm-s3-logging-2025",
  "Statement": [
    {
      "Sid": "EnforceHttpsAlways",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "arn:aws:s3:::cm-s3-logging-2025/*",
        "arn:aws:s3:::cm-s3-logging-2025"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "ReadWrite",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::004770426262:user/bucket-admin",
          "arn:aws:iam::004770426262:role/${module.iam_assumable_role.iam_role_name}"
        ]
      },
      "Action": [
        "s3:PutObjectAcl",
        "s3:PutObject",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucket",
        "s3:GetObjectVersion",
        "s3:GetObject",
        "s3:GetBucketLocation",
        "s3:DeleteObjectVersion",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::cm-s3-logging-2025/*",
        "arn:aws:s3:::cm-s3-logging-2025"
      ]
    },
    {
      "Sid": "ReadOnly",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::004770426262:user/bucket-admin"
      },
      "Action": [
        "s3:ListBucketMultipartUploads",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::cm-s3-logging-2025/*",
        "arn:aws:s3:::cm-s3-logging-2025"
      ]
    }
  ]
}
EOF

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }


  lifecycle_rule = [
    {
      id      = "cs-playground-logging-expire"
      enabled = true
      prefix  = ""

      expiration = {
        days = 30
      }

      abort_incomplete_multipart_upload_days = 7
    },
    {
      id      = "cs-playground-flow-expire"
      enabled = true
      prefix  = ""

      expiration = {
        days = 7
      }

      abort_incomplete_multipart_upload_days = 7
    }
  ]



}

module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "v5.54.0"

  name = "bucket-admin"
}

# module "iam_policy" {
#   source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version     = "v5.54.0"
#   name        = "logging-s3-read-role"
#   path        = "/"
#   description = "Reader role: logging-s3-read-role"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "s3:*"
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.44"

  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.logging_custom_trust_policy.json

  #   trusted_role_arns = [
  #     "arn:aws:iam::004770426262:user/bucket-admin"
  #   ]

  create_role             = true
  role_requires_mfa       = false
  create_instance_profile = true
  role_name               = "logging-s3-read-role"

  inline_policy_statements = [
    {
      sid = "LoggingStorage"
      actions = [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetBucketLocation",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ]
      effect = "Allow"
      resources = [
        "arn:aws:s3:::cm-s3-logging-2025",
        "arn:aws:s3:::cm-s3-logging-2025/*"
      ]
    }
  ]

}

resource "aws_iam_policy" "s3_read_access" {
  name        = "s3-read-access-policy"
  description = "Allows read access to the specific S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:GetObject", "s3:ListBucket"],
      Resource = [
        "${module.s3_bucket.s3_bucket_arn}",
        "${module.s3_bucket.s3_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_user_policy_attachment" "bucket_admin_read" {
  user       = module.iam_user.iam_user_name
  policy_arn = aws_iam_policy.s3_read_access.arn
}

resource "aws_iam_role_policy_attachment" "logging_s3_read" {
  role       = module.iam_assumable_role.iam_role_name
  policy_arn = aws_iam_policy.s3_read_access.arn
}
