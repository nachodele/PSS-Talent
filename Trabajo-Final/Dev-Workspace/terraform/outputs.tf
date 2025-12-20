output "alb_dns_name" {
  description = "ALB DNS para PR links"
  value       = aws_lb.pr_alb.dns_name
}