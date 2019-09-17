provider "aws" {
  region = "${terraform.workspace}"
}

locals {
  env = "${terraform.workspace}"
}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = "workers"

  cidr = "10.0.0.0/16"

  azs             = ["${local.env}a", "${local.env}b", "${local.env}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6 = true

  enable_nat_gateway = true
  single_nat_gateway = true

  vpc_tags = {
    Name = "workers"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_configuration" "lc" {
  name_prefix                 = "workers-"
  image_id                    = "${data.aws_ami.amazon-linux-2.id}"
  instance_type               = "${var.instance_type}"
  user_data                   = "${file("files/instance_user_data")}"
  key_name                    = "${aws_key_pair.kp.id}"
  security_groups             = ["${aws_security_group.ssh.id}"]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${aws_launch_configuration.lc.name}"
  max_size                  = "${var.workers}"
  min_size                  = "${var.workers}"
  desired_capacity          = "${var.workers}"
  health_check_grace_period = 60
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.lc.name}"
  vpc_zone_identifier       = "${module.vpc.public_subnets}"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "workers"
    propagate_at_launch = true
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.private_key.private_key_pem}\" > files/default.pem; chmod 400 files/default.pem"
  }
}

resource "aws_key_pair" "kp" {
  key_name   = "default"
  public_key = "${tls_private_key.private_key.public_key_openssh}"
}

resource "aws_security_group" "ssh" {
  name_prefix = "ssh-"
  description = "Allow SSH inbound"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.admin_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
