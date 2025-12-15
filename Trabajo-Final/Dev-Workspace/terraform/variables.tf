variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "pr_id" {
  description = "GitHub PR number"
  type        = string
}

variable "ssh_public_key" {
  description = "Contenido ~/.ssh/nachodele_ssh_key.pub"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR para SSH"
  type        = string
  default     = "0.0.0.0/0"
}
