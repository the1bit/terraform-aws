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

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [module.iam_assumable_role.iam_role_arn]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::cm-s3-logging-2025"
    ]
  }
}


module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v4.6.0"

  bucket = "cm-s3-logging-2025"
  # acl removed to prevent ACL error
  object_ownership = "BucketOwnerEnforced"

  # Bucket policies
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }


}

module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "v5.54.0"

  name = "bucket-admin"
}

module "iam_policy" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version     = "v5.54.0"
  name        = "logging-s3-read-role"
  path        = "/"
  description = "Reader role: logging-s3-read-role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

module "iam_assumable_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::004770426262:root"
  ]

  create_role = true
  role_name   = "logging-s3-read-role"

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
  number_of_custom_role_policy_arns = 1
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
