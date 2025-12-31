variable "spoke_vpc1_cidr" {
  description = "CIDR block for Spoke VPC 1"
  type        = string
}

variable "spoke_vpc1_private_subnet_cidr1" {
  description = "CIDR block for Spoke VPC 1 private subnet 1"
  type        = string
}

variable "spoke_vpc1_private_subnet_cidr2" {
  description = "CIDR block for Spoke VPC 1 private subnet 2"
  type        = string
}

variable "spoke_vpc2_cidr" {
  description = "CIDR block for Spoke VPC 2"
  type        = string
}

variable "spoke_vpc2_private_subnet_cidr1" {
  description = "CIDR block for Spoke VPC 2 private subnet 1"
  type        = string
}

variable "spoke_vpc2_private_subnet_cidr2" {
  description = "CIDR block for Spoke VPC 2 private subnet 2"
  type        = string
}

variable "availability_zone1" {
  description = "Availability Zone 1 for Subnet creation"
  type        = string
}

variable "availability_zone2" {
  description = "Availability Zone 2 for Subnet creation"
  type        = string
}

variable "tag_name_prefix" {
  description = "Prefix for resource names (tags)"
  type        = string
}

variable "tgw_id" {
  description = "ID of the Transit Gateway"
  type        = string
}

variable "vpc_attachment_sec_id" {
  description = "VPC Attachment ID for Sec"
  type        = string
}

variable "transit_gateway_route_table_id" {
  description = "Transit gateway route table ID for Sec"
  type        = string
}

