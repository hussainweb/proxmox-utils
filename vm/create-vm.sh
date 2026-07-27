#!/usr/bin/env bash

set -e

# Default values
NODE="erebor"
CORES=2
CPU_TYPE="host"
MEMORY=2048
DISK_SIZE="20G"
PASSWORD=""
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
BIOS="seabios"
STORAGE="local-lvm"
CLONE_TEMPLATE_ID=0

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
    --cpu-type TYPE            CPU type (default: host)
    --memory MEMORY            RAM in MB (default: 2048)
    --bios BIOS                BIOS type: ovmf (UEFI) or seabios (default: seabios)
    --node NODE                Proxmox node (default: erebor)
    --storage STORAGE          Storage for VM disks (default: local-lvm)
    --clone-from TEMPLATE_ID   Clone from existing template ID (optional)
    --ssh-key PATH             Path to SSH public key (default: ~/.ssh/id_ed25519.pub)
    --state-dir DIR            Custom directory for state files (default: ./states or $PROXMOX_STATE_DIR)
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
        --cpu-type)
            CPU_TYPE="$2"
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
        --state-dir)
            STATE_DIR="$2"
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

# Validate required Proxmox environment variables
if [[ -z "$PROXMOX_VE_ENDPOINT" || -z "$PROXMOX_VE_API_TOKEN" ]]; then
    echo "Error: Required Proxmox environment variables are not set."
    echo "Please set PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN."
    exit 1
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

# Create state directory if it doesn't exist
STATE_DIR="${STATE_DIR:-${PROXMOX_STATE_DIR:-./states}}"
mkdir -p "$STATE_DIR"

# Set state file path based on VMID
STATE_FILE="$STATE_DIR/terraform-$VMID.tfstate"

# Create backend configuration
cat > backend.tfbackend << EOF
path = "$STATE_FILE"
EOF

# Create terraform.tfvars
cat > terraform.tfvars << EOF
vmid               = $VMID
hostname           = "$HOSTNAME"
disk_size          = "$DISK_SIZE"
cores              = $CORES
cpu_type           = "$CPU_TYPE"
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

echo "Created terraform.tfvars with the following configuration:"
echo "  VMID: $VMID"
echo "  Hostname: $HOSTNAME"
echo "  Disk: $DISK_SIZE"
echo "  Cores: $CORES"
echo "  CPU Type: $CPU_TYPE"
echo "  Memory: $MEMORY MB"
echo "  BIOS: $BIOS"
echo "  Node: $NODE"
echo "  Storage: $STORAGE"
if [[ "$CLONE_TEMPLATE_ID" != "0" ]]; then
    echo "  Clone from template: $CLONE_TEMPLATE_ID"
fi
echo "  SSH Key: $SSH_PUBLIC_KEY_PATH"
echo "  State File: $STATE_FILE"
echo ""

# Reinitialize terraform with new backend
echo "Initializing Terraform..."
terraform init -reconfigure -backend-config=backend.tfbackend
echo ""

# Apply terraform configuration
echo "Creating VM..."
terraform apply -auto-approve

echo ""
echo "VM created successfully!"
echo "State file saved to: $STATE_FILE"

echo ""
echo "Smooth dotfiles setup with chezmoi:"
echo "  1. Find the VM's IP address in the Proxmox UI."
echo "  2. SSH into the VM (user 'hw'):"
echo "     ssh hw@<IP_ADDRESS>"
echo ""
echo "  3. Run chezmoi init to configure your environment (stack, personal, etc.):"
echo "     chezmoi init"
echo ""
echo "  4. Add 1Password accounts (if relevant):"
echo "     op account add --address my.1password.com --email hussainweb@gmail.com --shorthand personal"
echo "     op account add --address axelerant.1password.com --email hussain@axelerant.com --shorthand axelerant"
echo ""
echo "  5. Sign in to 1Password:"
echo "     Fish: eval (op signin)"
echo "     Zsh:  eval \$(op signin)"
echo ""
echo "  6. Apply the dotfiles:"
echo "     chezmoi apply"
echo ""
