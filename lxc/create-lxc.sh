#!/usr/bin/env bash

set -e

# Default values
UNPRIVILEGED=true
NESTING=true
KEYCTL=true
NODE="erebor"
CORES=2
MEMORY=2048
TEMPLATE="ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
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
    --template TEMPLATE         Template name (default: ubuntu-26.04-standard_26.04-1_amd64.tar.zst)
    --template-volume VOLUME   Template storage volume (default: local)
    --privileged               Create privileged container (default: unprivileged)
    --no-nesting               Disable nesting (default: enabled)
    --no-keyctl                Disable keyctl (default: enabled)
    --node NODE                Proxmox node (default: erebor)
    --cores CORES              CPU cores (default: 2)
    --memory MEMORY            RAM in MB (default: 2048)
    --ssh-key PATH             Path to SSH public key (default: ~/.ssh/id_ed25519.pub)
    --state-dir DIR            Custom directory for state files (default: ./states or $PROXMOX_STATE_DIR)
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
        --no-nesting)
            NESTING=false
            shift
            ;;
        --no-keyctl)
            KEYCTL=false
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
if [[ -z "$DISK" || -z "$HOSTNAME" || -z "$VMID" ]]; then
    echo "Error: Missing required parameters"
    usage
fi

# Validate required Proxmox environment variables
if [[ -z "$PROXMOX_VE_ENDPOINT" || -z "$PROXMOX_VE_API_TOKEN" ]]; then
    echo "Error: Required Proxmox environment variables are not set."
    echo "Please set PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN."
    exit 1
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

# Check for custom MinIO / S3 credentials
S3_ACCESS_KEY="$PROXMOX_TFSTATE_ACCESS_KEY"
S3_SECRET_KEY="$PROXMOX_TFSTATE_SECRET_KEY"
S3_ENDPOINT="$PROXMOX_TFSTATE_S3_ENDPOINT"
S3_BUCKET="$PROXMOX_TFSTATE_S3_BUCKET"
S3_REGION="${PROXMOX_TFSTATE_S3_REGION:-main}"

if [[ -n "$S3_ACCESS_KEY" && -n "$S3_SECRET_KEY" ]]; then
    echo "Using MinIO/S3 state backend at $S3_ENDPOINT (bucket: $S3_BUCKET)"
    cat > backend.tf << EOF
terraform {
  backend "s3" {}
}
EOF
    cat > backend.tfbackend << EOF
bucket                      = "$S3_BUCKET"
key                         = "lxc/terraform-$VMID.tfstate"
endpoints                   = { s3 = "$S3_ENDPOINT" }
access_key                  = "$S3_ACCESS_KEY"
secret_key                  = "$S3_SECRET_KEY"
region                      = "$S3_REGION"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
skip_requesting_account_id  = true
use_path_style              = true
EOF
    STATE_INFO="S3 ($S3_ENDPOINT / $S3_BUCKET / lxc/terraform-$VMID.tfstate)"
else
    cat > backend.tf << EOF
terraform {
  backend "local" {}
}
EOF
    STATE_DIR="${STATE_DIR:-${PROXMOX_STATE_DIR:-./states}}"
    mkdir -p "$STATE_DIR"
    STATE_FILE="$STATE_DIR/terraform-$VMID.tfstate"
    cat > backend.tfbackend << EOF
path = "$STATE_FILE"
EOF
    STATE_INFO="Local ($STATE_FILE)"
fi

# Create terraform.tfvars
cat > terraform.tfvars << EOF
vmid         = $VMID
hostname     = "$HOSTNAME"
template     = "$FULL_TEMPLATE"
disk_size    = "$DISK"
cores        = $CORES
memory       = $MEMORY
unprivileged = $UNPRIVILEGED
nesting      = $NESTING
keyctl       = $KEYCTL
node         = "$NODE"
password     = "$PASSWORD"
ssh_public_keys = <<-EOT
$SSH_PUBLIC_KEY
EOT
EOF

echo "Created terraform.tfvars with the following configuration:"
echo "  VMID: $VMID"
echo "  Hostname: $HOSTNAME"
echo "  Template: $TEMPLATE"
echo "  Disk: $DISK"
echo "  Cores: $CORES"
echo "  Memory: $MEMORY MB"
echo "  Unprivileged: $UNPRIVILEGED"
echo "  Nesting: $NESTING"
echo "  Keyctl: $KEYCTL"
echo "  Node: $NODE"
echo "  SSH Key: $SSH_PUBLIC_KEY_PATH"
echo "  State: $STATE_INFO"
echo ""

# Reinitialize terraform with new backend
echo "Initializing Terraform..."
terraform init -reconfigure -backend-config=backend.tfbackend
echo ""

# Apply terraform configuration
echo "Creating container..."
terraform apply -auto-approve

echo ""
echo "Container created successfully!"
echo "State saved to: $STATE_INFO"
