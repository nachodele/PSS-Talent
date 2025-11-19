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
