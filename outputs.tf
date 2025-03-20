# Output for debugging or verification
output "cluster_details" {
  value = local.cluster_details
}

output "bastion_dns" {
  value = aws_instance.bastion.public_dns
}
