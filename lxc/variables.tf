variable "vmid" {
  description = "The VM ID for the container"
  type        = number
}

variable "hostname" {
  description = "The hostname for the container"
  type        = string
}

variable "template" {
  description = "The template to use for the container (e.g., local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst)"
  type        = string
}

variable "disk_size" {
  description = "The size of the root disk (e.g., 20G)"
  type        = string
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

variable "unprivileged" {
  description = "Whether the container should be unprivileged (1) or privileged (0)"
  type        = bool
  default     = true
}

variable "node" {
  description = "The Proxmox node to create the container on"
  type        = string
  default     = "erebor"
}

variable "password" {
  description = "Root password for the container"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys to add to the container"
  type        = string
}
