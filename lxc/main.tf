terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106.0"
    }
  }

  backend "local" {
    # Backend configuration will be provided via backend.tfbackend
  }
}

provider "proxmox" {
  # Configuration should be provided via environment variables:
  # PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_INSECURE
}

resource "proxmox_virtual_environment_container" "container" {
  vm_id       = var.vmid
  node_name   = var.node
  description = "Managed by Terraform"

  initialization {
    hostname = var.hostname
    
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    
    user_account {
      keys     = [var.ssh_public_keys]
      password = var.password
    }
  }

  network_interface {
    name = "eth0"
  }

  operating_system {
    template_file_id = var.template
    type             = "unmanaged"
  }

  disk {
    datastore_id = "local-lvm"
    size         = tonumber(replace(var.disk_size, "G", ""))
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  features {
    nesting = true
  }

  unprivileged = var.unprivileged
  started      = true
}

output "container_id" {
  value       = proxmox_virtual_environment_container.container.vm_id
  description = "The VMID of the created container"
}

output "hostname" {
  value       = proxmox_virtual_environment_container.container.initialization[0].hostname
  description = "The hostname of the created container"
}
