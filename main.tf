terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    Environment = var.project
    Onwer       = var.contact
    ManagedBy   = "Terraform"
  }
}

data "aws_region" "current" {}
