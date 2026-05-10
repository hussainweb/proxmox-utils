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
- `--privileged` - Create a privileged container (default: unprivileged).
- `--no-nesting` - Disable nesting (default: enabled).
- `--no-keyctl` - Disable keyctl (default: enabled).

## Applying with Terraform

After running the wrapper script, apply the configuration:

```bash
terraform init
terraform apply
```

To destroy:
```bash
terraform destroy
```

## Configuration Details

- **Storage:** Defaults to `local-lvm`. Modify `main.tf` to change.
- **Network:** Defaults to `eth0` on `vmbr0` with DHCP.
