provider "aws" {
  region  = "eu-central-1"
  profile = "rapyd-sentinel"
}

module "backend" {
  source      = "../../modules/backend"
  environment = "dev"
  region      = "eu-central-1"
}