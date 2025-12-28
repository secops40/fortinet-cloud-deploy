########################################################
# Transit Gateway
########################################################
resource "aws_ec2_transit_gateway" "terraform-tgwy" {
  description                     = "Transit Gateway with 3 VPCs"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = var.tag_name_prefix
  }
}

# Route Table - FGT VPC
resource "aws_ec2_transit_gateway_route_table" "tgwy-fgt-route" {
  depends_on         = [aws_ec2_transit_gateway.terraform-tgwy]
  transit_gateway_id = aws_ec2_transit_gateway.terraform-tgwy.id
  tags = {
    Name = "${var.tag_name_prefix}-Sec-tgwy-rt"
  }
}

# Route Table - Spoke VPC
resource "aws_ec2_transit_gateway_route_table" "tgwy-vpc-route" {
  count              = var.spokeVpc ? 1 : 0
  depends_on         = [aws_ec2_transit_gateway.terraform-tgwy]
  transit_gateway_id = aws_ec2_transit_gateway.terraform-tgwy.id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke-tgwy-rt"
  }
}


# VPC attachment - FGT VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-fgt" {
  appliance_mode_support                          = "enable"
  subnet_ids                                      = [aws_subnet.transitsubnetaz1.id, aws_subnet.transitsubnetaz2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.terraform-tgwy.id
  vpc_id                                          = aws_vpc.fgtvm-vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "${var.tag_name_prefix}-tgwy-att-Sec"
  }
  depends_on = [aws_ec2_transit_gateway.terraform-tgwy]
}

# VPC attachment - Spoke1 VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-vpc1" {
  count                                           = var.spokeVpc ? 1 : 0
  appliance_mode_support                          = "enable"
  subnet_ids                                      = [aws_subnet.csprivatesubnetaz1[count.index].id, aws_subnet.csprivatesubnetaz2[count.index].id]
  transit_gateway_id                              = aws_ec2_transit_gateway.terraform-tgwy.id
  vpc_id                                          = aws_vpc.customer-vpc[count.index].id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "${var.tag_name_prefix}-tgwy-att-Spoke1"
  }
  depends_on = [aws_ec2_transit_gateway.terraform-tgwy]
}

# VPC attachment - Spoke2 VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-vpc2" {
  count                                           = var.spokeVpc ? 1 : 0
  appliance_mode_support                          = "enable"
  subnet_ids                                      = [aws_subnet.cs2privatesubnetaz1[count.index].id, aws_subnet.cs2privatesubnetaz2[count.index].id]
  transit_gateway_id                              = aws_ec2_transit_gateway.terraform-tgwy.id
  vpc_id                                          = aws_vpc.customer2-vpc[count.index].id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = "${var.tag_name_prefix}-tgwy-att-Spoke2"
  }
  depends_on = [aws_ec2_transit_gateway.terraform-tgwy]
}


# TGW Routes - Spoke1 VPC
resource "aws_ec2_transit_gateway_route" "customer-default-route" {
  count                          = var.spokeVpc ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-fgt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc-route[count.index].id
}

# Route Tables Associations - Spoke1 VPC
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-customer-assoc" {
  count                          = var.spokeVpc ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc1[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc-route[count.index].id
}

# Route Tables Associations - Spoke 2 VPC
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-customer2-assoc" {
  count                          = var.spokeVpc ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc2[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc-route[count.index].id
}


# Route Tables Propagations - Spoke VPC Route
# resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prop-cs-w-fgt" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-fgt.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-vpc-route.id
# }



# Route Tables Associations - FGT VPC
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-fgt-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-fgt.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-fgt-route.id
}


# Route Tables Propagations - FGT VPC Route
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prop-fgt-w-cs" {
  count = var.spokeVpc ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc1[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-fgt-route.id
}


# Route Tables Propagations - FGT VPC2 Route
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-prop-fgt-w-cs2" {
  count = var.spokeVpc ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-vpc2[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgwy-fgt-route.id
}



