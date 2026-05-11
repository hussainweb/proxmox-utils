# Proxmox Virtual Machine Management

This directory contains utility scripts and Terraform configurations for provisioning Virtual Machines with cloud-init support.

For general prerequisites and setup, please refer to the [root README](../README.md).

## Usage

### `create-vm.sh`

The script generates a `terraform.tfvars` file and manages state files per VMID in the `states/` directory.

#### Clone from existing template (Recommended)
```bash
./create-vm.sh \
  --hostname myvm \
  --vmid 101 \
  --clone-from 9000 \
  --disk 30G \
  --cores 4 \
  --memory 4096
```

### Parameters

- `--hostname HOSTNAME` - **Required**.
- `--vmid VMID` - **Required**.
- `--clone-from TEMPLATE_ID` - Clone from existing template ID.
- `--password PASSWORD` - Root password (default: blank).
- `--disk DISK` - Disk size (default: 20G).
- `--cores CORES` - CPU cores (default: 2).
- `--memory MEMORY` - RAM in MB (default: 2048).
- `--bios BIOS` - `ovmf` (UEFI) or `seabios` (Legacy) (default: `ovmf`).
- `--node NODE` - Proxmox node (default: `erebor`).
- `--storage STORAGE` - Storage for disks (default: `local-lvm`).
- `--ssh-key PATH` - Path to public key (default: `~/.ssh/id_ed25519.pub`).

### `destroy-vm.sh`

Destroys a VM and removes its specific state file:

```bash
./destroy-vm.sh --vmid 101
```

## State Management

State files are stored in `states/terraform-{VMID}.tfstate`. This allows you to manage multiple VMs independently using the same Terraform configuration.

## Cloud-init & Templates

Ensure your template has cloud-init installed and a cloud-init drive attached. See the [root README](../README.md#4-manual-template-creation-optional) for a manual creation example or the [template/](../template/) directory for automated tools.

## Troubleshooting

- **VM doesn't start:** Verify BIOS type matches the OS.
- **No SSH access:** Wait for cloud-init completion; check Proxmox console.
- **Disk resize fails:** Ensure template has cloud-init and supports online resize.
