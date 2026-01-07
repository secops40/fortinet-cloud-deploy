//AWS Configuration
variable "access_key" {}
variable "secret_key" {}

# Prefix for all resources created for this deployment in AWS
variable "tag_name_prefix" {
  description = "Provide a common tag prefix value that will be used in the name tag for all resources"
  default     = "TGW-GWLB"
}

// Create Spoke Vpcs
// Either true or false
variable "spokeVpc" {
  type    = bool
  default = "false"
}

variable "region" {
  default = "eu-west-1"
}

// Availability zones for the region
variable "availability_zone1" {
  default = "eu-west-1a"
}

variable "availability_zone2" {
  default = "eu-west-1b"
}

// VPC for FortiGate Security VPC
variable "vpccidr" {
  default = "10.0.0.0/16"
}

variable "publiccidraz1" {
  default = "10.0.0.0/24"
}

variable "privatecidraz1" {
  default = "10.0.1.0/24"
}

variable "attachcidraz1" {
  default = "10.0.2.0/24"
}

variable "gwlbcidraz1" {
  default = "10.0.3.0/24"
}

variable "publiccidraz2" {
  default = "10.0.10.0/24"
}

variable "privatecidraz2" {
  default = "10.0.11.0/24"
}

variable "attachcidraz2" {
  default = "10.0.12.0/24"
}

variable "gwlbcidraz2" {
  default = "10.0.13.0/24"
}



// VPC for Spoke1 VPC
variable "csvpccidr" {
  default = "10.1.0.0/16"
}

variable "cspubliccidraz1" {
  default = "10.1.0.0/24"
}

variable "csprivatecidraz1" {
  default = "10.1.1.0/24"
}


variable "cspubliccidraz2" {
  default = "10.1.10.0/24"
}

variable "csprivatecidraz2" {
  default = "10.1.11.0/24"
}

// VPC for Spoke2 VPC
variable "cs2vpccidr" {
  default = "10.2.0.0/16"
}

variable "cs2publiccidraz1" {
  default = "10.2.0.0/24"
}

variable "cs2privatecidraz1" {
  default = "10.2.1.0/24"
}


variable "cs2publiccidraz2" {
  default = "10.2.10.0/24"
}

variable "cs2privatecidraz2" {
  default = "10.2.11.0/24"
}

// use s3 bucket for bootstrap
// Either true or false
//
variable "bucket" {
  type    = bool
  default = "false"
}

// instance architect
// Either arm or x86
variable "arch" {
  default = "arm"
}

// instance type needs to match the architect
// c5.xlarge is x86_64
// c6g.xlarge is arm
// For detail, refer to https://aws.amazon.com/ec2/instance-types/
variable "instance_type" {
  default = "c6gn.xlarge"
}


// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
  default = "payg"
}

// BYOL License format to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, file.
variable "license_format" {
  default = "file"
}

// FortiGate VM version to deploy
variable "fgt_version" {
  default = "7.6.5"
}


#############################################################################################################
#  AMI

locals {
  fgtlocator = {
    payg = {
      arm = "FortiGate-VMARM64-AWSONDEMAND build*${var.fgt_version}*"
      x86 = "FortiGate-VM64-AWSONDEMAND build*${var.fgt_version}*"
    },
    byol = {
      arm = "FortiGate-VMARM64-AWS build*${var.fgt_version}*"
      x86 = "FortiGate-VM64-AWS build*${var.fgt_version}*"
    }
  }
}

data "aws_ami" "fgt_ami" {
  most_recent = true
  owners      = ["aws-marketplace"] # Fortinet

  filter {
    name   = "name"
    values = [local.fgtlocator[var.license_type][var.arch]]
  }
}

locals {
  ami_id = data.aws_ami.fgt_ami.id
}

//  Existing SSH Key on the AWS 
variable "keypair" {
  default = "<AWS SSH KEY>"
}

//  Admin HTTPS access port
variable "adminsport" {
  default = "443"
}

variable "bootstrap-fgtvm" {
  // Change to your own path
  type    = string
  default = "fgtvm.conf"
}

//license files for the two fgts
variable "licenses" {
  // Change to your own byol license files
  type    = list(string)
  default = ["license.lic", "license2.lic"]
}
