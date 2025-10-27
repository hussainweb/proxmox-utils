#!/usr/bin/env bash

set -e

# Function to display usage
usage() {
    cat << EOF
Usage: $0 VMID

Destroy a Proxmox VM using Terraform.

Arguments:
    VMID    VMID of the VM to destroy

Example:
    $0 100

EOF
    exit 1
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Get VMID from first argument
VMID="$1"

# Validate required parameter
if [[ -z "$VMID" ]]; then
    echo "Error: Missing required argument VMID"
    usage
fi

# Set state file path based on VMID
STATE_DIR="./states"
STATE_FILE="$STATE_DIR/terraform-$VMID.tfstate"

# Check if state file exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: State file not found at $STATE_FILE"
    echo "Cannot destroy VM $VMID - no state file exists"
    exit 1
fi

# Create backend configuration
cat > backend.tf << EOF
terraform {
  backend "local" {
    path = "$STATE_FILE"
  }
}
EOF

echo "Destroying VM $VMID using state file: $STATE_FILE"
echo ""

# Initialize terraform with backend
terraform init -reconfigure

# Destroy terraform resources
terraform destroy -auto-approve

echo ""
echo "VM $VMID destroyed successfully!"
echo "Removing state file..."
rm -f "$STATE_FILE"
echo "Done!"
