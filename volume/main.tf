provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}


locals {
  name   = "dtrifiro-gpu-volume"
  region = "eu-west-1"

  tags = {
    Terraform = "true"
    name      = "dtrifiro-gpu"
  }
}

resource "aws_ebs_volume" "ebsvolume" {
  availability_zone = data.aws_availability_zones.available.names[0] # has to match the instance it's attached to
  size              = 250
  encrypted         = false
  type              = "gp3"

  tags = local.tags
}


output "volume_id" {
  value       = aws_ebs_volume.ebsvolume.id
  description = "id of the created volume"
}
