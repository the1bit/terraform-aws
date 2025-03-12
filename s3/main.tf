provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Community module
module "s3_bucket_from_module" {
  source = "terraform-aws-modules/s3-bucket/aws"
  # Name of the S3 bucket
  bucket = "devtest20250312"
  # Enable to create
  create_bucket = var.enabled
  # Allow deletion of non-empty bucket
  force_destroy = var.force_destroy
  # Tags
  tags = var.tags

}