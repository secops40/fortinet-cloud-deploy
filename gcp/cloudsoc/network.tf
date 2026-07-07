# ============================================================
# VPC
# ============================================================

resource "google_compute_network" "vpc" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
  mtu                     = var.vpc_mtu
}

# ============================================================
# Subnets — one per zone, each a /24 carved from var.ip_block
# Naming: <prefix>-vpc-<zone>  e.g. test-vpc-asia-east1-a
# ============================================================

resource "google_compute_subnetwork" "subnets" {
  for_each = local.subnet_cidrs

  name          = "${var.prefix}-vpc-${each.key}"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = each.value
}

# ============================================================
# Firewall — management: full access from trusted IPs
# ============================================================

resource "google_compute_firewall" "management" {
  name    = "${var.prefix}-fw-management"
  network = google_compute_network.vpc.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.management_source_ips

  allow {
    protocol = "all"
  }
}

# ============================================================
# Firewall — HTTPS: TCP 443 from specified source IPs
# ============================================================

resource "google_compute_firewall" "https" {
  count = length(var.https_source_ips) > 0 ? 1 : 0

  name    = "${var.prefix}-fw-https"
  network = google_compute_network.vpc.name

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.https_source_ips

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
