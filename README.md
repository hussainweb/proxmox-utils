# Proxmox Utils

A collection of utility scripts and Terraform configurations for provisioning and managing resources on Proxmox VE.

## Directory Structure

- `lxc/`: Contains a bash wrapper (`create-lxc.sh`) and Terraform configuration to provision Proxmox LXC containers.
- `vm/`: Contains a bash wrapper (`create-vm.sh`) and Terraform configuration to provision Proxmox Virtual Machines, including cloning from templates with cloud-init integration.
- `template/`: Contains scripts to build an Ubuntu 26.04 cloud-init template (`create-template.sh`) and a comprehensive snippet manager (`manage-snippets.sh`) for cloud-init configurations via SSH.

## Prerequisites

- **Terraform:** Ensure Terraform is installed on your local machine to run the `lxc` and `vm` provisioning.
- **Proxmox Credentials:** The Terraform BPG provider requires environment variables for authentication. Set the following before running the wrapper scripts:
  - `PROXMOX_VE_ENDPOINT` (e.g., `https://proxmox:8006/`)
  - `PROXMOX_VE_API_TOKEN` (e.g., `user@pve!mytoken=uuid`)
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

### Managing Snippets

You can use the `manage-snippets.sh` script to list, upload, download, or delete snippets on your Proxmox host:

```bash
cd template
# List snippets
./manage-snippets.sh list --ssh-host root@proxmox

# Upload a local file
./manage-snippets.sh upload --ssh-host root@proxmox --file docker-cloud-init.yaml.new

# Download for editing
./manage-snippets.sh download --ssh-host root@proxmox --file docker-cloud-init.yaml --local-path ./temp.yaml

# Delete a snippet
./manage-snippets.sh delete --ssh-host root@proxmox --file old-config.yaml
```

This ensures snippets are correctly placed on the Proxmox storage (default: `nfslorien`) so it can be used by VMs and templates.
