variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "pr_id" {
  description = "GitHub PR number"
  type        = string
  default     = "0" # ← ya no es obligatorio
}

variable "allowed_ssh_cidr" {
  description = "CIDR para SSH"
  type        = string
  default     = "0.0.0.0/0"
}
