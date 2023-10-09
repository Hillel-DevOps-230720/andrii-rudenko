build {

  name = "db"

  source "sources.amazon-ebs.template" {
    ami_name = "database"

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
      target  = "db"
    }
  }

  provisioner "file" {
    source      = "./db/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    environment_vars = [
      "MYSQL_DB=${local.db_name}",
      "MYSQL_USER=${local.db_user}",
      "MYSQL_PASSWORD=${local.db_password}",
      "S3_NAME=${local.s3_name}",
    ]
    script = "create.db.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

}
