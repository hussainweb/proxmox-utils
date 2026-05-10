# Proxmox LXC Creator

A simple script and Terraform module to create Proxmox LXC containers.

## Prerequisites

1. Terraform installed
2. Proxmox API credentials set as environment variables:
   ```bash
   export PROXMOX_VE_ENDPOINT="https://proxmox.example.com:8006/"
   export PROXMOX_VE_API_TOKEN="user@pam!mytoken=your-token-uuid"
   export PROXMOX_VE_INSECURE=true  # if using self-signed certificates
   ```

## Usage

### Using the Script

The script generates a `terraform.tfvars` file with your configuration:

```bash
./create-lxc.sh \
  --template local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst \
  --password mySecurePassword123 \
  --disk 20G \
  --hostname mycontainer \
  --vmid 100
```

Optional parameters:
- `--privileged` - Create a privileged container (default: unprivileged)
- `--no-nesting` - Disable nesting (default: enabled)
- `--no-keyctl` - Disable keyctl (default: enabled)
- `--node NODE` - Proxmox node (default: erebor)
- `--cores CORES` - CPU cores (default: 2)
- `--memory MEMORY` - RAM in MB (default: 2048)
- `--ssh-key PATH` - Path to SSH public key (default: ~/.ssh/id_ed25519.pub)

### Apply with Terraform

After running the script:

```bash
terraform init
terraform plan
terraform apply
```

### Direct Terraform Usage

You can also use Terraform directly by creating your own `terraform.tfvars`:

```hcl
vmid            = 100
hostname        = "mycontainer"
template        = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
disk_size       = "20G"
cores           = 2
memory          = 2048
unprivileged    = true
nesting         = true
keyctl          = true
node            = "erebor"
password        = "mySecurePassword123"
ssh_public_keys = <<-EOT
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@host
EOT
```

## Configuration

### Storage

By default, the module uses `local-lvm` for storage. Modify the `storage` parameter in `main.tf` if your setup uses a different storage name.

### Network

The container is configured with:
- Network interface: eth0
- Bridge: vmbr0
- IP: DHCP

Modify the network block in `main.tf` if you need static IP configuration.

## Examples

### Minimal Example (using defaults)
```bash
./create-lxc.sh --template local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst \
  --password pass123 --disk 10G --hostname test-container --vmid 101
```

### Custom Configuration
```bash
./create-lxc.sh --template local:vztmpl/debian-11-standard_11.7-1_amd64.tar.zst \
  --password pass123 --disk 50G --hostname prod-server --vmid 200 \
  --privileged --cores 4 --memory 4096 --node pve01
```

## Cleanup

To destroy the container:
```bash
terraform destroy
```
