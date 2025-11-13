output "website_endpoint" {
  description = "URL pública del sitio web estático en S3"
  value       = "http://${aws_s3_bucket.project_bucket.bucket}.s3-website.${var.region}.amazonaws.com"
}

