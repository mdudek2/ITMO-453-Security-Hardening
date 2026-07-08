#!/bin/bash
set -e

# VM Configuration vars
VM_BASE_NAME="itmo-453-web"
VM_COUNT=1
VM_RAM=8192
VM_CPUS=4
VM_DISK_SIZE=25000
VM_DIR="$HOME/itmo-453-lab2-vms"
ISO_PATH="$HOME/isos/ubuntu-24.04.4-live-server-amd64.iso"
HOSTONLY_IF="vboxnet0"
HOSTONLY_IP="192.168.56.10"
HOSTONLY_MASK="255.255.255.0"
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

# Statically configure the Host-Only Interface on the Host Machine
echo "Configuring host-only interface: $HOSTONLY_IF with IP $HOSTONLY_IP"

# Ensure the host-only interface actually exists; if not, create it
if ! VBoxManage list hostonlyifs | grep -q "^Name:.*${HOSTONLY_IF}"; then
  VBoxManage hostonlyif create
fi

# Set the static IP and netmask for the host adapter (this is the host's gateway IP)
VBoxManage hostonlyif ipconfig "$HOSTONLY_IF" --ip "$HOSTONLY_IP" --netmask "$HOSTONLY_MASK"

# Completely REMOVE VirtualBox's built-in DHCP server for this interface to stop it from offering IPs
if VBoxManage list dhcpservers | grep -q "NetworkName:.*HostInterfaceNetworking-${HOSTONLY_IF}"; then
  echo "Removing VirtualBox DHCP server for $HOSTONLY_IF"
  VBoxManage dhcpserver remove --ifname "$HOSTONLY_IF" || true
fi

# remove the old key from ssh to prevent issues with remote host id
echo "Removing old host key from ssh..."
sudo ssh-keygen -f '/root/.ssh/known_hosts' -R '192.168.56.230'
sudo ssh-keygen -f '/home/maks/.ssh/known_hosts' -R '192.168.56.230'

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