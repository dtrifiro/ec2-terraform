data "aws_availability_zones" "available" {}


locals {
  tags = {
    Terraform = "true"
    name      = var.name
  }

  availability_zone = data.aws_availability_zones.available.names[0] # has to match the instance it's attached to
}

resource "aws_ebs_volume" "ebsvolume" {
  availability_zone = local.availability_zone
  size              = 250
  encrypted         = false
  type              = "gp3"

  tags = local.tags
}
