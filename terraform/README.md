set -o allexport; source ./awscli/.env; set +o allexport
sudo apt install terraform
mkdir terraform && cd terraform
terraform init
terraform plan
