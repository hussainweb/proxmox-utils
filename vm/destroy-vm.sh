#!/usr/bin/env bash

set -e

# Function to display usage
usage() {
    cat << EOF
Usage: $0 --vmid VMID

Destroy a Proxmox VM using Terraform.

Required Options:
    --vmid VMID                VMID of the VM to destroy

Options:
    -h, --help                 Show this help message

Example:
    $0 --vmid 100

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vmid)
            VMID="$2"
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
if [[ -z "$VMID" ]]; then
    echo "Error: Missing required parameter --vmid"
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

echo "Destroying VM $VMID using state file: $STATE_FILE"
echo ""

# Destroy terraform resources
terraform destroy -state="$STATE_FILE" -auto-approve

echo ""
echo "VM $VMID destroyed successfully!"
echo "Removing state file..."
rm -f "$STATE_FILE"
echo "Done!"
