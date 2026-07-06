#!/bin/bash

LOGGING_DIR="$HOME/itmo-453-logs/"

echo "Gathering logs from hosts in inventory..."
sleep 3
sudo ansible-playbook ../playbooks/collect-logs.yaml
echo "Logs saved to $LOGGING_DIR..."