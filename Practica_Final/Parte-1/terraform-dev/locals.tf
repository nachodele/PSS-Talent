locals {
  project     = "proyecto-final-pss"  # Todo en minúsculas y sin espacios
  common_tags = {
    Environment = "Terraform"
    Project     = local.project
    Owner       = "nachodele"
  }
}

locals {
  website_files = {
    "index.html" = "${path.module}/files/index.html"
    "error.html" = "${path.module}/files/error.html"
  }
}
