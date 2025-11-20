variable "region" {
  description = "La región AWS donde se desplegarán los recursos"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidrs" {
  description = "CIDR blocks for the public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  type        = list(string)
}

variable "private_subnets_cidrs" {
  description = "CIDR blocks for the private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones to use"
  default     = ["ap-south-1a", "ap-south-1b"]
  type        = list(string)
}

variable "rds_password" {
  description = "Contraseña para la instancia RDS PostgreSQL"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiaZL/31r1TvVi/4OXevkMYraxq457OUC+uz0KaNf4BHFqV6ZmsLrSQCK8IfNHzvJcE9QhMSYTsi0bQ/bwAemF6HSH5ClwqmLB6GY0WMZ2teC8o3/G9u1AweY0wzVlCYPQH8i9It/WGOk3gCEFPuNp6gZg5831Pl3MFFRxAmuNx4iD4n1WQ+MFltIbvuQ4lA2/e4v8mmdt65q70iWVsFzzxV58W5Xv0sqrNf5MS1/ciO2m/WCDE8eTzVd6iBV5z6FGvdAKCMyxP3wPs2moV/2E6+jKQJ9GsCJ0qPA/UgI5lx+El98g8hQkLf9fK3TqzzPgos/KFvStAA5Nq6hl/aR6kX20TsfV7zUl0MshqtFMa6VYCEJcPHWtBwskLl5QED+zBEnMJxkQJcnnk1pXuvurTS1RGKa+O9xanw+te1jDVlEHzSfCvc1Uke/NwfRnI0pd1adYn9LFyxsH/N9kSRYdm7p7T9oRGuuW3jK/92yYRK3vauLR2lSfzAn5+HEjTwgc67K1mxrz+AS9ecHUMQ1geE0SRjqUh0C/vsKn9kmjlLoDCUg5Syef+EHIZ9HtRGnYxxxv2imNCa32OPi5jGoSxMnCblZ9rmfwObzGR36UWFUbGnf4cqPezYg+3o13x+zFDc8eDvTctysrkuic42qCLi+SsC1lLgbgUM//Eq0BZw== vagrant@control"
  description = "Clave pública SSH para las instancias"
  type        = string
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_tags" {
  type    = map(string)
  default = {}
}
