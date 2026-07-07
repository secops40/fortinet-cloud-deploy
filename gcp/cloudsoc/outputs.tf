output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_info" {
  description = "Zone → subnet name / CIDR"
  value = {
    for zone, sn in google_compute_subnetwork.subnets :
    zone => { name = sn.name, cidr = sn.ip_cidr_range }
  }
}

output "fsm_instances" {
  description = "FortiSIEM instance name → zone / public IP"
  value = {
    for i, inst in google_compute_instance.fsm :
    inst.name => {
      zone      = inst.zone
      public_ip = google_compute_address.fsm[i].address
    }
  }
}

output "fsr_instance" {
  description = "FortiSOAR instance name / zone / public IP"
  value = {
    name      = google_compute_instance_from_machine_image.fsr.name
    zone      = google_compute_instance_from_machine_image.fsr.zone
    public_ip = google_compute_address.fsr.address
  }
}
