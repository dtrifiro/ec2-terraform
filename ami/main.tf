provider "aws" {
  region = var.region
}

data "aws_instance" "instance" {
  instance_id = var.instance_id
}

resource "aws_ami_from_instance" "ami" {
  name               = var.name
  source_instance_id = var.instance_id
}
