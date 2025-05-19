# Output for debugging or verification
output "cluster_details" {
  value = local.cluster_details
}

output "bastion_dns" {
  value = aws_instance.bastion.public_dns
}

output "cluster1_worker_ebs_volumes" {
  value = module.kubernetes_clusters["cluster1"].worker_ebs_volumes
}

output "cluster1_worker_ebs_attachments" {
  value = module.kubernetes_clusters["cluster1"].worker_ebs_attachments
}