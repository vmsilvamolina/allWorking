terraform {
  backend "s3" {
    bucket  = "vmsilvamolina-state"
    key     = "prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
}
