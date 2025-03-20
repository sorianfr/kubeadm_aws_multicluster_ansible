apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: ${cluster_name}-${node_name}-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: ${node_name}
  updatePeriodSeconds: 10
