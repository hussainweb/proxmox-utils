# Proxmox Utils

A collection of utility scripts and Terraform configurations for provisioning and managing resources on Proxmox VE.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Components](#components)
  - [LXC Containers](./lxc/README.md)
  - [Virtual Machines](./vm/README.md)
  - [Templates & Snippets](./template/README.md)
- [Usage & Examples](#usage--examples)

## Prerequisites

Before using any of these utilities, ensure you have the following:

- **Terraform:** Installed on your local machine.
- **Proxmox API Credentials:** Set as environment variables for the [Terraform BPG provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs):
  ```bash
  export PROXMOX_VE_ENDPOINT="https://proxmox.example.com:8006/"
  export PROXMOX_VE_API_TOKEN="user@pam!mytoken=your-token-uuid"
  export PROXMOX_VE_INSECURE=true  # if using self-signed certificates
  ```

### State Management & Remote S3 Backend

By default, state files are managed per resource in `./states/terraform-{VMID}.tfstate`.

You can customize the local state directory via `--state-dir /path/to/states` or `export PROXMOX_STATE_DIR="/path/to/states"`.

#### MinIO / S3 Remote State
To store state files in MinIO or S3, export the following environment variables:
```bash
export PROXMOX_TFSTATE_ACCESS_KEY="your-access-key"
export PROXMOX_TFSTATE_SECRET_KEY="your-secret-key"
export PROXMOX_TFSTATE_S3_ENDPOINT="https://s3.example.com"
export PROXMOX_TFSTATE_S3_BUCKET="my-tf-state-bucket"
export PROXMOX_TFSTATE_S3_REGION="main"  # optional, default: main
```

## Components

### [LXC Containers](./lxc/)
Provision Proxmox LXC containers using a bash wrapper and Terraform.
- **Key Features:** Unprivileged/Privileged support, nesting, keyctl, automatic SSH key injection.
- **Documentation:** See [lxc/README.md](./lxc/README.md) for detailed parameters and troubleshooting.

### [Virtual Machines](./vm/)
Provision Virtual Machines with cloud-init integration.
- **Key Features:** Template cloning, state management per VMID, UEFI/Legacy BIOS support.
- **Documentation:** See [vm/README.md](./vm/README.md) for advanced usage, state management, and template requirements.

### [Templates & Snippets](./template/)
Utilities for preparing Proxmox environments.
- **`create-template.sh`**: Build an Ubuntu 26.04 cloud-init template via SSH.
- **`manage-snippets.sh`**: Centralized management for cloud-init snippets on Proxmox storage.

## Usage & Examples

### 1. LXC Containers
Provisioning lightweight containers.
```bash
cd lxc

# Minimal deployment
./create-lxc.sh --vmid 101 --hostname my-lxc --disk 20G

# Advanced: Privileged with custom resources
./create-lxc.sh --vmid 102 --hostname prod-server --disk 50G --cores 4 --memory 4096 --privileged
```

### 2. Virtual Machines
Provisioning full VMs with cloud-init.
```bash
cd vm

# Clone from existing template
./create-vm.sh --vmid 201 --hostname my-vm --clone-from 8000 --disk 30G
```

### 3. Templates & Snippets
Building base images and managing cloud-init configs.
```bash
cd template

# Create an Ubuntu 26.04 template via SSH
./create-template.sh --ssh-host root@pve --vm-id 8000

# Manage cloud-init snippets
./manage-snippets.sh upload --ssh-host root@pve --file docker-cloud-init.yaml
```

### 4. Manual Template Creation (Optional)
If you prefer to build a template manually on the Proxmox host:
```bash
# Download & Create
wget https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 ubuntu-26.04-server-cloudimg-amd64.img local-lvm

# Configure & Convert
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0 --agent enabled=1
qm template 9000
```

### 5. Cleanup
- **LXC:** `cd lxc && terraform destroy`
- **VM:** `cd vm && ./destroy-vm.sh --vmid 201`

---
For detailed instructions on each component, please refer to the respective subdirectories.
