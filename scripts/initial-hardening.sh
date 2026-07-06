#!/bin/bash

# generate a key to be used for ssh on the host machine
echo "Generating an ssh key that will be used for administration on deployed servers..."
sleep 3

if [ ! -f ~/.ssh/lab2-ssh-key ]; then
  ssh-keygen -t ed25519 \
    -f ~/.ssh/project-ssh-key \
    -N "" \
    -C "automatically generated as part of lab2 deployment" \
    -q
fi

# use an ansible playbook to insert the key into each machine and harden ssh
echo "Performing initial hardening for all webservers..."
sleep 3
sudo ansible-playbook ../playbooks/harden.yaml