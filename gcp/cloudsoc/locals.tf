locals {
  # The two deployment zones; defaults to <region>-a and <region>-b
  zones = length(var.zones_override) == 2 ? var.zones_override : [
    "${var.region}-a",
    "${var.region}-b",
  ]

  # Carve a /24 out of the /16 for each zone: offset 1 → x.x.1.0/24, offset 2 → x.x.2.0/24
  subnet_cidrs = {
    (local.zones[0]) = cidrsubnet(var.ip_block, 8, 1)
    (local.zones[1]) = cidrsubnet(var.ip_block, 8, 2)
  }

  # Resolve full image paths
  fsm_image = var.fsm_image_project != "" ? "projects/${var.fsm_image_project}/global/images/${var.fsm_image}" : var.fsm_image
  # FortiSOAR uses a Machine Image — must be fully project-qualified
  fsr_machine_image = var.fsr_image_project != "" ? "projects/${var.fsr_image_project}/global/machineImages/${var.fsr_image}" : "projects/${var.project_id}/global/machineImages/${var.fsr_image}"

  base_metadata = {
    "block-project-ssh-keys"    = "true"
    "google-logging-enabled"    = "false"
    "google-monitoring-enabled" = "false"
  }

  # FortiSIEM: SSH key always injected (fsm_ssh_keys is required)
  fsm_metadata = merge(local.base_metadata, {
    "ssh-keys" = join("\n", var.fsm_ssh_keys)
  })

  # FortiSOAR: SSH key optional
  fsr_metadata = merge(
    local.base_metadata,
    length(var.fsr_ssh_keys) > 0 ? { "ssh-keys" = join("\n", var.fsr_ssh_keys) } : {}
  )
}
