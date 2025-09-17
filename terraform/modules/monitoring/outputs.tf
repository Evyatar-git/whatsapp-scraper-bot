output "prometheus_target_group_arn" {
  description = "Prometheus target group ARN"
  value       = var.enable_monitoring ? aws_lb_target_group.prometheus[0].arn : null
}

output "grafana_target_group_arn" {
  description = "Grafana target group ARN"
  value       = var.enable_monitoring ? aws_lb_target_group.grafana[0].arn : null
}

output "monitoring_security_group_id" {
  description = "Monitoring security group ID"
  value       = var.enable_monitoring ? aws_security_group.monitoring[0].id : null
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = var.enable_monitoring ? "http://${var.alb_dns_name}/prometheus" : null
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.enable_monitoring ? "http://${var.alb_dns_name}/grafana" : null
}
