#!/usr/bin/env bash

set -e

# Default values
UNPRIVILEGED=true
NODE="erebor"
CORES=2
MEMORY=2048
TEMPLATE="ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
TEMPLATE_VOLUME="local"
PASSWORD=""
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_ed25519.pub"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Create a new Proxmox LXC container using Terraform.

Required Options:
    --disk DISK                 Disk size (e.g., 20G)
    --hostname HOSTNAME         Hostname for the container
    --vmid VMID                VMID for the container

Optional:
    --password PASSWORD         Root password for the container (optional)
    --template TEMPLATE         Template name (default: ubuntu-24.04-standard_24.04-2_amd64.tar.zst)
    --template-volume VOLUME   Template storage volume (default: local)
    --privileged               Create privileged container (default: unprivileged)
    --node NODE                Proxmox node (default: erebor)
    --cores CORES              CPU cores (default: 2)
    --memory MEMORY            RAM in MB (default: 2048)
    --ssh-key PATH             Path to SSH public key (default: ~/.ssh/id_ed25519.pub)
    -h, --help                 Show this help message

Example:
    $0 --disk 20G --hostname mycontainer --vmid 100

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        --disk)
            DISK="$2"
            shift 2
            ;;
        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        --vmid)
            VMID="$2"
            shift 2
            ;;
        --template-volume)
            TEMPLATE_VOLUME="$2"
            shift 2
            ;;
        --privileged)
            UNPRIVILEGED=false
            shift
            ;;
        --node)
            NODE="$2"
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
if [[ -z "$DISK" || -z "$HOSTNAME" || -z "$VMID" ]]; then
    echo "Error: Missing required parameters"
    usage
fi

# Check if SSH public key exists
if [[ ! -f "$SSH_PUBLIC_KEY_PATH" ]]; then
    echo "Error: SSH public key not found at $SSH_PUBLIC_KEY_PATH"
    exit 1
fi

# Read SSH public key
SSH_PUBLIC_KEY=$(cat "$SSH_PUBLIC_KEY_PATH")

# Construct full template path in Proxmox format
FULL_TEMPLATE="${TEMPLATE_VOLUME}:vztmpl/${TEMPLATE}"

# Create terraform.tfvars
cat > terraform.tfvars << EOF
vmid         = $VMID
hostname     = "$HOSTNAME"
template     = "$FULL_TEMPLATE"
disk_size    = "$DISK"
cores        = $CORES
memory       = $MEMORY
unprivileged = $UNPRIVILEGED
node         = "$NODE"
password     = "$PASSWORD"
ssh_public_keys = <<-EOT
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
echo "  Template: $TEMPLATE"
echo "  Disk: $DISK"
echo "  Cores: $CORES"
echo "  Memory: $MEMORY MB"
echo "  Unprivileged: $UNPRIVILEGED"
echo "  Node: $NODE"
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
echo "Creating container..."
terraform apply -state="$STATE_FILE" -auto-approve

echo ""
echo "Container created successfully!"
echo "State file saved to: $STATE_FILE"
