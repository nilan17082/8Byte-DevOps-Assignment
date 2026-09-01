terraform {
  backend "s3" {
    bucket         = "8byte-tfstate-nilan"
    key            = "assignment/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "8byte-tf-locks"
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}