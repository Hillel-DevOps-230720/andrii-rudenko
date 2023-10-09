source "amazon-ebs" "template" {

  region               = "${var.region}"
  instance_type        = "${var.type}"
  ssh_timeout          = "${var.timeout}"
  ssh_username         = "${var.user}"
  iam_instance_profile = "${var.profile}"

}
