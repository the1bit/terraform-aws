provider "aws" {
  region = var.aws_region
}

# Create an ECR repository
resource "aws_ecr_repository" "repository" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE" # Allows adding/removing tags
  force_delete         = true      # Deletes the repository even if images exist
}

# Add a lifecycle policy to the ECR repository
resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.repository.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Never delete images tagged with 'prod'"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 99999 # Set a very high number to effectively never expire
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep the last 5 images with 'prod-' prefix"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete all other untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


# Example of adding/removing specific tags (for demonstration)
# resource "null_resource" "manage_image_tags" {
#   provisioner "local-exec" {
#     command = <<EOT
#       aws ecr batch-delete-image --repository-name ${aws_ecr_repository.my_repository.name} --image-ids imageTag=${var.remove_image_tag} || echo "Tag not found or already removed"
#       aws ecr put-image --repository-name ${aws_ecr_repository.my_repository.name} --image-tag ${var.add_image_tag} --image-manifest ${var.image_manifest}
#     EOT
#   }
# }
