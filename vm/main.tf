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

resource "proxmox_vm_qemu" "vm" {
  vmid        = var.vmid
  name        = var.hostname
  target_node = var.node

  # Clone configuration (if template ID is provided)
  clone_id = var.clone_template_id != 0 ? var.clone_template_id : null

  # Full clone (not linked)
  full_clone = var.clone_template_id != 0 ? true : null

  # BIOS setting
  bios = var.bios

  # Boot configuration
  onboot = true
  agent  = 1

  # CPU and Memory
  memory = var.memory
  cpu {
    cores = var.cores
  }

  # Network
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Disk configuration
  scsihw = "virtio-scsi-pci"

  dynamic "disk" {
    for_each = var.clone_template_id != 0 ? [] : [1]
    content {
      slot    = "scsi0"
      type    = "disk"
      storage = var.storage
      size    = var.disk_size
      format  = "raw"
    }
  }

  # If cloning, resize the disk
  dynamic "disk" {
    for_each = var.clone_template_id != 0 ? [1] : []
    content {
      type    = "disk"
      storage = var.storage
      size    = var.disk_size
      slot    = "scsi0"
    }
  }

  dynamic "disk" {
    for_each = [1]
    content {
      slot    = "ide2"
      type    = "cloudinit"
      storage = var.storage
    }
  }

  # Cloud-init configuration
  os_type   = "cloud-init"
  ipconfig0 = "ip=dhcp"

  # Cloud-init settings
  ciuser     = "root"
  cipassword = var.password != "" ? var.password : null
  sshkeys    = var.ssh_public_keys
  cicustom   = "user=nfslorien:snippets/docker-cloud-init.yaml"

  # Serial console for cloud-init
  serial {
    id   = 0
    type = "socket"
  }

  # VGA configuration
  vga {
    type = "std"
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

output "vm_id" {
  value       = proxmox_vm_qemu.vm.vmid
  description = "The VMID of the created VM"
}

output "hostname" {
  value       = proxmox_vm_qemu.vm.name
  description = "The hostname of the created VM"
}
