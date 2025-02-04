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

variable "remove_image_tag" {
  description = "Tag to be removed from the image"
  type        = string
  default     = "old-tag"
}

variable "image_manifest" {
  description = "Base64-encoded image manifest for pushing a new tag"
  type        = string
  default     = ""
}
