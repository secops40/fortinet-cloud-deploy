module "spoke" {
  source     = "./modules/spoke"
  count      = var.spokeVpc ? 1 : 0
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]

  spoke_vpc1_cidr                 = var.spoke_vpc1_cidr
  spoke_vpc1_private_subnet_cidr1 = var.spoke_vpc1_private_subnet_cidr1
  spoke_vpc1_private_subnet_cidr2 = var.spoke_vpc1_private_subnet_cidr2
  spoke_vpc2_cidr                 = var.spoke_vpc2_cidr
  spoke_vpc2_private_subnet_cidr1 = var.spoke_vpc2_private_subnet_cidr1
  spoke_vpc2_private_subnet_cidr2 = var.spoke_vpc2_private_subnet_cidr2
  availability_zone1              = var.availability_zone1
  availability_zone2              = var.availability_zone2
  tag_name_prefix                 = var.tag_name_prefix
  tgw_id                          = aws_ec2_transit_gateway.TGW-XAZ.id
  vpc_attachment_sec_id           = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-sec.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.TGW-VPC-SEC-rt.id
}

