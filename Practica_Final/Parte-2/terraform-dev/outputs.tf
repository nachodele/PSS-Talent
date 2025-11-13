output "private_key_pem" {
  description = "Clave privada SSH generada automáticamente"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}
