[all]
%{ for cluster_name, cluster in local.cluster_details }
${cluster.control_plane.hostname} ansible_host=${cluster.control_plane.ip} ansible_user=ubuntu
%{ for worker in cluster.workers }
${worker.hostname} ansible_host=${worker.ip} ansible_user=ubuntu
%{ endfor }
%{ endfor }

[controlplanes]
%{ for cluster_name, cluster in local.cluster_details }
${cluster.control_plane.hostname}
%{ endfor }

[workers]
%{ for cluster_name, cluster in local.cluster_details }
%{ for worker in cluster.workers }
${worker.hostname}
%{ endfor }
%{ endfor }

[${cluster_name}]
%{ for cluster_name, cluster in local.cluster_details }
${cluster.control_plane.hostname}
%{ for worker in cluster.workers }
${worker.hostname}
%{ endfor }
%{ endfor }
