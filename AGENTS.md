# Agent Instructions for Proxmox Utils

This file contains instructions and context for AI agents (like Gemini CLI) working with this repository.

## Repository Architecture

This repository uses a specific pattern: wrapping Terraform configurations with Bash scripts to provide a simpler CLI experience and manage individual states per resource.

The wrapper scripts (`lxc/create-lxc.sh` and `vm/create-vm.sh`) are responsible for:
1. Parsing user input arguments.
2. Dynamically generating a `terraform.tfvars` file for the required Terraform variables.
3. Managing Terraform state locally by creating a local `states/` directory and generating a dynamic `backend.tfbackend` configured for the specific `VMID` (e.g., `states/terraform-100.tfstate`).
4. Reconfiguring the backend and applying the Terraform configuration (`terraform apply -auto-approve`).

## Agent Guidelines

- **Always use the Wrapper Scripts:** When tasked with creating or managing a VM or LXC container, prefer invoking the bash scripts (`./create-lxc.sh` or `./create-vm.sh`) rather than running `terraform` commands manually. This ensures state is correctly scoped to the VMID.
- **Modifying Terraform Files:** 
  - If you add or modify variables in `lxc/variables.tf` or `vm/variables.tf`, you **MUST** also update the corresponding `create-*.sh` script to parse those arguments and inject them into the generated `terraform.tfvars`.
  - Keep Terraform files strictly focused on resource declaration.
- **State and Generated Files:** Do not commit generated `.tfvars`, `backend.tfbackend` files, or the `states/` directories. These should be covered by `.gitignore`.
- **Proxmox Provider Authentication:** The Terraform configurations use the `bpg/proxmox` provider. Assume that authentication variables (`PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`) are injected via the user's environment. Do not hardcode credentials anywhere in the code.
- **Adding New Resource Types:** If a new resource type is added (e.g., Proxmox storage management), follow the existing pattern: create a dedicated directory, write the Terraform files, and provide a Bash wrapper script to manage the local state based on a unique identifier.
