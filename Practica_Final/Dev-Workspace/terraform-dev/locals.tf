# Definición de subredes públicas y privadas
locals {
  public_subnets = [
    for idx, az in var.availability_zones :
    {
      az      = az
      cidr    = var.public_subnets_cidrs[idx]
      name    = "public-subnet-${idx + 1}"
    }
  ]

  private_subnets = [
    for idx, az in var.availability_zones :
    {
      az      = az
      cidr    = var.private_subnets_cidrs[idx]
      name    = "private-subnet-${idx + 1}"
    }
  ]
}

# Definición de tags comunes
locals {
  project     = "proyecto-final-pss"
  common_tags = {
    Environment = "Terraform"
    Project     = local.project
    Owner       = "nachodele"
  }
}

# Mapeo de archivos
locals {
  website_files = {
    "index.html" = "${path.module}/files/index.html"
    "error.html" = "${path.module}/files/error.html"
  }
}
