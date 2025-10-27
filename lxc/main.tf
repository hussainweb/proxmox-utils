terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }

  backend "local" {
    # Backend configuration will be provided via backend.tfbackend
  }
}

provider "proxmox" {
  # Configuration should be provided via environment variables:
  # PM_API_URL, PM_USER, PM_PASS, PM_TLS_INSECURE
}

resource "proxmox_lxc" "container" {
  vmid         = var.vmid
  hostname     = var.hostname
  target_node  = var.node
  ostemplate   = var.template
  password     = var.password
  unprivileged = var.unprivileged
  start        = true

  ssh_public_keys = var.ssh_public_keys

  # Root filesystem
  rootfs {
    storage = "local-lvm"
    size    = var.disk_size
  }

  # Network
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  # Resources
  cores  = var.cores
  memory = var.memory

  # Features
  features {
    nesting = true
  }
}

output "container_id" {
  value       = proxmox_lxc.container.vmid
  description = "The VMID of the created container"
}

output "hostname" {
  value       = proxmox_lxc.container.hostname
  description = "The hostname of the created container"
}
