# Proxmox LXC Management

This directory contains utility scripts and Terraform configurations for provisioning Proxmox LXC containers.

For general prerequisites and setup, please refer to the [root README](../README.md).

## Usage

### `create-lxc.sh`

The script generates a `terraform.tfvars` file based on your input.

```bash
./create-lxc.sh \
  --template local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst \
  --password mySecurePassword123 \
  --disk 20G \
  --hostname mycontainer \
  --vmid 100
```

### Parameters

- `--template TEMPLATE` - **Required**. Path to the container template.
- `--hostname HOSTNAME` - **Required**.
- `--vmid VMID` - **Required**.
- `--password PASSWORD` - Root password.
- `--disk DISK` - Disk size (default: 20G).
- `--cores CORES` - CPU cores (default: 2).
- `--memory MEMORY` - RAM in MB (default: 2048).
- `--node NODE` - Proxmox node (default: `erebor`).
- `--ssh-key PATH` - Path to public key (default: `~/.ssh/id_ed25519.pub`).
- `--state-dir DIR` - Custom directory for state files (default: `./states` or `$PROXMOX_STATE_DIR`).
- `--privileged` - Create a privileged container (default: unprivileged).
- `--no-nesting` - Disable nesting (default: enabled).
- `--no-keyctl` - Disable keyctl (default: enabled).

### `destroy-lxc.sh`

Destroys an LXC container and removes its state file:
```bash
./destroy-lxc.sh 100
./destroy-lxc.sh --state-dir /path/to/states 100
```

## State Management

State files default to `./states/terraform-{VMID}.tfstate`.

### MinIO / S3 Remote State Backend
To store state remotely in S3 or MinIO, set the following environment variables:
```bash
export PROXMOX_TFSTATE_ACCESS_KEY="your-access-key"
export PROXMOX_TFSTATE_SECRET_KEY="your-secret-key"
export PROXMOX_TFSTATE_S3_ENDPOINT="https://s3.example.com"
export PROXMOX_TFSTATE_S3_BUCKET="my-tf-state-bucket"
export PROXMOX_TFSTATE_S3_REGION="main" # optional, default: main
```

## Configuration Details

- **Storage:** Defaults to `local-lvm`. Modify `main.tf` to change.
- **Network:** Defaults to `eth0` on `vmbr0` with DHCP.


