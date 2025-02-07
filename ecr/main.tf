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

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Never delete images tagged with 'prod'",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["prod"],
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 999999
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep the last 3 images with 'prod-' prefix",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["prod-"],
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 3,
      "description": "Keep the latest version of images with tags starting with 0",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["0"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 4,
      "description": "Keep the latest version of images with tags starting with 1",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["1"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 5,
      "description": "Keep the latest version of images with tags starting with 2",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["2"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 6,
      "description": "Keep the latest version of images with tags starting with 3",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["3"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 7,
      "description": "Keep the latest version of images with tags starting with 4",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["4"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 8,
      "description": "Delete all other untagged images after 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 9,
      "description": "Delete all other tagged images after 1 day",
      "selection": {
        "tagStatus": "any",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}


# data "aws_ecr_image" "prod_prefix_tag" {
#   repository_name = aws_ecr_repository.repository.name
#   image_digest    = var.image_digest
#   image_tag       = "${var.add_image_tag}-${var.reference_tag}"
# }

# Example of adding/removing specific tags (for demonstration)
resource "null_resource" "manage_image_tags" {
  provisioner "local-exec" {
    command = <<EOT
      # Delete the existing tag if it exists
      DELETE_OUTPUT=$(aws ecr batch-delete-image --repository-name ${aws_ecr_repository.repository.name} --image-ids imageTag=${var.add_image_tag} 2>&1)
      if echo "$DELETE_OUTPUT" | grep -q "requested image not found"; then
        echo "Image with tag '${var.add_image_tag}' does not exist in repository"
      else
        echo "Existing image tag '${var.add_image_tag}' deleted successfully (if it existed)."
      fi

      # Get image manifest
      IMAGE_MANIFEST=$(aws ecr batch-get-image --repository-name ${aws_ecr_repository.repository.name} \
                        --image-ids imageTag=${var.reference_tag} \
                        --query 'images[0].imageManifest' \
                        --output text 2>&1)

      if echo "$IMAGE_MANIFEST" | grep -q "requested image not found"; then
        echo "ERROR: Reference image with tag '${var.reference_tag}' does not exist in repository $REPO_NAME. Cannot create new tag."
        exit 1
      fi

      # Get the image manifest and add the protection tag
      aws ecr put-image --repository-name ${aws_ecr_repository.repository.name} \
                        --image-tag ${var.add_image_tag} \
                        --image-manifest "$IMAGE_MANIFEST" 2>&1
     if [ $? -eq 0 ]; then
        echo "Successfully added tag '${var.add_image_tag}' to image in repository $REPO_NAME."
      else
        echo "Tag '${var.add_image_tag}' already exists in repository $REPO_NAME."
      fi


     # Get the image manifest and re-tag the image
      aws ecr put-image --repository-name ${aws_ecr_repository.repository.name} \
                        --image-tag "${var.add_image_tag}-${var.reference_tag}" \
                        --image-manifest "$IMAGE_MANIFEST" 2>&1
      if [ $? -eq 0 ]; then
        echo "Successfully added tag '${var.add_image_tag}-${var.reference_tag}' to image in repository $REPO_NAME."
      else
        echo "Tag '${var.add_image_tag}-${var.reference_tag}' already exists in repository $REPO_NAME."
      fi
    EOT
  }

  # This forces Terraform to see a change every time
  triggers = {
    always_run = timestamp()
  }
}
