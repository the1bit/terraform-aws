variable "aws_profile" {
  description = "The AWS profile to use for the S3 bucket"
  type        = string
  default     = "cloudsteak"
}

variable "aws_region" {
  description = "The AWS region where the S3 bucket will be created"
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "enabled" {
  description = "A boolean that indicates whether the S3 bucket should be created"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default = {
    Environment  = "dev"
    ForceDestroy = "true"
  }
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = true
}
