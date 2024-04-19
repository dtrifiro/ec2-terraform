provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "dtrifiro-gpu"
  region = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  # azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  azs = slice(data.aws_availability_zones.available.names, 0, 1)

  ssh_key_name  = "dtrifiro@redhat.com"
  ssh_key_value = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqKUU5xbvbd3SpX9tttv2oWZb0/njKxmNRMAI5DpSIf dtrifiro@redhat.com"
  user_data     = file("user_data.sh")

  attached_ebs_volume = "vol-0c7e20d989aabd157" # created via the volume module

  tags = {
    Terraform = "true"
    Name      = local.name
  }
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = local.name

  ami                    = data.aws_ami.debian.id
  instance_type          = "g4dn.xlarge"
  key_name               = local.ssh_key_name
  monitoring             = true
  vpc_security_group_ids = [module.security_group.security_group_id]
  # subnet_id                   = element(module.vpc.private_subnets, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true

  # hibernation = true # not supported in all cases, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hibernating-prerequisites.html

  user_data = local.user_data

  tags = local.tags

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 250
      tags = {
        Name = "dtrifiro-gpu-root"
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

  name        = local.name
  description = "dtrifiro-gpu security group"
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

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  create_igw = true

  tags = local.tags
}


data "aws_ami" "debian" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"] # change here to use a different AMI
    # values = ["amazon/RHEL-9*x86_64*"]
  }
}

resource "aws_network_interface" "this" {
  subnet_id = element(module.vpc.private_subnets, 0)

  tags = local.tags
}

resource "aws_key_pair" "ssh-key" {
  key_name   = local.ssh_key_name
  public_key = local.ssh_key_value

  tags = local.tags
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh" # FIXME: this device name is ignored
  volume_id   = local.attached_ebs_volume
  instance_id = module.ec2_instance.id
}


resource "null_resource" "wait-finished" {
  provisioner "remote-exec" {
    connection {
      host = module.ec2_instance.public_ip
      user = "admin"

      ## use ssh agent to load the ssh key
      agent = true
      ## the given private key could also be given
      # private_key = file("~/.ssh/id_ed25519")
    }

    inline = ["until [ -f /var/lib/cloud/instance/boot-finished ]; do echo \"Waiting for provisioning...\" && sleep 1; done"]
  }

  ## local-exec could be used too
  # provisioner "local-exec" {
  #   command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -T 300 -i ${module.ec2_instance.public_ip},  --user admin --private-key files/id_rsa playbook.yml"
  # }
}
