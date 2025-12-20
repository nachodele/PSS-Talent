output "alb_dns_name" {
  description = "ALB DNS para PR links"
  value       = aws_lb.pr_alb.dns_name
}

output "alb_health_url" {
  description = "Health check completo"
  value       = "http://${aws_lb.pr_alb.dns_name}/health"
}

output "alb_version_url" {
  description = "Version endpoint completo"
  value       = "http://${aws_lb.pr_alb.dns_name}/version"
}

output "instance_public_ip" {
  value = aws_instance.pr_instance.public_ip
}
