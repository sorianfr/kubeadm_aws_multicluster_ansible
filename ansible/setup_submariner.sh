#!/bin/bash

# Run initial setup
ansible-playbook -i inventory.ini playbooks/01-cluster-init.yml
ansible-playbook -i inventory.ini playbooks/02-join-workers.yml -vvv
ansible-playbook -i inventory.ini playbooks/prueba_kubectl.yml -vvv
