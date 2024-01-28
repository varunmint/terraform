terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
          }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "create_vpc" {

    cidr_block = "10.0.0.0/16"
    tags = {
      Environment  = "Production"
    }
      
}