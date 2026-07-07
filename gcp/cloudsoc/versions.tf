terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# google-beta is required for google_compute_instance_from_machine_image (FortiSOAR)
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
