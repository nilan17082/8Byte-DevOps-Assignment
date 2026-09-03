# 1. ECR Repository (Where your CI/CD pipeline will save your Docker images)
resource "aws_ecr_repository" "app_repo" {
  name         = "8byte-app-repo"
  force_delete = true
}

# 2. IAM Role (Gives ECS permission to download your image and read secrets)
resource "aws_iam_role" "ecs_execution_role" {
  name = "8byte-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 🔐 FIX: Allow ECS to read the DB password from Secrets Manager
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "8byte-ecs-secrets-policy"
  description = "Allows ECS to read the DB password from Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.db_password.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# 3. ECS Cluster (The environment where your app lives)
resource "aws_ecs_cluster" "app_cluster" {
  name = "8byte-app-cluster"
}

# 4. Task Definition (The instructions for running your Docker container)
resource "aws_ecs_task_definition" "app_task" {
  family                   = "8byte-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name         = "8byte-app"
      image        = "nginx:latest" # Placeholder! Your CI/CD will update this.
      essential    = true
      portMappings = [{ containerPort = var.app_port, hostPort = var.app_port }]

      environment = [
        { name = "DB_HOST", value = aws_db_instance.postgres.address },
        { name = "DB_USER", value = aws_db_instance.postgres.username },
        { name = "DB_NAME", value = aws_db_instance.postgres.db_name }
      ]

      # 🔐 FIX: Injecting the database credentials securely!
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        }
      ]

      # 📝 FIX: Wire logs directly to CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/8byte-app-logs"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ==========================================
# 5. Staging Environment Service
# ==========================================
resource "aws_ecs_service" "app_service" {
  name            = "8byte-app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1 # Staging only needs 1 container
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "8byte-app"
    container_port   = var.app_port
  }
}

# ==========================================
# 6. Production Environment Service
# ==========================================
resource "aws_ecs_service" "prod_service" {
  name            = "8byte-app-service-prod"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2 # Production gets 2 instances for true High Availability
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prod_tg.arn # Points to Prod Target Group
    container_name   = "8byte-app"
    container_port   = var.app_port
  }
}

# 📈 FIX: Target Tracking Autoscaling (Min 2, Max 4 based on CPU) - NOW ATTACHED TO PROD
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.prod_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "8byte-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
}