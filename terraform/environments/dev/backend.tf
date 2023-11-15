terraform {
  backend "s3" {
    key = "development/terraform.tfstate"
  }
}
