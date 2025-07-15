terraform {
  backend "s3" {
    bucket         = "rapyd-sentinel-tf-state-dev-eu-central-1"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    profile        = "rapyd-sentinel"
    # dynamodb_table = "rapyd-sentinel-tf-lock-dev"
  }
}
