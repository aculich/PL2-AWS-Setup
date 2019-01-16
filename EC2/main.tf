################################################################################
# AMI Setup
locals {
  cis_owner_id = 679593333241
}

data "aws_ami" "cis_level_1_ami" {
  owners       = ["${local.cis_owner_id}"]
  name_regex   = "CIS Ubuntu Linux 16.04 LTS Benchmark Level 1"
}

################################################################################
# EC2 Instance Setup
resource "aws_instance" "EC2_analysis_instance" {
  ami           = "${data.aws_ami.cis_level_1_ami.id}"
  availability_zone = "${var.region}${var.availability_zone}"
  tenancy = "default"
  disable_api_termination = "true"
  instance_initiated_shutdown_behavior = "stop"
  instance_type = "${var.instance_type}"
  monitoring = "true"
  vpc_security_group_ids = "${var.security_group_ids}"

  tags = {
    Name = "${var.project_name}_EC2_analysis_instance"
  }
}


# Python Script for staying secure: https://www.cisecurity.org/python-script-for-staying-secure-with-the-latest-cis-amis/

################################################################################
# EBS Volume Setup
# https://www.terraform.io/docs/providers/aws/r/volume_attachment.html

#TODO: data._data_source_....
