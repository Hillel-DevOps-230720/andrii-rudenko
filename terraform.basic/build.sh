#!/bin/bash

# TERRAFORM, VPC, AND WHY YOU WANT A TFSTATE FILE PER ENV
# https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/

# Terraform: planning a new project with Dev/Prod environments
# https://rtfm.co.ua/terraform-pochatok-roboti-ta-planuvannya-novogo-proektu-dev-prod-ta-bootsrap/

# Terraform: remote state with AWS S3, and state locking with DynamoDB
# https://rtfm.co.ua/en/terraform-remote-state-with-aws-s3-and-state-locking-with-dynamodb/

# Terraform: dynamic remote state with AWS S3 and multiple environments by directory
# https://rtfm.co.ua/en/terraform-dynamic-remote-state-with-aws-s3-and-multiple-environments-by-directory/

# Terrastrap - Bootstrap a S3 & DynamoDB Backend for Terraform
# https://github.com/dozyio/terrastrap

# How to Create Terraform Multiple Environments
# https://getbetterdevops.io/terraform-create-infrastructure-in-multiple-environments/

# 20 Terraform Best Practices to Improve your TF workflow
# https://spacelift.io/blog/terraform-best-practices#how-to-structure-your-terraform-projects

# What are Terraform Dynamic Blocks – Examples
# https://spacelift.io/blog/terraform-dynamic-blocks

terraform --version
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
sudo ln -s ~/.tfenv/bin/* /usr/local/bin
tfenv -v
tfenv list-remote
tfenv install 1.6.3
tfenv use 1.6.3
exit
terraform --version

cd bootstrap/
terraform init && terraform apply
# Uncomment S3 backend in backend.tf
terraform init -backend-config=backend.hcl
aws s3 ls tf-state-hillel/bootstrap/

cd environments/dev/
terraform init -backend-config=../../backend.hcl
terraform apply -var-file="dev.tfvars"
terraform destroy -var-file="dev.tfvars"

cd environments/prod/
terraform init -backend-config=../../backend.hcl
terraform apply -var-file="prod.tfvars"

cd environments/ansible/
terraform init -backend-config=../../backend.hcl
terraform apply -var-file="ansible.tfvars"
terraform destroy -var-file="ansible.tfvars"
