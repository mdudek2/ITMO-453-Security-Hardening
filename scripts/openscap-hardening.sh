#!/bin/bash

# deploy site using ansible
echo "Performing comprehensive hardening via openscap..."

sleep 3
sudo ansible-playbook ../playbooks/scap-compliance.yaml