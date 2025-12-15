output "instance_public_ip" {
  description = "IP pública del entorno PR"
  value       = aws_instance.pr_instance.public_ip
}

output "instance_id" {
  description = "ID de la instancia"
  value       = aws_instance.pr_instance.id
}

output "url_entorno" {
  description = "URL completa del entorno"
  value       = "http://${aws_instance.pr_instance.public_ip}"
}

output "key_name" {
  description = "Key pair creado"
  value       = aws_key_pair.pr_key.key_name
}
