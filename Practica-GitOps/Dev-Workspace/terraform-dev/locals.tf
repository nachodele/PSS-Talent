locals {
  public_subnets = [
    { name = "public-subnet-1", cidr = var.public_subnets_cidrs[0], az = var.availability_zones[0] },
    { name = "public-subnet-2", cidr = var.public_subnets_cidrs[1], az = var.availability_zones[1] }
  ]
  private_subnets = [
    { name = "private-subnet-1", cidr = var.private_subnets_cidrs[0], az = var.availability_zones[0] },
    { name = "private-subnet-2", cidr = var.private_subnets_cidrs[1], az = var.availability_zones[1] }
  ]

  project     = "practica-gitops"
  common_tags = {
    Environment = "Terraform"
    Project     = local.project
    Owner       = "nachodele"
  }
}
