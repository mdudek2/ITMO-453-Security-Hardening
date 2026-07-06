#!/bin/bash

# deploy site using ansible
echo "Deploying all services via ansible..."

sleep 3
sudo ansible-playbook ../playbooks/deploy-services.yaml

