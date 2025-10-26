#!/usr/bin/env bash

set -e

# Function to display usage
usage() {
    cat << EOF
Usage: $0 VMID

Destroy a Proxmox LXC container using Terraform.

Arguments:
    VMID    VMID of the container to destroy

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
    echo "Cannot destroy container with VMID $VMID - no state file exists."
    exit 1
fi

echo "Found state file: $STATE_FILE"
echo "Destroying container with VMID: $VMID"
echo ""

# Destroy terraform resources
terraform destroy -state="$STATE_FILE" -auto-approve

echo ""
echo "Container destroyed successfully!"
echo "Removing state file: $STATE_FILE"
rm -f "$STATE_FILE" "$STATE_FILE.backup"

# Check if states directory is empty and remove it
if [[ -d "$STATE_DIR" ]] && [[ -z "$(ls -A "$STATE_DIR")" ]]; then
    rmdir "$STATE_DIR"
    echo "Removed empty states directory"
fi
