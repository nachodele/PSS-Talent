terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "proyecto-final-pss-nachodele-8540ad6a"
    key    = "backend/state.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.region
}

provider "random" {}
