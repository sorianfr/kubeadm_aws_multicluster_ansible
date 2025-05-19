output "control_plane_ip" {
  value = aws_instance.controlplane.private_ip
}

output "debug_cluster_name" {
  value = var.cluster_name
}

output "debug_bgp_peers" {
  value = jsonencode(var.bgp_peers)
}

output "resolved_bgp_peers" {
  value = local.resolved_bgp_peers
}

output "worker_ebs_volumes" {
  description = "List of EBS volume IDs for worker nodes"
  value = [for vol in aws_ebs_volume.worker_ebs : vol.id]
}

output "worker_ebs_attachments" {
  description = "EBS volume attachments to worker instances"
  value = [for att in aws_volume_attachment.worker_ebs_attach : {
    device_name = att.device_name
    volume_id   = att.volume_id
    instance_id = att.instance_id
  }]
}