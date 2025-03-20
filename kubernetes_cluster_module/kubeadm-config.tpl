---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
metadata:
  name: "${cluster_name}"
networking:
  podSubnet: "${pod_subnet}"  # Update to match your Tigera Calico CIDR
  serviceSubnet: "${service_cidr}" 
  dnsDomain: ${cluster_name}.local
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "${controlplane_ip}" # Update this with your control plane's private IP.
  bindPort: 6443
nodeRegistration:
  kubeletExtraArgs:
    node-ip: "${controlplane_ip}"

