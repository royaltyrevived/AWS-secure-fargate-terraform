variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for load balanced services"
  type        = string
  default     = null
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "service_port" {
  description = "Service Connect port"
  type        = number
}

variable "cpu" {
  description = "CPU units"
  type        = string
}

variable "memory" {
  description = "Memory in MB"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
}

variable "load_balanced" {
  description = "Whether the service is load balanced"
  type        = bool
}

variable "environment_vars" {
  description = "Environment variables"
  type        = map(string)
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "task_execution_role_arn" {
  description = "Task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "Task role ARN"
  type        = string
}

variable "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  type        = string
}