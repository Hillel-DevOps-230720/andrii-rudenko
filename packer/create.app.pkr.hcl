build {

  name = "app"

  source "sources.amazon-ebs.template" {
    ami_name = "app"

    source_ami_filter {
      owners      = ["self"]
      most_recent = true
      filters = {
        "tag:project" : "${var.project}"
        "tag:target" : "basis"
      }
    }

    tags = {
      project = "${var.project}"
      target  = "app"
    }
  }

  provisioner "file" {
    source      = "./app/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    environment_vars = [
      "MYSQL_DB=${local.db_name}",
      "MYSQL_USER=${local.db_user}",
      "MYSQL_PASSWORD=${local.db_password}",
      "MYSQL_HOST=${local.db_ip_local}",
      "SECRET_KEY=${local.app_key}",
      "APP_PORT=${local.app_port}",
      "APP_URL=${local.app_url}",
    ]
    script = "create.app.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

}
