provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "alb" {
  source = "./modules/alb"
  
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  certificate_arn = var.certificate_arn
  
  # Pass load-balanced services to ALB module
  load_balanced_services = {
    for k, v in var.services : k => v if v.load_balanced
  }
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"
  
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.security_group_id
}

module "rds" {
  source = "./modules/rds"
  
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  ecs_security_group_id = module.ecs_cluster.ecs_security_group_id
  
  # RDS configuration
  db_instance_class = var.db_instance_class
  db_name          = var.db_name
  db_username      = var.db_username
  db_password      = var.db_password
}

module "ecs_services" {
  source = "./modules/ecs-service"
  for_each = var.services
  
  service_name          = each.key
  project_name          = var.project_name
  environment           = var.environment
  cluster_id            = module.ecs_cluster.cluster_id
  cluster_name          = module.ecs_cluster.cluster_name
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  ecs_security_group_id = module.ecs_cluster.ecs_security_group_id
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = var.services[each.key].load_balanced ? module.alb.target_group_arns[each.key] : null
  
  # Service specific configurations
  ecr_repo_name     = each.value.ecr_repo_name
  container_port    = each.value.container_port
  service_port      = each.value.service_port
  cpu               = each.value.cpu
  memory            = each.value.memory
  desired_count     = each.value.desired_count
  min_capacity      = each.value.min_capacity
  max_capacity      = each.value.max_capacity
  load_balanced     = each.value.load_balanced
  environment_vars  = each.value.environment_vars
  
  # Add RDS endpoint as environment variable if needed
  rds_endpoint = module.rds.endpoint
  
  # Pass required role ARNs and namespace
  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn = module.ecs_cluster.task_role_arn
  service_discovery_namespace_id = module.ecs_cluster.service_discovery_namespace_id
}