#!/bin/bash

echo "Setting up UFW through ansible to allow SSH web traffic, and monitoring..."
sleep 3

sudo ansible-playbook ../playbooks/firewall.yaml