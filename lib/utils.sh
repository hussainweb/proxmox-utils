#!/usr/bin/env bash

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: lib/utils.sh is a helper library and must be sourced, not executed directly."
    echo "Usage: source /path/to/lib/utils.sh"
    exit 1
fi

# Validate required Proxmox VE environment variables
check_proxmox_env() {
    if [[ -z "$PROXMOX_VE_ENDPOINT" || -z "$PROXMOX_VE_API_TOKEN" ]]; then
        echo "Error: Required Proxmox environment variables are not set."
        echo "Please set PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN."
        exit 1
    fi
}

# Setup Terraform backend (S3 vs Local)
# Arguments:
#   1: resource_type ("lxc" or "vms")
#   2: vmid
#   3: custom_state_dir (optional)
#   4: require_existing_state (optional: "true" or "false")
# Exports/sets: STATE_INFO, STATE_FILE, STATE_DIR
setup_backend() {
    local resource_type="$1"
    local vmid="$2"
    local custom_state_dir="$3"
    local require_existing_state="${4:-false}"

    S3_ACCESS_KEY="$PROXMOX_TFSTATE_ACCESS_KEY"
    S3_SECRET_KEY="$PROXMOX_TFSTATE_SECRET_KEY"
    S3_ENDPOINT="$PROXMOX_TFSTATE_S3_ENDPOINT"
    S3_BUCKET="$PROXMOX_TFSTATE_S3_BUCKET"
    S3_REGION="${PROXMOX_TFSTATE_S3_REGION:-main}"

    if [[ -n "$S3_ACCESS_KEY" && -n "$S3_SECRET_KEY" ]]; then
        if [[ -z "$S3_ENDPOINT" || -z "$S3_BUCKET" ]]; then
            echo "Error: MinIO/S3 state backend is enabled (access key and secret key are set),"
            echo "but required environment variables PROXMOX_TFSTATE_S3_ENDPOINT or PROXMOX_TFSTATE_S3_BUCKET are missing."
            echo "Please set PROXMOX_TFSTATE_S3_ENDPOINT and PROXMOX_TFSTATE_S3_BUCKET."
            exit 1
        fi
        echo "Using MinIO/S3 state backend at $S3_ENDPOINT (bucket: $S3_BUCKET)"
        cat > backend.tf << EOF
terraform {
  backend "s3" {}
}
EOF
        cat > backend.tfbackend << EOF
bucket                      = "$S3_BUCKET"
key                         = "${resource_type}/terraform-${vmid}.tfstate"
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
        STATE_INFO="S3 ($S3_ENDPOINT / $S3_BUCKET / ${resource_type}/terraform-${vmid}.tfstate)"
        STATE_FILE=""
        STATE_DIR=""
    else
        cat > backend.tf << EOF
terraform {
  backend "local" {}
}
EOF
        STATE_DIR="${custom_state_dir:-${PROXMOX_STATE_DIR:-./states}}"
        STATE_FILE="$STATE_DIR/terraform-${vmid}.tfstate"

        if [[ "$require_existing_state" == "true" && ! -f "$STATE_FILE" ]]; then
            echo "Error: State file not found at $STATE_FILE"
            echo "Cannot destroy resource with VMID $vmid - no state file exists."
            exit 1
        fi

        mkdir -p "$STATE_DIR"
        cat > backend.tfbackend << EOF
path = "$STATE_FILE"
EOF
        STATE_INFO="Local ($STATE_FILE)"
    fi
}

# Clean up local state files and empty state directory after destroy
# Arguments:
#   1: vmid
#   2: custom_state_dir (optional)
cleanup_local_state() {
    local vmid="$1"
    local custom_state_dir="$2"

    if [[ -z "$PROXMOX_TFSTATE_ACCESS_KEY" || -z "$PROXMOX_TFSTATE_SECRET_KEY" ]]; then
        local state_dir="${custom_state_dir:-${PROXMOX_STATE_DIR:-./states}}"
        local state_file="$state_dir/terraform-${vmid}.tfstate"
        echo "Removing local state file: $state_file"
        rm -f "$state_file" "$state_file.backup"

        # Check if states directory is empty and remove it
        if [[ -d "$state_dir" ]] && [[ -z "$(ls -A "$state_dir")" ]]; then
            rmdir "$state_dir"
            echo "Removed empty states directory"
        fi
    fi
}
