#!/bin/bash

echo "Running teardown script..."
sleep 3

# destroy the hosts file and make a new empty one
echo "Deleting ansible hosts file..."
sleep 3
sudo rm /etc/ansible/hosts
sudo touch /etc/ansible/hosts

# destroy virtualbox machines
echo "Shutting down and destroying virtual machines..."

VBoxManage list vms |
while read -r line; do
    vm=$(echo "$line" | sed 's/^"\(.*\)" {.*}$/\1/')

    if [[ $vm =~ ^itmo-453-.* ]]; then
        echo "Deleting $vm"
        VBoxManage controlvm "$vm" poweroff
        sleep 5
        VBoxManage unregistervm "$vm" --delete
    fi
done

echo "All machines deleted!"