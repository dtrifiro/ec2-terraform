provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  azs = slice(data.aws_availability_zones.available.names, 0, 1)

  create_volume = (var.persistent_volume_id == null)
  volume_id     = (local.create_volume ? module.volume_attachment[0].volume_id : var.persistent_volume_id)

  tags = {
    Terraform = "true"
    Name      = var.name
  }
}

module "volume_attachment" {
  source = "./volume"

  region = var.region
  name   = "${var.name}-volume"

  count = local.create_volume ? 1 : 0
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = var.name

  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group.security_group_id]
  # subnet_id                   = element(module.vpc.private_subnets, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true

  # hibernation = true # not supported in all cases, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hibernating-prerequisites.html

  user_data = var.custom_ami == null ? file("user_data.sh") : null

  tags = local.tags

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 500
      volume_size = 250
      tags = {
        Name = "${var.name}-root"
      }
    },
  ]

  ## We don't need to create one, we'll attach an already existing one
  #ebs_block_device = [
  #  {
  #    delete_on_termination = false
  #    device_name           = "/dev/sdf"
  #    volume_type           = "gp3"
  #    volume_size           = 250
  #    throughput            = 200
  #    # encrypted   = true
  #    #kms_key_id  = aws_kms_key.this.arn
  #    tags = {
  #      MountPoint = "/mnt/data"
  #    }
  #  }
  #]
}

## optional for encryption of the volumes
# resource "aws_kms_key" "this" {
# }

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = var.name
  description = "${var.name} security group"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = [
    # "http-80-tcp",
    "ssh-tcp",
    "all-icmp"
  ]
  egress_rules = ["all-all"]

  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  create_igw = true

  tags = local.tags
}


data "aws_ami" "ami" {
  most_recent = true
  # owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      var.custom_ami == null ? "debian-12-amd64-*" : var.custom_ami
    ]
  }
}

resource "aws_network_interface" "this" {
  subnet_id = element(module.vpc.private_subnets, 0)

  tags = local.tags
}

resource "aws_key_pair" "ssh-key" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_key_value

  tags = local.tags
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh" # FIXME: this device name is ignored
  instance_id = module.ec2_instance.id

  volume_id = local.create_volume ? module.volume_attachment[0].volume_id : var.persistent_volume_id
}


resource "null_resource" "wait-finished" {
  provisioner "remote-exec" {
    connection {
      host = module.ec2_instance.public_ip
      user = "root"

      ## use ssh agent to load the ssh key
      agent = true
      ## the given private key could also be given
      # private_key = file("~/.ssh/id_ed25519")
    }

    script = "wait_for_provisioning.sh"
  }

  ## local-exec could be used too
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -T 300 -i ${module.ec2_instance.public_ip},  --user admin --private-key files/id_rsa playbook.yml"
  # }
}
