output "instance" {
  value       = module.ec2_instance.public_ip
  description = "Public IP address details"
}

output "username" {
  value       = "admin"
  description = "ssh username"
}

output "instance-id" {
  value       = module.ec2_instance.id
  description = "ec2 instance id"
}
