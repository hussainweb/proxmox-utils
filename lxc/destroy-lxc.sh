#!/usr/bin/env bash

set -e

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] VMID

Destroy a Proxmox LXC container using Terraform.

Arguments:
    VMID    VMID of the container to destroy

Options:
    --state-dir DIR    Custom directory for state files (default: ./states or $PROXMOX_STATE_DIR)

Example:
    $0 100
    $0 --state-dir /path/to/states 100

EOF
    exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --state-dir)
            STATE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [[ -z "$VMID" ]]; then
                VMID="$1"
                shift
            else
                echo "Unknown argument: $1"
                usage
            fi
            ;;
    esac
done

# Validate required parameter
if [[ -z "$VMID" ]]; then
    echo "Error: Missing required argument VMID"
    usage
fi

# Validate required Proxmox environment variables
if [[ -z "$PROXMOX_VE_ENDPOINT" || -z "$PROXMOX_VE_API_TOKEN" ]]; then
    echo "Error: Required Proxmox environment variables are not set."
    echo "Please set PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN."
    exit 1
fi

# Set state file path based on VMID
STATE_DIR="${STATE_DIR:-${PROXMOX_STATE_DIR:-./states}}"
STATE_FILE="$STATE_DIR/terraform-$VMID.tfstate"

# Check if state file exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: State file not found at $STATE_FILE"
    echo "Cannot destroy container with VMID $VMID - no state file exists."
    exit 1
fi

# Create backend configuration
cat > backend.tfbackend << EOF
path = "$STATE_FILE"
EOF

echo "Found state file: $STATE_FILE"
echo "Destroying container with VMID: $VMID"
echo ""

# Initialize terraform with backend
terraform init -reconfigure -backend-config=backend.tfbackend

# Destroy terraform resources
terraform destroy -auto-approve

echo ""
echo "Container destroyed successfully!"
echo "Removing state file: $STATE_FILE"
rm -f "$STATE_FILE" "$STATE_FILE.backup"

# Check if states directory is empty and remove it
if [[ -d "$STATE_DIR" ]] && [[ -z "$(ls -A "$STATE_DIR")" ]]; then
    rmdir "$STATE_DIR"
    echo "Removed empty states directory"
fi
