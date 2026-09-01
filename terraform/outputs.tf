# 1. The Website URL (So you can actually visit your app in a browser)
output "website_url" {
  description = "The public URL of the Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}"
}

# 2. The ECR Repository URL (Your CI/CD pipeline needs this to upload Docker images)
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

# 3. The Database Address (Just good to have for debugging)
output "database_endpoint" {
  description = "The connection endpoint for the PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}