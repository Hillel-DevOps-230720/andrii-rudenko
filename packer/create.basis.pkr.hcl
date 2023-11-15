build {

  name = "basis"

  source "sources.amazon-ebs.template" {
    ami_name = "basis"

    source_ami_filter {
      most_recent = true
      owners      = ["self"]
      filters = {
        "tag:project" : "${var.project}"
        "tag:target" : "shrink"
      }
    }

    tags = {
      project = "${var.project}"
      target  = "basis"
    }
  }

  provisioner "ansible" {
    playbook_file   = "../ansible/create.basis.yml"
  }

  # provisioner "shell" {
  #   script          = "create.basis.sh"
  #   execute_command = "{{ .Path }}"
  # }

  # post-processor "manifest" {
  #   output = "manifest.json"
  # }

}
