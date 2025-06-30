variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = ""
}

# RDS Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "services" {
  description = "Map of ECS services to deploy"
  type = map(object({
    ecr_repo_name     = string
    container_port    = number
    service_port      = number  # For service connect
    cpu               = string
    memory            = string
    desired_count     = number
    min_capacity      = number
    max_capacity      = number
    health_check_path = string
    load_balanced     = bool
    environment_vars  = map(string)
  }))
  default = {
    service1 = {
      ecr_repo_name     = "service repo"
      container_port    = 3001
      service_port      = 9001
      cpu               = "256"
      memory            = "512"
      desired_count     = 2
      min_capacity      = 1
      max_capacity      = 4
      health_check_path = "/health"
      load_balanced     = true
      environment_vars  = {}
    }
    service2 = {
      ecr_repo_name     = "service repo"
      container_port    = 4222
      service_port      = 4222
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      min_capacity      = 1
      max_capacity      = 2
      health_check_path = "/"
      load_balanced     = false
      environment_vars  = {}
    }
    service3 = {
      ecr_repo_name     = "service repo"
      container_port    = 6379
      service_port      = 6379
      cpu               = "256"
      memory            = "512"
      desired_count     = 1
      min_capacity      = 1
      max_capacity      = 2
      health_check_path = "/"
      load_balanced     = false
      environment_vars  = {}
    }
  }
}
