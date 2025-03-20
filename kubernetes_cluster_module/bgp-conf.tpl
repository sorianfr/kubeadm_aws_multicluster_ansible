apiVersion: projectcalico.org/v3 
kind: BGPConfiguration 
metadata: 
  name: default 
spec: 
  logSeverityScreen: Info 
  asNumber: ${asn}
  serviceClusterIPs: 
    - cidr: "${service_cidr}"
