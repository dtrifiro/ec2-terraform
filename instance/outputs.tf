output "region" {
  value       = var.region
  description = "Region"
}

output "instance_name" {
  value       = var.name
  description = "Public IP address details"
}

output "instance_ip" {
  value       = module.ec2_instance.public_ip
  description = "Public IP address details"
}

output "instance_type" {
  value       = var.instance_type
  description = "Instance type"
}

output "ami" {
  value       = data.aws_ami.debian.name
  description = "Name of the ami used for the instasnce"
}

output "username" {
  value       = "admin"
  description = "ssh username"
}

output "instance_id" {
  value       = module.ec2_instance.id
  description = "ec2 instance id"
}

output "persistent_volume_id" {
  value       = module.volume_attachment.volume_id
  description = "persistent attached volume id"
}
