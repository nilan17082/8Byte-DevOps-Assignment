# 1. Log Groups (Centralized Logging for Apps)
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/8byte-app-logs"
  retention_in_days = 7
}

# 2. SNS Topic for Alerts (The "Get Paged" integration)
resource "aws_sns_topic" "alerts" {
  name = "8byte-alerts-topic"
}

# (Optional but recommended) Subscribe your email to the alerts
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com" # Change this to your actual email address!
}

# 3. High CPU Alarm (Triggers if CPU goes over 80%)
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "8byte-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.app_cluster.name
    ServiceName = aws_ecs_service.app_service.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# 4. Dashboard 1: Infrastructure & App Metrics 
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "8Byte-App-Infra-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.app_cluster.name],
            [".", "MemoryUtilization", ".", "."]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "ECS CPU & Memory"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app_alb.arn_suffix],
            [".", "TargetResponseTime", "TargetGroup", aws_lb_target_group.app_tg.arn_suffix, "LoadBalancer", aws_lb.app_alb.arn_suffix]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "Request Count & Latency"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", aws_lb_target_group.app_tg.arn_suffix, "LoadBalancer", aws_lb.app_alb.arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "Error Rates (4XX / 5XX)"
        }
      }
    ]
  })
}

# 5. Dashboard 2: Database Metrics
resource "aws_cloudwatch_dashboard" "db_dashboard" {
  dashboard_name = "8Byte-Database-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.postgres.identifier],
            [".", "DatabaseConnections", ".", "."]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "RDS Database Metrics"
        }
      }
    ]
  })
}