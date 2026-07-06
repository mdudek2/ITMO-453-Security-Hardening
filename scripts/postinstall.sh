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

# allow password authentication temporarily so that the ssh key can be copied over
# this will be disabled by an ansible play after all virtual machines start successfully
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

reboot now