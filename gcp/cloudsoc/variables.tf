# ============================================================
# Project & Region
# ============================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "prefix" {
  description = "Resource name prefix, e.g. 'test' → test-vpc, test-fsm-1, test-fsr-1"
  type        = string
}

variable "region" {
  description = "GCP region to deploy into"
  type        = string
  default     = "asia-east1"
}

variable "zones_override" {
  description = "Override the two deployment zones (default: <region>-a and <region>-b)"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.zones_override) == 0 || length(var.zones_override) == 2
    error_message = "zones_override must be empty (use defaults) or contain exactly 2 zones."
  }
}

# ============================================================
# Networking
# ============================================================

variable "ip_block" {
  description = "VPC IP block /16; each of the 2 subnets gets a /24 carved out of it"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_mtu" {
  description = "VPC MTU (1300–8896). Use 1460 if traffic traverses VPN/GRE tunnels to avoid fragmentation."
  type        = number
  default     = 1500
  validation {
    condition     = var.vpc_mtu >= 1300 && var.vpc_mtu <= 8896
    error_message = "vpc_mtu must be between 1300 and 8896."
  }
}

variable "management_source_ips" {
  description = "Source CIDRs with full management access (all protocols, all instances)"
  type        = list(string)
  default = [
    "123.51.251.120/32",
    "60.250.130.67/32",
    "60.250.130.70/32",
    "123.51.251.127/32",
    "111.185.24.12/32",
  ]
  validation {
    condition = alltrue([
      for cidr in var.management_source_ips : can(cidrnetmask(cidr))
    ])
    error_message = "All entries in management_source_ips must be valid CIDR ranges (e.g. 1.2.3.4/32)."
  }
}

variable "https_source_ips" {
  description = "Source CIDRs allowed to reach TCP 443; set [] to skip creating the HTTPS firewall rule"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.https_source_ips : can(cidrnetmask(cidr))
    ])
    error_message = "All entries in https_source_ips must be valid CIDR ranges (e.g. 1.2.3.4/32)."
  }
}

# ============================================================
# FortiSIEM
# ============================================================

variable "fsm_count" {
  description = "Number of FortiSIEM instances to create (1–4); distributed across the 2 zones"
  type        = number
  default     = 1
  validation {
    condition     = var.fsm_count >= 1 && var.fsm_count <= 4
    error_message = "fsm_count must be between 1 and 4."
  }
}

variable "fsm_image" {
  description = "FortiSIEM boot image name"
  type        = string
  default     = "fortisiem-gcp-7-5-1-0620"
}

variable "fsm_image_project" {
  description = "GCP project that owns the FortiSIEM image; empty = same as var.project_id"
  type        = string
  default     = ""
}

variable "fsm_machine_type" {
  description = "FortiSIEM machine type"
  type        = string
  default     = "n2-standard-8"
}

variable "fsm_boot_disk_type" {
  description = "FortiSIEM boot disk type (pd-ssd, pd-balanced, pd-standard)"
  type        = string
  default     = "pd-ssd"
}

variable "fsm_opt_disk_type" {
  description = "FortiSIEM /opt disk type (Disk 2, 100 GB)"
  type        = string
  default     = "pd-balanced"
}

variable "fsm_svn_disk_type" {
  description = "FortiSIEM /svn disk type (Disk 3, 60 GB)"
  type        = string
  default     = "pd-balanced"
}

variable "fsm_cmdb_disk_type" {
  description = "FortiSIEM /cmdb disk type (Disk 4, 60 GB)"
  type        = string
  default     = "pd-balanced"
}

variable "fsm_data_disk_type" {
  description = "FortiSIEM /data disk type (Disk 5, configurable size)"
  type        = string
  default     = "pd-ssd"
}

variable "fsm_disk5_size_gb" {
  description = "FortiSIEM Disk 5 (/data) size in GB (minimum 60)"
  type        = number
  default     = 60
  validation {
    condition     = var.fsm_disk5_size_gb >= 60
    error_message = "Disk 5 (/data) must be at least 60 GB."
  }
}

variable "fsm_use_spot" {
  description = "Use SPOT pricing for FortiSIEM instances"
  type        = bool
  default     = false
}

variable "fsm_spot_termination_action" {
  description = "What happens to a FortiSIEM SPOT instance when preempted: STOP (default) or DELETE"
  type        = string
  default     = "STOP"
  validation {
    condition     = contains(["STOP", "DELETE"], var.fsm_spot_termination_action)
    error_message = "fsm_spot_termination_action must be STOP or DELETE."
  }
}

# ============================================================
# FortiSOAR
# ============================================================

variable "fsr_image" {
  description = "FortiSOAR Machine Image name (not a boot disk image)"
  type        = string
  default     = "fortisoar-vmware-8-0-0-6034"
}

variable "fsr_image_project" {
  description = "GCP project that owns the FortiSOAR image; empty = same as var.project_id"
  type        = string
  default     = ""
}

variable "fsr_machine_type" {
  description = "FortiSOAR machine type"
  type        = string
  default     = "n2-standard-8"
}

variable "fsr_use_spot" {
  description = "Use SPOT pricing for the FortiSOAR instance"
  type        = bool
  default     = false
}

variable "fsr_spot_termination_action" {
  description = "What happens to the FortiSOAR SPOT instance when preempted: DELETE (default) or STOP"
  type        = string
  default     = "DELETE"
  validation {
    condition     = contains(["STOP", "DELETE"], var.fsr_spot_termination_action)
    error_message = "fsr_spot_termination_action must be STOP or DELETE."
  }
}

# ============================================================
# Instance Protection
# ============================================================

variable "deletion_protection" {
  description = "Enable deletion protection on all instances; set true in prod to prevent accidental destroy"
  type        = bool
  default     = false
}

# ============================================================
# SSH
# ============================================================

variable "fsm_ssh_keys" {
  description = <<-EOT
    SSH public keys for FortiSIEM (required, at least one).
    Format: "yourusername:ssh-rsa AAAA..."
    The username determines which OS account receives the key.
    Run: gcloud config get-value account | cut -d@ -f1
  EOT
  type        = list(string)
  validation {
    condition     = length(var.fsm_ssh_keys) > 0
    error_message = "fsm_ssh_keys must contain at least one SSH key (format: \"username:ssh-rsa AAAA...\")."
  }
}

variable "fsr_ssh_keys" {
  description = <<-EOT
    SSH public keys for FortiSOAR (optional).
    If provided, username must be csadmin (format: "csadmin:ssh-rsa AAAA...").
    Note: FortiSOAR is created from a Machine Image; use default password 'changeme' to log in.
  EOT
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for k in var.fsr_ssh_keys : startswith(k, "csadmin:")])
    error_message = "All FortiSOAR SSH keys must use username 'csadmin' (format: \"csadmin:ssh-rsa AAAA...\")."
  }
}
