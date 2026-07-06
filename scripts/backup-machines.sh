#!/bin/bash

vm_dir="$HOME/itmo-453-lab2-vms"
backup_dir="$HOME/itmo-453-backups/"

echo "Starting virtual machine backup..."
sleep 3

VBoxManage list vms |
while read -r line; do
    vm=$(echo "$line" | sed 's/^"\(.*\)" {.*}$/\1/')

    if [[ $vm =~ ^itmo-453-.* ]]; then
        
        echo "Shutting down $vm..."
        VBoxManage controlvm "$vm" poweroff
        sleep 5
        
        echo "Backing up $vm to $backup_dir/$vm"
        cp "$vm_dir/$vm.vdi" "$backup_dir/"
        echo "Done backing up $vm..."
    fi
done

echo "All Machines have been backed up!"
