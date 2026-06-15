output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}