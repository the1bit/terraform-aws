provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}





# Community module
module "s3_bucket_from_module" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.6"
  # Name of the S3 bucket
  bucket = var.name
  # Enable to create
  create_bucket = var.enabled
  # Allow deletion of non-empty bucket
  force_destroy = var.force_destroy
  # Tags
  tags = var.tags

}

data "aws_iam_policy_document" "logging_custom_trust_policy" {
  statement {
    sid     = "federated"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EC2CloudMentorRole"]
    }
  }

}

data "aws_caller_identity" "current" {
  
  
}

module "S3_BUCKET_FOR_LOGGING" {
  source = "terraform-aws-modules/s3-bucket/aws"
  # enabled                     = true
  create_bucket = var.enabled
  #region                      = var.region
  # NOTE: NO REGION SETTINGS

  # name                        = var.s3_bucket_names["logging"]
  bucket = var.s3_bucket_names["logging"]

  # acl                         = var.s3_acl["logging"]
  acl              = var.s3_acl["logging"]
  object_ownership = "ObjectWriter"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true


  depends_on = [ aws_iam_role.read_only_aws_role ]

  #sse_algorithm               = var.s3_sse_algorithm["logging"]
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true # required for directory buckets
      apply_server_side_encryption_by_default = {
        sse_algorithm = var.s3_sse_algorithm["logging"]
      }
    }
  }

  # logging_target_bucket       = var.s3_bucket_names["logging"]
  # logging_target_prefix       = "log/${var.s3_bucket_names["logging"]}/"
  logging = {
    target_bucket = var.s3_bucket_names["logging"]
    target_prefix = "log/${var.s3_bucket_names["logging"]}-logs/"
  }

  # lifecycle_rules             = var.s3_bucket_rules["logging"]
  lifecycle_rule = var.s3_bucket_rules["logging"]


  #  default_tags                = var.default_tags
  # TODO: We must add the environment name to the tags!!!!!
  #   environment                 = var.environment
  tags = var.tags



  # public_access_blocked       = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # versioning                  = "Suspended"
  versioning = {
    enabled = false
  }

  # validate_encryption_headers = false
  # NOTE: Not needed, because everywhewre is set to false

  #  s3_actions                  = var.s3_actions
  # NOTE: No dedicated s3_actions, here you must define the whole policy in the policy variable
  # Bucket policy
  attach_policy = true
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Id": "${var.s3_bucket_names["logging"]}",
  "Statement": [
    {
      "Sid": "EnforceHttpsAlways",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_names["logging"]}/*",
        "arn:aws:s3:::${var.s3_bucket_names["logging"]}"
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
          "arn:aws:iam::004770426262:user/cicdmanager",
          "arn:aws:iam::004770426262:role/${aws_iam_role.read_only_aws_role.name}"
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
        "arn:aws:s3:::${var.s3_bucket_names["logging"]}/*",
        "arn:aws:s3:::${var.s3_bucket_names["logging"]}"
      ]
    },
    {
      "Sid": "ReadOnly",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::004770426262:user/cicdmanager"
      },
      "Action": [
        "s3:ListBucketMultipartUploads",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_names["logging"]}/*",
        "arn:aws:s3:::${var.s3_bucket_names["logging"]}"
      ]
    }
  ]
}
EOF
}

module "ROLE_LOGGING_SERVICEACCOUNT" {
  source     = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version    = "~> 5.44"
  depends_on = [data.aws_iam_policy_document.logging_custom_trust_policy]

  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.logging_custom_trust_policy.json

  create_role       = true
  role_requires_mfa = false

  role_name = "cm-logging-service-account"

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
        "${module.S3_BUCKET_FOR_LOGGING.s3_bucket_arn}",
        "${module.S3_BUCKET_FOR_LOGGING.s3_bucket_arn}/*",
        "${module.S3_BUCKET_FOR_LOGGING.s3_bucket_arn}",
        "${module.S3_BUCKET_FOR_LOGGING.s3_bucket_arn}/*"
      ]
    }
  ]

  tags = var.default_tags
}

# module "S3_BUCKET_FOR_LOGGING" {
#   source                      = "git::https://github.vodafone.com/VFDE-BusinessOnline/iac-s3.git//s3-bucket?ref=main"
#   create_read_write_role      = true
#   create_read_only_role       = false
#   read_write_role_principals  = local.s3_read_write_principals["logging"]
# }