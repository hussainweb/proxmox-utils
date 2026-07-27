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
    STATE_FILE="$STATE_DIR/terraform-$VMID.tfstate"
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "Error: State file not found at $STATE_FILE"
        echo "Cannot destroy container with VMID $VMID - no state file exists."
        exit 1
    fi
    cat > backend.tfbackend << EOF
path = "$STATE_FILE"
EOF
    STATE_INFO="Local ($STATE_FILE)"
fi

echo "Destroying container with VMID $VMID using state: $STATE_INFO"
echo ""

# Initialize terraform with backend
terraform init -reconfigure -backend-config=backend.tfbackend

# Destroy terraform resources
terraform destroy -auto-approve

echo ""
echo "Container destroyed successfully!"
if [[ -z "$S3_ACCESS_KEY" || -z "$S3_SECRET_KEY" ]]; then
    echo "Removing local state file: $STATE_FILE"
    rm -f "$STATE_FILE" "$STATE_FILE.backup"

    # Check if states directory is empty and remove it
    if [[ -d "$STATE_DIR" ]] && [[ -z "$(ls -A "$STATE_DIR")" ]]; then
        rmdir "$STATE_DIR"
        echo "Removed empty states directory"
    fi
fi
