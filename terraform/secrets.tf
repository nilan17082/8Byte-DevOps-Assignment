# Generate a random 20-character password
resource "random_password" "db" {
  length  = 20
  special = false
}

# Create the Secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "8byte/db-password-nilan"
  recovery_window_in_days = 0 # Forces immediate deletion if we destroy the environment
}

# Store the random password inside the Secret
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}