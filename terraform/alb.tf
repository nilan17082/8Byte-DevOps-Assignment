# 0. Get the AWS ELB Service Account ID (Required for bucket permissions)
data "aws_elb_service_account" "main" {}

# 1. S3 Bucket for ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "8byte-alb-access-logs-nilan"
  force_destroy = true # Makes it easy to clean up during terraform destroy
}

# 2. Bucket Policy to allow the Load Balancer to write logs to the bucket
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"
      }
    ]
  })
}

# 3. The Load Balancer (Sits in the public subnets to face the internet)
resource "aws_lb" "app_alb" {
  name               = "app-8byte-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  # 📝 FIX: Enable real ALB access logs directly to S3
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.alb_logs_policy]

  tags = {
    Name = "8byte-alb"
  }
}

# 4. Staging Target Group (The existing group for your Staging environment)
resource "aws_lb_target_group" "app_tg" {
  name        = "8byte-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# 4b. Production Target Group (The new group for your Production environment)
resource "aws_lb_target_group" "prod_tg" {
  name        = "8byte-prod-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# 5. Production Listener (Port 80 -> Production Target Group)
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_tg.arn
  }
}

# 6. Staging Listener (Port 8080 -> Staging Target Group)
resource "aws_lb_listener" "staging_front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}