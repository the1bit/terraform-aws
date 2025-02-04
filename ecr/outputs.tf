output "repository_url" {
  description = "URL of the created ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.repository.name
}

