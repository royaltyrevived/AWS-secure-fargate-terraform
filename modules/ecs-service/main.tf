locals {
  container_name = var.service_name
  account_id     = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = 7
  
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.service_name}-logs"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "service" {
  family                   = "${var.service_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn           = var.task_role_arn
  
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  
  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_repo_name}:latest"
      cpu       = 0
      essential = true
      
      portMappings = [
        {
          name          = "${var.service_name}-${var.container_port}-tcp"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      
      environment = [
        for k, v in merge(
          var.environment_vars,
          {
            ENVIRONMENT = var.environment
            RDS_ENDPOINT = var.rds_endpoint
          }
        ) : {
          name  = k
          value = v
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
          "mode"                  = "non-blocking"
          "max-buffer-size"       = "25m"
        }
      }
      
      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])
  
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.service_name}-task"
  }
}

# ECS Service - WITHOUT Service Connect
resource "aws_ecs_service" "service" {
  name                              = "${var.service_name}-service"
  cluster                           = var.cluster_id
  task_definition                   = aws_ecs_task_definition.service.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  enable_execute_command            = true
  health_check_grace_period_seconds = var.load_balanced ? 60 : null
  
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  
  dynamic "load_balancer" {
    for_each = var.load_balanced && var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }
  
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  deployment_controller {
    type = "ECS"
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-${var.service_name}-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "service" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}