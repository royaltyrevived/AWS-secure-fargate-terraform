output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.services : k => v.arn }
}