# ============================================================
# Static public IPs for FortiSIEM
# ============================================================

resource "google_compute_address" "fsm" {
  count  = var.fsm_count
  name   = "${var.prefix}-fsm-${count.index + 1}-ip"
  region = var.region
}

# ============================================================
# FortiSIEM extra disks
# Disk 2: /opt  100 GB
# Disk 3: /svn   60 GB
# Disk 4: /cmdb  60 GB
# Disk 5: /data  var.fsm_disk5_size_gb (default 60 GB)
# ============================================================

resource "google_compute_disk" "fsm_opt" {
  count = var.fsm_count
  name  = "${var.prefix}-fsm-${count.index + 1}-opt"
  zone  = element(local.zones, count.index % length(local.zones))
  type  = var.fsm_opt_disk_type
  size  = 100

  labels = {
    keep_resource = "true"
  }
}

resource "google_compute_disk" "fsm_svn" {
  count = var.fsm_count
  name  = "${var.prefix}-fsm-${count.index + 1}-svn"
  zone  = element(local.zones, count.index % length(local.zones))
  type  = var.fsm_svn_disk_type
  size  = 60

  labels = {
    keep_resource = "true"
  }
}

resource "google_compute_disk" "fsm_cmdb" {
  count = var.fsm_count
  name  = "${var.prefix}-fsm-${count.index + 1}-cmdb"
  zone  = element(local.zones, count.index % length(local.zones))
  type  = var.fsm_cmdb_disk_type
  size  = 60

  labels = {
    keep_resource = "true"
  }
}

resource "google_compute_disk" "fsm_data" {
  count = var.fsm_count
  name  = "${var.prefix}-fsm-${count.index + 1}-data"
  zone  = element(local.zones, count.index % length(local.zones))
  type  = var.fsm_data_disk_type
  size  = var.fsm_disk5_size_gb

  labels = {
    keep_resource = "true"
  }
}

# ============================================================
# FortiSIEM instances
# Instances are distributed across the 2 zones (round-robin):
#   fsm-1 → zones[0], fsm-2 → zones[1], fsm-3 → zones[0], …
# ============================================================

resource "google_compute_instance" "fsm" {
  count        = var.fsm_count
  name         = "${var.prefix}-fsm-${count.index + 1}"
  machine_type = var.fsm_machine_type
  zone         = element(local.zones, count.index % length(local.zones))

  labels = {
    keep_resource = "true"
  }

  metadata            = local.fsm_metadata
  deletion_protection = var.deletion_protection

  # Boot disk (Disk 1) — image supplies the root partition
  boot_disk {
    initialize_params {
      image = local.fsm_image
      type  = var.fsm_boot_disk_type
      labels = {
        keep_resource = "true"
      }
    }
  }

  # Disk 2 — /opt (100 GB); configFSM.sh will split into /opt + swap
  attached_disk {
    source      = google_compute_disk.fsm_opt[count.index].self_link
    device_name = "${var.prefix}-fsm-${count.index + 1}-opt"
  }

  # Disk 3 — /svn (60 GB)
  attached_disk {
    source      = google_compute_disk.fsm_svn[count.index].self_link
    device_name = "${var.prefix}-fsm-${count.index + 1}-svn"
  }

  # Disk 4 — /cmdb (60 GB)
  attached_disk {
    source      = google_compute_disk.fsm_cmdb[count.index].self_link
    device_name = "${var.prefix}-fsm-${count.index + 1}-cmdb"
  }

  # Disk 5 — /data (configurable, default 60 GB)
  attached_disk {
    source      = google_compute_disk.fsm_data[count.index].self_link
    device_name = "${var.prefix}-fsm-${count.index + 1}-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets[element(local.zones, count.index % length(local.zones))].id

    access_config {
      # Static (fixed) public IP
      nat_ip = google_compute_address.fsm[count.index].address
    }
  }

  scheduling {
    automatic_restart           = var.fsm_use_spot ? false : true
    on_host_maintenance         = var.fsm_use_spot ? "TERMINATE" : "MIGRATE"
    preemptible                 = var.fsm_use_spot
    provisioning_model          = var.fsm_use_spot ? "SPOT" : "STANDARD"
    instance_termination_action = var.fsm_use_spot ? var.fsm_spot_termination_action : null
  }
}
