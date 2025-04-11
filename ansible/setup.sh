#!/bin/bash

# Run initial setup
ansible-playbook -i inventory.ini playbooks/01-cluster-init.yml
ansible-playbook -i inventory.ini playbooks/02-join-workers.yml -vvv
ansible-playbook -i inventory.ini playbooks/03-calico.yml -vvv
ansible-playbook -i inventory.ini playbooks/04-apply-bgp-conf.yml -vvv

# Try BGP peers with automatic recovery
MAX_RETRIES=3
ATTEMPT=1
while [ $ATTEMPT -le $MAX_RETRIES ]; do
  echo "Attempt $ATTEMPT of $MAX_RETRIES to apply BGP peers"
  ansible-playbook -i inventory.ini playbooks/05-apply-bgp-peers.yml -vvv
  
  # Verify success
  if [ $? -eq 0 ]; then
    echo "BGP peers applied successfully"
    break
  fi
  
  # On failure, run recovery
  echo "BGP peer application failed, running recovery..."
  ansible-playbook -i inventory.ini playbooks/00-reset-calico.yml -vvv
  
  ATTEMPT=$((ATTEMPT+1))
done

if [ $ATTEMPT -gt $MAX_RETRIES ]; then
  echo "Failed to apply BGP peers after $MAX_RETRIES attempts"
  exit 1
fi