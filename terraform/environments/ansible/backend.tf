terraform {
  backend "s3" {
    key = "ansible/terraform.tfstate"
  }
}
