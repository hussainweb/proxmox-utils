# Proxmox VM Creator

A simple script and Terraform module to create Proxmox VMs with cloud-init support.

## Prerequisites

1. Terraform installed
2. Proxmox API credentials set as environment variables:
   ```bash
   export PM_API_URL="https://proxmox.example.com:8006/api2/json"
   export PM_USER="root@pam"
   export PM_PASS="your-password"
   export PM_TLS_INSECURE=true  # if using self-signed certificates
   ```

## Usage

### Using the Script

The script generates a `terraform.tfvars` file with your configuration and manages state files per VMID:

#### Create from scratch (requires cloud-init image)
```bash
./create-vm.sh \
  --hostname myvm \
  --vmid 100
```

#### Clone from existing template
```bash
./create-vm.sh \
  --hostname myvm \
  --vmid 101 \
  --clone-from 9000 \
  --disk 30G \
  --cores 4 \
  --memory 4096
```

### Required Parameters
- `--hostname HOSTNAME` - Hostname for the VM
- `--vmid VMID` - VMID for the VM

### Optional Parameters
- `--password PASSWORD` - Root password (default: blank)
- `--disk DISK` - Disk size (default: 20G)
- `--cores CORES` - CPU cores (default: 2)
- `--memory MEMORY` - RAM in MB (default: 2048)
- `--bios BIOS` - BIOS type: ovmf (UEFI) or seabios (default: ovmf)
- `--node NODE` - Proxmox node (default: erebor)
- `--storage STORAGE` - Storage for VM disks (default: local-lvm)
- `--clone-from TEMPLATE_ID` - Clone from existing template ID
- `--ssh-key PATH` - Path to SSH public key (default: ~/.ssh/id_ed25519.pub)

## State Management

The script automatically manages separate state files for each VM in the `states/` directory:
- State files are named: `states/terraform-{VMID}.tfstate`
- This allows multiple VMs to be managed independently

## Cloud-init Support

The VM is configured with cloud-init, which allows:
- Automatic hostname configuration
- SSH key injection
- Optional password authentication
- Network configuration (DHCP by default)

### Template Requirements

If cloning from a template (recommended), ensure your template:
1. Has cloud-init installed and configured
2. Is marked as a template in Proxmox
3. Has a cloud-init drive attached

### Creating a Cloud-init Template

You can create a template manually in Proxmox:

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM
qm create 9000 --name ubuntu-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Attach disk
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Add cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# Set boot disk
qm set 9000 --boot c --bootdisk scsi0

# Enable QEMU agent
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

## Examples

### Minimal VM (using defaults)
```bash
./create-vm.sh --hostname test-vm --vmid 100
```

### Clone with custom resources
```bash
./create-vm.sh \
  --hostname prod-server \
  --vmid 200 \
  --clone-from 9000 \
  --disk 50G \
  --cores 4 \
  --memory 8192 \
  --password mySecurePassword
```

### Legacy BIOS VM
```bash
./create-vm.sh \
  --hostname legacy-vm \
  --vmid 150 \
  --bios seabios \
  --clone-from 9000
```

## Destroying VMs

To destroy a VM:

```bash
./destroy-vm.sh --vmid 100
```

This will:
1. Use the state file for the specified VMID
2. Destroy the VM via Terraform
3. Remove the state file

## Configuration

### Storage

By default, the module uses `local-lvm` for storage. Use the `--storage` option to specify a different storage backend.

### Network

The VM is configured with:
- Network interface: virtio
- Bridge: vmbr0
- IP: DHCP

To use static IP, you'll need to modify the `ipconfig0` setting in `main.tf` after running the script.

### BIOS Types

- `ovmf` (UEFI) - Modern BIOS, required for some OS features, supports Secure Boot
- `seabios` - Legacy BIOS, better compatibility with older systems

## Direct Terraform Usage

You can also use Terraform directly by creating your own `terraform.tfvars`:

```hcl
vmid              = 100
hostname          = "myvm"
disk_size         = "20G"
cores             = 2
memory            = 2048
node              = "erebor"
password          = ""
bios              = "ovmf"
storage           = "local-lvm"
clone_template_id = 9000
ssh_public_keys   = <<-EOT
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@host
EOT
```

Then run:
```bash
terraform init
terraform plan -state=states/terraform-100.tfstate
terraform apply -state=states/terraform-100.tfstate
```

## Troubleshooting

### VM doesn't start
- Check that cloud-init is installed in the template
- Verify BIOS setting matches your OS requirements (UEFI vs Legacy)
- Check Proxmox logs: `journalctl -u pve-cluster`

### Can't connect via SSH
- Wait a few minutes for cloud-init to complete
- Check VM console in Proxmox web interface
- Verify SSH key is correct
- Check cloud-init status: `cloud-init status`

### Disk resize doesn't work
- Ensure you're using a template with cloud-init
- Some filesystems require manual resize inside the VM
- Check if the disk was actually resized in Proxmox web interface
