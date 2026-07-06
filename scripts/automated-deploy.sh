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
echo "running deploy-services.sh..."
bash deploy-services.sh
#echo "Running openscap-hardening.sh..."
#echo "This will probably take a while..."
#sleep 10
#bash openscap-hardening.sh