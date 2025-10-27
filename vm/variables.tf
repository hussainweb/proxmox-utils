variable "vmid" {
  description = "The VM ID for the virtual machine"
  type        = number
}

variable "hostname" {
  description = "The hostname for the virtual machine"
  type        = string
}

variable "disk_size" {
  description = "The size of the root disk (e.g., 20G)"
  type        = string
  default     = "20G"
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Amount of RAM in MB"
  type        = number
  default     = 2048
}

variable "node" {
  description = "The Proxmox node to create the VM on"
  type        = string
  default     = "erebor"
}

variable "password" {
  description = "Root password for the VM (optional, blank by default)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "bios" {
  description = "BIOS type: ovmf (UEFI) or seabios"
  type        = string
  default     = "seabios"
}

variable "storage" {
  description = "Storage for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "clone_template_id" {
  description = "Template ID to clone from (0 for no cloning)"
  type        = number
  default     = 0
}

variable "ssh_public_keys" {
  description = "SSH public keys to add to the VM"
  type        = string
}
