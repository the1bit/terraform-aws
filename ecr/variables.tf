variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "cm-app"
}

variable "add_image_tag" {
  description = "Tag to be added to the image"
  type        = string
  default     = "prod"
}

variable "reference_tag" {
  description = "Tag to be referenced in the image"
  type        = string
  default     = "3.1.0"
}
