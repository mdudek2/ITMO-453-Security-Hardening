#!/bin/bash

# This script is run by virtualbox on the server when running provision.sh

# install nginx prometheus and open-ssh-server
apt install nginx prometheus openssh-server -y

# enable nginx
systemctl enable nginx
systemctl start nginx

# enable ssh
systemctl enable ssh
systemctl start ssh

# enable prometheus
systemctl enable prometheus
systemctl start prometheus

# Find the name of the second network interface
IFACE2=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | sed -n '2p')

# Define the static IP you want this specific guest VM to have
GUEST_STATIC_IP="192.168.56.230" 

echo "Configuring static IP $GUEST_STATIC_IP on interface $IFACE2..."

# Overwrite Netplan to keep nic1 on DHCP (NAT) and force nic2 to be static
cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
    ${IFACE2}:
      dhcp4: false
      addresses:
        - ${GUEST_STATIC_IP}/24
EOF

# Apply the new network setup inside the guest
chmod 600 /etc/netplan/01-netcfg.yaml
netplan apply

# allow password authentication temporarily so that the ssh key can be copied over
# this will be disabled by an ansible play after all virtual machines start successfully
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

reboot now