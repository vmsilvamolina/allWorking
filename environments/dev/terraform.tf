terraform {
  backend "s3" {
    bucket  = "vmsilvamolina-state"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
}
