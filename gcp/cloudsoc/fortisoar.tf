# ============================================================
# Static public IP for FortiSOAR
# ============================================================

resource "google_compute_address" "fsr" {
  name   = "${var.prefix}-fsr-1-ip"
  region = var.region
}

# ============================================================
# FortiSOAR instance — created from Machine Image, placed in zones[0]
# ============================================================

resource "google_compute_instance_from_machine_image" "fsr" {
  provider             = google-beta
  name                 = "${var.prefix}-fsr-1"
  machine_type         = var.fsr_machine_type
  zone                 = local.zones[0]
  source_machine_image = local.fsr_machine_image

  labels = {
    keep_resource = "true"
  }

  metadata            = local.fsr_metadata
  deletion_protection = var.deletion_protection

  network_interface {
    subnetwork = google_compute_subnetwork.subnets[local.zones[0]].id

    access_config {
      nat_ip = google_compute_address.fsr.address
    }
  }

  scheduling {
    automatic_restart           = var.fsr_use_spot ? false : true
    on_host_maintenance         = var.fsr_use_spot ? "TERMINATE" : "MIGRATE"
    preemptible                 = var.fsr_use_spot
    provisioning_model          = var.fsr_use_spot ? "SPOT" : "STANDARD"
    instance_termination_action = var.fsr_use_spot ? var.fsr_spot_termination_action : null
  }
}
