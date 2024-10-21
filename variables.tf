variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "name" {
  type    = string
  default = "dtrifiro-gpu"
}

variable "instance_type" {
  # "g4dn.xlarge"  # 4 cores, 16GB
  # "g4dn.2xlarge" # 8 cores, 32GB
  # "g4dn.4xlarge" # 16 cores, 64GB (tesla T4)
  # "g5.8xlarge" # 64 cores, 128GB, 1x24GB gpu (A10G)
  # "g5.12xlarge" # 48 cores, 192GB, 4x24GB gpus (A10G)
  # "p4d.24xlarge" # 96 cores, 1152GB, 8x40GB gpus (A100)
  # "p2.8xlarge" # 64 cores, 732GB, 8x24GB GPUs (K80)
  # "p2.16xlarge" # 64 cores, 732GB, 16xXXGB gpus (??)
  # "g5.48xlarge" # 192 cores, 768GB, 8x24GB gpus (??)
  # see the docs:
  # G5: https://aws.amazon.com/ec2/instance-types/g5/
  # G6: https://aws.amazon.com/ec2/instance-types/g6
  # P2: https://aws.amazon.com/ec2/instance-types/p2/
  # P4: https://aws.amazon.com/ec2/instance-types/g5/
  #
  # g6.xlarge 4 x86_64 16 250 ssd Up to 10 Gigabit 1
  # g6.2xlarge 8 x86_64 32 450 ssd Up to 10 Gigabit 1
  # g6.4xlarge 16 x86_64 64 600 ssd Up to 25 Gigabit 1
  # g6.8xlarge 32 x86_64 128 900 ssd 25 Gigabit 1
  # g6.12xlarge 48 x86_64 192 3760 ssd 40 Gigabit 4
  # g6.16xlarge 64 x86_64 256 1880 ssd 25 Gigabit 1
  # g6.24xlarge 96 x86_64 384 3760 ssd 50 Gigabit 4
  # g6.48xlarge 192 x86_64 768 7520 ssd 100 Gigabit 8

  type    = string
  default = "g5.8xlarge"
}


variable "ssh_key_name" {
  type    = string
  default = "dtrifiro@redhat.com"

}
variable "ssh_key_value" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBqKUU5xbvbd3SpX9tttv2oWZb0/njKxmNRMAI5DpSIf dtrifiro@redhat.com"
}


variable "persistent_volume_id" {
  type    = string
  default = null

  description = "Attach the specified persistent volume. Created if null."
}

variable "custom_ami" {
  type    = string
  default = null

  description = "Use the specified ami.`user_data.sh` is not run in this case."
}
