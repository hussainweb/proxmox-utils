# Proxmox Utils

A collection of utility scripts and Terraform configurations for provisioning and managing resources on Proxmox VE.

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Components](#components)
  - [LXC Containers](./lxc/README.md)
  - [Virtual Machines](./vm/README.md)
  - [Templates & Snippets](./template/README.md)
- [Usage Examples](#usage-examples)

## Prerequisites

Before using any of these utilities, ensure you have the following:

- **Terraform:** Installed on your local machine.
- **Proxmox API Credentials:** Set as environment variables for the [Terraform BPG provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs):
  ```bash
  export PROXMOX_VE_ENDPOINT="https://proxmox.example.com:8006/"
  export PROXMOX_VE_API_TOKEN="user@pam!mytoken=your-token-uuid"
  export PROXMOX_VE_INSECURE=true  # if using self-signed certificates
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

## Usage Examples

### Creating an LXC Container
```bash
cd lxc
./create-lxc.sh --vmid 101 --hostname my-lxc --template local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst
```

### Creating a Virtual Machine
```bash
cd vm
./create-vm.sh --vmid 102 --hostname my-vm --clone-from 8000
```

### Destroying Resources
- **LXC:** `cd lxc && terraform destroy`
- **VM:** `cd vm && ./destroy-vm.sh --vmid 102`

---
For detailed instructions on each component, please refer to the respective subdirectories.
