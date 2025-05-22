Python Virtual Environment for Ansible host:

# 1. Make sure venv is installed
sudo apt install -y python3-venv python3-full

# 2. Create a virtual environment
python3 -m venv ~/.venvs/ansible-k8s

# 3. Activate the virtual environment
source ~/.venvs/ansible-k8s/bin/activate

# 4. Upgrade pip (optional but good)
pip install --upgrade pip

# 5. Install required Python packages
pip install kubernetes openshift

# 6. Install Ansible and the Kubernetes collection (if not already done)
pip install ansible
ansible-galaxy collection install kubernetes.core


after running the playbook/rol


To Connect:

ssh -i "my_k8s_key.pem" -L 8085:10.0.2.11:30080 ubunt
u@ec2-3-235-1-196.compute-1.amazonaws.com

In Bastion:

kubectl --context=cluster1 -n argocd port-forward svc/argocd-server 8085:443

In Local Machine:

ssh -i "my_k8s_key.pem" -L 8085:localhost:8085 ubuntu@ec2-18-234-208-120.compute-1.amazonaws.com   

In Browser:
https://localhost:8085

To Get the Password:

kubectl --context=cluster1 -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo


Seeing an App in Localmachine (App has to be NodePort to do it this way)

ssh -i "my_k8s_key.pem" -L 8085:10.0.2.11:30080 ubuntu@ec2-3-235-1-196.compute-1.amazonaws.com
                           local_port:node_id:nodeport ubuntu@bastion_dns           
