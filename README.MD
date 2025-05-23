## Installation

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/sorianfr/kubeadm_aws_multicluster_ansible.git

2. Download and Install Terraform
   ```bash
   curl -o terraform.zip https://releases.hashicorp.com/terraform/1.5.6/terraform_1.5.6_linux_amd64.zip && unzip terraform.zip && sudo mv terraform /usr/local/bin/

3. AWS Configure
   
4. Initialize and Apply Terraform
   ```bash
   terraform init
   terraform apply
   ```

5. SSH onto Bastion
   ```bash
   ssh -i my_k8s_key.pem ubuntu@<BASTION_PUBLIC_DNS>

6. Run playbook
   ```bash
   cd ~/ansible

   ansible-playbook -i inventory.ini playbooks/01-cluster-init.yml
   ansible-playbook -i inventory.ini playbooks/02-join-workers.yml -vvv
   ansible-playbook -i inventory.ini playbooks/03-calico.yml -vvv
   ansible-playbook -i inventory.ini playbooks/04-apply-bgp-conf.yml -vvv
   ansible-playbook -i inventory.ini playbooks/05-apply-bgp-peers.yml -vvv

   ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbooks/kubeadm.yml
   ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbooks/join_workers.yml 
   ansible-playbook -i inventory.ini playbooks/test_calico.yml

   watch kubectl get pods -n calico-system
   kubectl get tigerastatus



   ansible-playbook -i inventory.ini playbooks/apply-bgp-conf.yml
   ansible-playbook -i inventory.ini playbooks/apply-bgp-peers.yml

   kubectl exec -n calico-system ds/calico-node -c calico-node -- birdcl show protocols
   kubectl exec -n calico-system ds/calico-node -c calico-node -- birdcl show route

   ansible-playbook -i inventory.ini playbooks/install-calicoctl-and-node-status.yml
   
   sudo calicoctl node status

   ansible-playbook -i inventory.ini playbooks/create-ippools.yml
   ansible-playbook -i inventory.ini playbooks/patch-felix-externalnodes.yml
   

   ansible-playbook -i inventory.ini playbooks/generate-dns-mappings.yml

## BGP Configuration

1. Cluster1
```bash
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  asNumber: 65001
  serviceClusterIPs:
    - cidr: 10.96.0.0/16
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  asNumber: 65002
  serviceClusterIPs:
    - cidr: 10.100.0.0/16
```

## BGP Peers

1. Cluster1
```bash
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c2-control  
spec:  
  peerIP: 10.0.3.10
  asNumber: 65002  
---  
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c2-worker  
spec:  
  peerIP: 10.0.3.11
  asNumber: 65002 
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c1-control  
spec:  
  peerIP: 10.0.2.10
  asNumber: 65001  
---  
apiVersion: projectcalico.org/v3  
kind: BGPPeer  
metadata:  
  name: bgp2c1-worker  
spec:  
  peerIP: 10.0.2.11
  asNumber: 65001 
```


## Calico Node Status
1. Cluster1
```bash
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c1-control-plane-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster1controlplane
  updatePeriodSeconds: 10
---
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c1-worker-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster1worker1
  updatePeriodSeconds: 10
```
2. Cluster2
```bash
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c2-control-plane-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster2controlplane
  updatePeriodSeconds: 10
---
apiVersion: projectcalico.org/v3
kind: CalicoNodeStatus
metadata:
  name: c2-worker-status
spec:
  classes:
    - Agent
    - BGP
    - Routes
  node: cluster2worker1
  updatePeriodSeconds: 10
```
## IPPools

1. Cluster1

```bash
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c2-svc-cidr 
spec: 
  cidr: 10.100.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false
---  
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c2-pod-cidr 
spec: 
  cidr: 10.245.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false 
```
2. Cluster2
```bash
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c1-svc-cidr 
spec: 
  cidr: 10.96.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false
---  
apiVersion: crd.projectcalico.org/v1 
kind: IPPool 
metadata: 
  name: c1-pod-cidr 
spec: 
  cidr: 10.244.0.0/16 
  ipipMode: CrossSubnet 
  disabled: false 
```

## FelixConfiguration

1. Copy & Paste


  ```bash
  kubectl patch felixconfiguration default --type='merge' -p "$(cat <<EOF
  {
    "spec": {
      "externalNodesList": [
        "$(nslookup cluster2controlplane | grep Address | tail -n 1 | awk '{print $2}')/32",
        "$(nslookup cluster2worker1 | grep Address | tail -n 1 | awk '{print $2}')/32"
      ]
    }
  }
  EOF
  )"
  ```

  

2. Copy & Paste


  ```bash
  kubectl patch felixconfiguration default --type='merge' -p "$(cat <<EOF
  {
    "spec": {
      "externalNodesList": [
        "$(nslookup cluster1controlplane | grep Address | tail -n 1 | awk '{print $2}')/32",
        "$(nslookup cluster1worker1 | grep Address | tail -n 1 | awk '{print $2}')/32"
      ]
    }
  }
  EOF
  )"
  ```


```bash
kubectl create deployment nginx --image=nginx 
```

```bash
kubectl create service nodeport nginx --tcp 80:80 
kubectl patch service nginx -p '{"spec":{"externalTrafficPolicy":"Local"}}'

```




```bash
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot   
```

 
```bash
kubectl rollout restart -n kube-system deployment/coredns 
```



```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

From bastion to download config files
```
scp -i "my_k8s_key.pem" ubuntu@10.0.2.10:.kube/config /home/ubuntu/cluster1_config
scp -i "my_k8s_key.pem" ubuntu@10.0.3.10:.kube/config /home/ubuntu/cluster2_config
```
Edit config files as they have the same name

```
export KUBECONFIG=~/cluster1_config:~/cluster2_config
kubectl config view --merge --flatten > ~/.kube/config
```


to port forward using private ip and port with bastion public ip
in your local machine:
```
ssh -i my_k8s_key.pem -L 8080:10.0.2.10:32510 ubuntu@ec2-54-144-247-55.compute-1.amazonaws.com
```

in the browser:
```
http://localhost:8080
```


ssh -i my_k8s_key.pem -L 8081:10.0.2.10:30287 ubuntu@ec2-54-144-247-55.compute-1.amazonaws.com


#submariner

curl -OL  https://github.com/submariner-io/releases/releases/download/v0.15.2/subctl-v0.15.2-linux-amd64.tar.xz
tar xf subctl-v0.15.2-linux-amd64.tar.xz

sudo mv subctl-v0.15.2/subctl-v0.15.2-linux-amd64 /usr/local/bin/subctl

sudo chmod +x /usr/local/bin/subctl


docker cp ~/.kube/config c1-control-plane:/root/.kube/config


scp -i "my_k8s_key.pem" ~/.kube/config ubuntu@10.0.2.10:~/kubeconfig

ssh -i "my_k8s_key.pem" ubuntu@10.0.2.10

sudo su

mkdir -p /root/.kube
mv /home/ubuntu/kubeconfig /root/.kube/config
chown root:root /root/.kube/config
chmod 600 /root/.kube/config

subctl deploy-broker --context cluster1


subctl join broker-info.subm \
  --context cluster1 \
  --clusterid cluster1 \
  --cable-driver none \
  --servicecidr 10.96.0.0/16 \
  --clustercidr 10.244.0.0/16

subctl join broker-info.subm \
  --context cluster2 \
  --clusterid cluster2 \
  --cable-driver none \
  --servicecidr 10.100.0.0/16 \
  --clustercidr 10.245.0.0/16