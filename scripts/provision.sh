#!/bin/bash
set -e

# VM Configuration vars
VM_BASE_NAME="itmo-453-web"
PROMETHEUS_NAME="itmo-453-prometheus"
VM_COUNT=1
VM_RAM=8192
VM_CPUS=4
VM_DISK_SIZE=25000
VM_DIR="$HOME/itmo-453-lab2-vms"
ISO_PATH="$HOME/isos/ubuntu-24.04.4-live-server-amd64.iso"
HOSTONLY_IF="vboxnet0"
NETWORK_NAME="lab2nat"
DHCP_IP="192.168.56.100"
INVENTORY="/etc/ansible/hosts"
GROUPNAME="labproject"

mkdir -p "$VM_DIR"

# Create a NAT network so that virtual machines can communicate with each other
if ! VBoxManage list natnetworks | grep -q "^Name:.*${NETWORK_NAME}$"; then
  VBoxManage natnetwork add \
    --netname "$NETWORK_NAME" \
    --network "192.168.100.0/24" \
    --enable \
    --dhcp on
fi

# start multiple VMs using a for loop
for i in $(seq 1 "$VM_COUNT"); do

  VM_NAME="${VM_BASE_NAME}-${i}"

  echo "Creating VM: $VM_NAME"

  VBoxManage createvm --name "$VM_NAME" \
    --ostype Ubuntu_64 \
    --register

  VBoxManage modifyvm "$VM_NAME" \
    --memory "$VM_RAM" \
    --cpus "$VM_CPUS" \
    --nic1 natnetwork \
    --nat-network1 "$NETWORK_NAME" \
    --nic2 hostonly --hostonlyadapter2 "$HOSTONLY_IF" \
    --vram 16 \
    --graphicscontroller vmsvga

  VBoxManage createmedium disk --filename "$VM_DIR/$VM_NAME.vdi" \
    --size "$VM_DISK_SIZE"

  VBoxManage storagectl "$VM_NAME" --name SATA --add sata --controller IntelAhci

  VBoxManage storageattach "$VM_NAME" \
    --storagectl SATA \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$VM_DIR/$VM_NAME.vdi"

  VBoxManage storagectl "$VM_NAME" --name IDE --add ide

  VBoxManage storageattach "$VM_NAME" \
    --storagectl IDE \
    --port 0 \
    --device 0 \
    --type dvddrive \
    --medium "$ISO_PATH"

  VBoxManage unattended install "$VM_NAME" \
    --iso="$ISO_PATH" \
    --user=ubuntu \
    --full-user-name=ubuntu \
    --password ubuntu \
    --time-zone=America/Chicago \
    --post-install-template="postinstall.sh"

  VBoxManage startvm "$VM_NAME" --type headless

done

# Wait for a few minutes so that unattended install finishes
echo "Sleeping for a few minutes to give VM's time to finish installing."
sleep 600

# Output all IP addresses on vboxnet0 
# 192.168.56.100 is the dhcp server
echo "Scanning vboxnet0 to find IPs..."

# Create inventory if it doesn't exist
sudo touch "$INVENTORY"

# Add group header for webservers if missing
if ! grep -Fxq "[$GROUPNAME]" "$INVENTORY"; then
    echo "[$GROUPNAME]" | sudo tee -a "$INVENTORY" > /dev/null
fi

# add each newly discovered IP to the inventory if it isn't already present
while IFS= read -r ip; do
    if ! grep -Fxq "$ip" "$INVENTORY"; then
        echo "$ip" | sudo tee -a "$INVENTORY" > /dev/null
        echo "Added $ip"
    else
        echo "Skipping $ip (already present)"
    fi
done < <(
    sudo arp-scan --interface=vboxnet0 192.168.56.0/24 |
    awk -v exclude="$DHCP_IP" '
        /^[0-9]+\./ && $1 != exclude {
            print $1
        }
    '
)

echo "Wrote server IPs to ansible inventory file..."
sleep 3
echo "Provisioning Done! You can now use ansible for additional configuration."

echo "------------Inventory File------------"
cat /etc/ansible/hosts
echo "------------Inventory File------------"