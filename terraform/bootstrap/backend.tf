terraform {
  # Comment out when creating a local state
  backend "s3" {
    key = "bootstrap/terraform.tfstate"
  }
}
