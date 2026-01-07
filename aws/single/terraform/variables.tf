//AWS Configuration
variable "access_key" {}
variable "secret_key" {}

# Prefix for all resources created for this deployment in AWS
variable "tag_name_prefix" {
  description = "Provide a common tag prefix value that will be used in the name tag for all resources"
  default     = "SINGLE"
}

variable "region" {
  default = "eu-west-1"
}

// Availability zones for the region
variable "availability_zone1" {
  default = "eu-west-1a"
}

variable "vpccidr" {
  default = "10.0.0.0/16"
}

variable "publiccidraz1" {
  default = "10.0.0.0/24"
}

variable "privatecidraz1" {
  default = "10.0.1.0/24"
}

// FortiGate VM version to deploy
variable "fgt_version" {
  default = "7.6.5"
}

// BYOL License format to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either token or file.
variable "license_format" {
  default = "file"
}

// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
  default = "byol"
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
  default = "c6gn.large"
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

variable "adminsport" {
  default = "443"
}

// FGTVM config in plaintext Format for S3 Bucket
variable "bootstrap-fgtvm" {
  // Change to your own path
  type    = string
  default = "fgtvm.conf"
}

// license file for the active fgt
variable "license" {
  // Change to your own byol license file, license.lic
  type    = string
  default = "license.lic"
}
