# Proxmox Utils

A collection of utility scripts and Terraform configurations for provisioning and managing resources on Proxmox VE.

## Directory Structure

- `lxc/`: Contains a bash wrapper (`create-lxc.sh`) and Terraform configuration to provision Proxmox LXC containers.
- `vm/`: Contains a bash wrapper (`create-vm.sh`) and Terraform configuration to provision Proxmox Virtual Machines, including cloning from templates with cloud-init integration.
- `template/`: Contains a bash script (`create-template.sh`) to connect to a Proxmox host via SSH and build an Ubuntu 26.04 cloud-init template directly on the host.

## Prerequisites

- **Terraform:** Ensure Terraform is installed on your local machine to run the `lxc` and `vm` provisioning.
- **Proxmox Credentials:** The Terraform BPG provider requires environment variables for authentication. Set the following before running the wrapper scripts:
  - `PROXMOX_VE_ENDPOINT` (e.g., `https://proxmox:8006/`)
  - `PROXMOX_VE_USERNAME`
  - `PROXMOX_VE_PASSWORD`
  - `PROXMOX_VE_INSECURE=true` (if using self-signed certificates)

## Usage

### Creating an LXC Container

Navigate to the `lxc` directory and run the wrapper script:

```bash
cd lxc
./create-lxc.sh --vmid 101 --hostname my-lxc --disk 20G
```

Use `./create-lxc.sh --help` to see all available options (e.g., `--node`, `--cores`, `--memory`, `--template`, `--privileged`).

### Creating a Virtual Machine

Navigate to the `vm` directory and run the wrapper script:

```bash
cd vm
./create-vm.sh --vmid 102 --hostname my-vm --clone-from 8000
```

Use `./create-vm.sh --help` to see all available options (e.g., `--disk`, `--cores`, `--memory`, `--bios`).

### Creating a VM Template

Navigate to the `template` directory and run the script:

```bash
cd template
./create-template.sh --ssh-host root@proxmox
```

This will download an Ubuntu cloud image, import it into Proxmox via SSH, configure cloud-init, and optionally convert it into a reusable template.
