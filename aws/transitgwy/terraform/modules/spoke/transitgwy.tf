# Route Tables
resource "aws_ec2_transit_gateway_route_table" "TGW-spoke-rt" {
  transit_gateway_id = var.tgw_id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke-rt"
  }
}

# TGW routes
resource "aws_ec2_transit_gateway_route" "spokes_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.vpc_attachment_sec_id 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

# Route Tables Associations
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-spoke1-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-spoke2-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-spoke-rt.id
}

# Route Tables Propagations
## This section defines which VPCs will be routed from each Route Table created in the Transit Gateway

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc1.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prp-vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-spoke-vpc2.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_route" "sec_to_spoke1_route" {
  route_table_id         = var.sec_vpc_route_table_id
  destination_cidr_block = var.spoke_vpc1_cidr
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "sec_to_spoke2_route" {
  route_table_id         = var.sec_vpc_route_table_id
  destination_cidr_block = var.spoke_vpc2_cidr
  transit_gateway_id     = var.tgw_id
}

