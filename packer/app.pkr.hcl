packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "base_ami" {
  type    = string
  default = "${env("AWS_ID_AMI_UNUNTU22_4G")}"
}

variable "instance_size" {
  type    = string
  default = "t2.micro"
}

variable "region" {
  type    = string
  default = "${env("AWS_DEFAULT_REGION")}"
}

source "amazon-ebs" "flask" {
  ami_name      = "ubuntu22-flask"
  instance_type = "${var.instance_size}"
  region        = "${var.region}"
  source_ami    = "${var.base_ami}"
  ssh_timeout   = "10m"
  ssh_username  = "ubuntu"
  tags = {
    BuiltBy  = "Packer"
    OS       = "Ubuntu 22.04 with 4 Gb root partition"
    Project  = "Devops"
    ami_type = "Flask applications with Gunicorn and Nginx"
  }
}

build {
  sources = ["source.amazon-ebs.flask"]

  provisioner "file" {
    destination = "/home/ubuntu/app.env"
    source      = "app.env"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y git mariadb-server",
      "sudo apt-get install -y unzip jq",
      "sudo apt-get install -y python3-pip python3.10-venv default-libmysqlclient-dev build-essential pkg-config",
      "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip",
      "unzip /tmp/awscliv2.zip -d /tmp/ && sudo /tmp/aws/install",
      "sudo apt-get install -y nginx"
    ]
  }

  provisioner "shell" {
    execute_command = "{{ .Path }}"
    script          = "initialize.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
