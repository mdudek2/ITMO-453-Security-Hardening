#!/bin/bash

echo "Executing a fully automated deployment..."
sleep 3
echo "You may be prompted for your sudo password one time..."
echo "Running provision.sh..."
bash provision.sh
sleep 3
echo "Running initial-hardening.sh..."
sleep 3
bash initial-hardening.sh
echo "Running setup-firewall.sh..."
bash setup-firewall.sh
sleep 3
#echo "Running openscap-hardening.sh..."
#echo "This will probably take a while..."
#sleep 3
#bash openscap-hardening.sh
#sleep 3
echo "running deploy-services.sh..."
bash deploy-services.sh
sleep 3
echo "Wrote server IPs to ansible inventory file..."
sleep 3
echo "Provisioning and configuration done!"
echo "------------Inventory File------------"
cat /etc/ansible/hosts
echo "------------Inventory File------------"