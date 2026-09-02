variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "app_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 3000
}

# ==========================================
# 📧 Alerting Variable
# ==========================================
variable "alert_email" {
  description = "The email address to receive SNS pipeline and infrastructure alerts"
  type        = string
  default     = "admin@example.com" # Fallback default to prevent apply errors
}