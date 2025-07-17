terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.3.0"
    }
  }

  backend "s3" {
    bucket         = "rapyd-sentinel-tf-state-dev-eu-central-1"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "rapyd-sentinel-tf-lock-dev"
  }
}
