terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111.0"
    }
  }
}

provider "proxmox" {
  # Configuration should be provided via environment variables:
  # PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_INSECURE
}

resource "proxmox_virtual_environment_vm" "vm" {
  vm_id       = var.vmid
  name        = var.hostname
  node_name   = var.node
  description = "Managed by Terraform"
  
  bios = var.bios

  # Clone configuration (if template ID is provided)
  dynamic "clone" {
    for_each = var.clone_template_id != 0 ? [1] : []
    content {
      vm_id = var.clone_template_id
      full  = true
    }
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Disks
  disk {
    datastore_id = var.storage
    file_format  = "raw"
    interface    = "scsi0"
    size         = tonumber(replace(var.disk_size, "G", ""))
  }

  # Cloud-Init
  initialization {
    datastore_id = var.storage
    
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "root"
      password = var.password != "" ? var.password : null
      keys     = [var.ssh_public_keys]
    }

    vendor_data_file_id = "nfslorien:snippets/docker-cloud-init.yaml"
  }

  vga {
    type = "std"
  }

  started = true

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}

output "vm_id" {
  value       = proxmox_virtual_environment_vm.vm.vm_id
  description = "The VMID of the created VM"
}

output "hostname" {
  value       = proxmox_virtual_environment_vm.vm.name
  description = "The hostname of the created VM"
}
