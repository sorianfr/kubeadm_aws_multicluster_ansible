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
