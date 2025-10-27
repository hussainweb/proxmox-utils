#!/usr/bin/env bash

set -e

# Default values
NODE="erebor"
CORES=2
MEMORY=2048
DISK_SIZE="20G"
PASSWORD=""
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
BIOS="ovmf"  # UEFI
STORAGE="local-lvm"
CLONE_TEMPLATE_ID=""

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Create a new Proxmox VM using Terraform with cloud-init support.

Required Options:
    --hostname HOSTNAME         Hostname for the VM
    --vmid VMID                VMID for the VM

Optional:
    --password PASSWORD         Root password for the VM (default: blank)
    --disk DISK                Disk size (default: 20G)
    --cores CORES              CPU cores (default: 2)
    --memory MEMORY            RAM in MB (default: 2048)
    --bios BIOS                BIOS type: ovmf (UEFI) or seabios (default: ovmf)
    --node NODE                Proxmox node (default: erebor)
    --storage STORAGE          Storage for VM disks (default: local-lvm)
    --clone-from TEMPLATE_ID   Clone from existing template ID (optional)
    --ssh-key PATH             Path to SSH public key (default: ~/.ssh/id_ed25519.pub)
    -h, --help                 Show this help message

Example:
    $0 --hostname myvm --vmid 100
    $0 --hostname myvm --vmid 100 --clone-from 9000 --disk 30G --cores 4

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        --vmid)
            VMID="$2"
            shift 2
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        --disk)
            DISK_SIZE="$2"
            shift 2
            ;;
        --cores)
            CORES="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --bios)
            BIOS="$2"
            shift 2
            ;;
        --node)
            NODE="$2"
            shift 2
            ;;
        --storage)
            STORAGE="$2"
            shift 2
            ;;
        --clone-from)
            CLONE_TEMPLATE_ID="$2"
            shift 2
            ;;
        --ssh-key)
            SSH_PUBLIC_KEY_PATH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$HOSTNAME" || -z "$VMID" ]]; then
    echo "Error: Missing required parameters"
    usage
fi

# Validate BIOS type
if [[ "$BIOS" != "ovmf" && "$BIOS" != "seabios" ]]; then
    echo "Error: BIOS must be either 'ovmf' or 'seabios'"
    exit 1
fi

# Check if SSH public key exists
if [[ ! -f "$SSH_PUBLIC_KEY_PATH" ]]; then
    echo "Error: SSH public key not found at $SSH_PUBLIC_KEY_PATH"
    exit 1
fi

# Read SSH public key
SSH_PUBLIC_KEY=$(cat "$SSH_PUBLIC_KEY_PATH")

# Create terraform.tfvars
cat > terraform.tfvars << EOF
vmid               = $VMID
hostname           = "$HOSTNAME"
disk_size          = "$DISK_SIZE"
cores              = $CORES
memory             = $MEMORY
node               = "$NODE"
password           = "$PASSWORD"
bios               = "$BIOS"
storage            = "$STORAGE"
clone_template_id  = $CLONE_TEMPLATE_ID
ssh_public_keys    = <<-EOT
$SSH_PUBLIC_KEY
EOT
EOF

# Create state directory if it doesn't exist
STATE_DIR="./states"
mkdir -p "$STATE_DIR"

# Set state file path based on VMID
STATE_FILE="$STATE_DIR/terraform-$VMID.tfstate"

echo "Created terraform.tfvars with the following configuration:"
echo "  VMID: $VMID"
echo "  Hostname: $HOSTNAME"
echo "  Disk: $DISK_SIZE"
echo "  Cores: $CORES"
echo "  Memory: $MEMORY MB"
echo "  BIOS: $BIOS"
echo "  Node: $NODE"
echo "  Storage: $STORAGE"
if [[ -n "$CLONE_TEMPLATE_ID" ]]; then
    echo "  Clone from template: $CLONE_TEMPLATE_ID"
fi
echo "  SSH Key: $SSH_PUBLIC_KEY_PATH"
echo "  State File: $STATE_FILE"
echo ""

# Initialize terraform if not already initialized
if [[ ! -d ".terraform" ]]; then
    echo "Initializing Terraform..."
    terraform init
    echo ""
fi

# Apply terraform configuration
echo "Creating VM..."
terraform apply -state="$STATE_FILE" -auto-approve

echo ""
echo "VM created successfully!"
echo "State file saved to: $STATE_FILE"
