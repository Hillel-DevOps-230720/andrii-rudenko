build {

  name = "db"

  source "sources.amazon-ebs.template" {
    ami_name = "db"
    source_ami_filter {
      owners      = ["self"]
      most_recent = true
      filters = {
        "tag:project" : "${var.project}"
        "tag:target" : "basis"
      }
    }

    tags = {
      Name    = "db"
      project = "${var.project}"
      target  = "db"
    }
  }

  provisioner "ansible" {
    playbook_file   = "../ansible/create.db.yml"
    extra_arguments = [
      "--extra-vars",
      join(" ", [
        "db_name=${local.db_name}",
        "db_user=${local.db_user}",
        "db_password=${local.db_password}",
        "s3_name=${local.s3_name}",
      ])
    ]
  }

  # provisioner "file" {
  #   source      = "./db/"
  #   destination = "/tmp/"
  # }

  # provisioner "shell" {
  #   environment_vars = [
  #     "MYSQL_DB=${local.db_name}",
  #     "MYSQL_USER=${local.db_user}",
  #     "MYSQL_PASSWORD=${local.db_password}",
  #     "S3_NAME=${local.s3_name}",
  #   ]
  #   script = "create.db.sh"
  # }

  # post-processor "manifest" {
  #   output = "manifest.json"
  # }

}
