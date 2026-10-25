output "ecr_repository_url" {
  description = "ECR repository URL for the Flask application"
  value       = aws_ecr_repository.tech2_app.repository_url
}