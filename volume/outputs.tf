output "volume_name" {
  value       = aws_ebs_volume.ebsvolume.id
  description = "id of the created volume"
}

output "volume_id" {
  value       = aws_ebs_volume.ebsvolume.id
  description = "id of the created volume"
}

output "availability_zone" {
  value       = local.availability_zone
  description = "availability zone of the created volume"
}
