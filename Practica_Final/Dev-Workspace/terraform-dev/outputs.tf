output "website_endpoint" {
  description = "URL pública del sitio web estático en S3"
  value       = "http://${data.aws_s3_bucket.existing_bucket.bucket}.s3-website.${var.region}.amazonaws.com"
}
