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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/utils.sh"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --state-dir)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --state-dir requires a non-empty directory argument"
                usage
            fi
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
check_proxmox_env

# Setup Terraform backend
setup_backend "lxc" "$VMID" "$STATE_DIR" "true"

echo "Destroying container with VMID $VMID using state: $STATE_INFO"
echo ""

# Initialize terraform with backend
terraform init -reconfigure -backend-config=backend.tfbackend

# Destroy terraform resources
terraform destroy -auto-approve

echo ""
echo "Container destroyed successfully!"
cleanup_local_state "$VMID" "$STATE_DIR"
