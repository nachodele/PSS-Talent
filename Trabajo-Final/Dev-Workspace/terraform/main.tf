terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
 # Backend S3 con DynamoDB locking - clave única por PR
  backend "s3" {
    bucket         = "trabajo-final-nachodele-pss"  
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-trabajo-final-nachodele"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
