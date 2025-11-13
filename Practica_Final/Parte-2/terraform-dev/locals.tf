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
