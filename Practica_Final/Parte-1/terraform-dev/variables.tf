variable "additional_tags" {
  description = "Tags adicionales para el bucket"
  type        = map(string)
  default = {
    Purpose   = "Static Website Hosting"
    CreatedBy = "Terraform"
  }
}

variable "region" {
  description = "La región AWS donde se desplegarán los recursos"
  type        = string
  default     = "ap-south-1"
}
