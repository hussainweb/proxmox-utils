# Proxmox Templates & Snippets

This directory contains utilities for preparing and managing Proxmox VM templates and cloud-init snippets.

For general prerequisites and setup, please refer to the [root README](../README.md).

## Utilities

### `create-template.sh`

Automates the creation of an Ubuntu 26.04 cloud-init VM template. It downloads the official cloud image, imports it into Proxmox via SSH, and configures it with a custom cloud-init snippet.

#### Usage
```bash
./create-template.sh --ssh-host root@proxmox [OPTIONS]
```

**Options:**
- `--ssh-host HOST`: **Required**. SSH host for Proxmox.
- `--vm-id ID`: VM ID for the template (default: `8000`).
- `--storage STORAGE`: Proxmox storage name (default: `local-lvm`).
- `--ssh-key FILE`: Public key to inject into the template (default: `~/.ssh/id_ed25519.pub`).

### `manage-snippets.sh`

Manages cloud-init snippets stored on Proxmox. Snippets are useful for custom configurations that go beyond the basic Proxmox cloud-init UI.

#### Commands
- **list**: List snippets on Proxmox.
- **upload**: Upload a local YAML as a snippet.
- **download**: Download a snippet for local editing.
- **delete**: Remove a snippet from Proxmox.

#### Usage Examples
```bash
# List available snippets
./manage-snippets.sh list --ssh-host root@pve

# Upload a custom cloud-init config
./manage-snippets.sh upload --ssh-host root@pve --file docker-cloud-init.yaml
```

## Cloud-init Snippets

The following YAML files are provided as base configurations:

- **`basic-cloud-init.yaml`**:
  - Sets up user `hw`.
  - Installs common CLI tools (`fish`, `bat`, `eza`, `ripgrep`, etc.).
  - Installs **Homebrew**, **chezmoi**, and **1Password CLI**.
  - Initializes dotfiles via `chezmoi init hussainweb` (manual apply required after 1Password login).
- **`docker-cloud-init.yaml`**:
  - Includes everything in `basic-cloud-init.yaml`.
  - Installs **Docker Engine** and **Docker Compose**.
  - Adds the user to the `docker` group.

## Workflow: Creating a Template

1.  **Upload Snippet**: Use `manage-snippets.sh` to upload `docker-cloud-init.yaml` to your Proxmox host.
2.  **Run Template Script**: Run `./create-template.sh --ssh-host root@pve`.
3.  **Convert**: The script will prompt to convert the created VM into a template.

Once the template is ready, you can use the [vm/ utilities](../vm/) to clone it into new VMs.
