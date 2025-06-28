# Define priority counter
locals {
  service_priorities = {
    for idx, key in keys(var.load_balanced_services) : key => idx + 100
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-sg"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
  
  enable_deletion_protection = false
  enable_http2              = true
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Create target groups for load-balanced services
resource "aws_lb_target_group" "services" {
  for_each = var.load_balanced_services
  
  name_prefix = substr("${each.key}-tg", 0, 6)
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = each.value.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  deregistration_delay = 30
  
  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-tg"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener rules for each service
resource "aws_lb_listener_rule" "services" {
  for_each = var.load_balanced_services
  
  listener_arn = aws_lb_listener.http.arn
  priority     = local.service_priorities[each.key]
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }
  
  condition {
    path_pattern {
      values = ["/${each.key}/*"]
    }
  }
}