apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: ${target_cluster}-svc-cidr 
spec: 
  cidr: ${target_cluster_service_cidr} 
  ipipMode: CrossSubnet 
  disabled: true 

---  

apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: ${target_cluster}-pod-cidr 
spec: 
  cidr: ${target_cluster_pod_subnet} 
  ipipMode: CrossSubnet 
  disabled: true 
