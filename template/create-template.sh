#!/bin/bash

# Proxmox VM Template Creation Script
# Usage: ./create-template.sh --ssh-host HOST [OPTIONS]
#
# Required:
#   --ssh-host HOST          SSH host to connect to Proxmox
#
# Optional:
#   --vm-id ID               VM ID (default: 8000)
#   --storage STORAGE        Storage name (default: local-lvm)
#   --ssh-key FILE           SSH public key file (default: ~/.ssh/id_ed25519.pub)
#   -h, --help               Show this help message

set -e

# Default values
VM_ID="8000"
STORAGE="local-lvm"
SSH_HOST=""
SSH_KEY_FILE="$HOME/.ssh/id_ed25519.pub"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vm-id)
            VM_ID="$2"
            shift 2
            ;;
        --storage)
            STORAGE="$2"
            shift 2
            ;;
        --ssh-host)
            SSH_HOST="$2"
            shift 2
            ;;
        --ssh-key)
            SSH_KEY_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --ssh-host HOST [OPTIONS]"
            echo ""
            echo "Required:"
            echo "  --ssh-host HOST          SSH host to connect to Proxmox"
            echo ""
            echo "Optional:"
            echo "  --vm-id ID               VM ID (default: 8000)"
            echo "  --storage STORAGE        Storage name (default: local-lvm)"
            echo "  --ssh-key FILE           SSH public key file (default: ~/.ssh/id_ed25519.pub)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Cloud-init snippet path
CICUSTOM_SNIPPET="nfslorien:snippets/docker-cloud-init.yaml"

# Ubuntu cloud image
IMAGE_URL="https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
IMAGE_FILE="ubuntu-24.04-server-cloudimg-amd64.img"

# Validate SSH_HOST is provided
if [ -z "$SSH_HOST" ]; then
    echo "Error: --ssh-host is required"
    echo "Use --help for usage information"
    exit 1
fi

# Check if SSH key file exists
if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "Error: SSH key file not found: $SSH_KEY_FILE"
    echo "Please provide a valid SSH public key file path"
    exit 1
fi

# Read SSH public key
SSH_PUBLIC_KEY=$(cat "$SSH_KEY_FILE")

echo "=== Proxmox VM Template Creation ==="
echo "VM ID: $VM_ID"
echo "Storage: $STORAGE"
echo "SSH Host: $SSH_HOST"
echo "SSH Key: $SSH_KEY_FILE"
echo "Cloud-init snippet: $CICUSTOM_SNIPPET"
echo ""

# SSH command prefix
SSH="ssh $SSH_HOST"

echo "Step 1: Downloading Ubuntu cloud image..."
$SSH "wget -q --show-progress $IMAGE_URL || wget $IMAGE_URL"

echo ""
echo "Step 2: Creating VM..."
$SSH "qm create $VM_ID --memory 4096 --core 4 --cpu host --agent 1 --name ubuntu-cloud --net0 virtio,bridge=vmbr0"

echo ""
echo "Step 3: Importing disk..."
$SSH "qm disk import $VM_ID $IMAGE_FILE $STORAGE"

echo ""
echo "Step 4: Configuring VM..."
$SSH "qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0"
$SSH "qm set $VM_ID --ide2 $STORAGE:cloudinit"
$SSH "qm set $VM_ID --boot c --bootdisk scsi0"
$SSH "qm set $VM_ID --serial0 socket --vga serial0"

echo ""
echo "Step 5: Resizing disk..."
$SSH "qm resize $VM_ID scsi0 +16.5G"

echo ""
echo "Step 6: Setting cloud-init options..."
# Set DHCP for IPv4 and IPv6
$SSH "qm set $VM_ID --ipconfig0 ip=dhcp,ip6=dhcp"
# Set SSH key
$SSH "qm set $VM_ID --sshkeys <(echo '$SSH_PUBLIC_KEY')" || $SSH "qm set $VM_ID --sshkey \"$SSH_PUBLIC_KEY\""

echo ""
echo "Step 7: Setting cloud-init custom config..."
$SSH "qm set $VM_ID --cicustom \"user=$CICUSTOM_SNIPPET\""

echo ""
echo "=== VM $VM_ID created successfully! ==="
echo ""
echo "Cloud-init configured with:"
echo "  - DHCP enabled for IPv4 and IPv6"
echo "  - SSH key from: $SSH_KEY_FILE"
echo ""
echo "IMPORTANT: Before converting to template, verify:"
echo "  - Cloud-init config at /mnt/pve/nfslorien/snippets/docker-cloud-init.yaml"
echo "  - Set username/password if needed via: ssh $SSH_HOST 'qm set $VM_ID --ciuser <user> --cipassword <pass>'"
echo ""

read -p "Do you want to convert VM $VM_ID to a template now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Converting VM $VM_ID to template..."
    $SSH "qm template $VM_ID"
    echo "✓ VM $VM_ID converted to template successfully!"
else
    echo "Skipping template conversion. You can convert it later with:"
    echo "  ssh $SSH_HOST 'qm template $VM_ID'"
fi

echo ""
echo "Done!"
