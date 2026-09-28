terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every taggable resource, so individual resources only
  # need to set their own Name tag.
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}