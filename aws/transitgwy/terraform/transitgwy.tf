##############################################################################################################
# TRANSIT GATEWAY
##############################################################################################################
resource "aws_ec2_transit_gateway" "TGW-XAZ" {
  description                     = "Transit Gateway with 3 VPCs. 2 subnets in each."
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = var.tag_name_prefix
  }
}

# Route Tables
resource "aws_ec2_transit_gateway_route_table" "TGW-VPC-SEC-rt" {
  depends_on         = [aws_ec2_transit_gateway.TGW-XAZ]
  transit_gateway_id = aws_ec2_transit_gateway.TGW-XAZ.id
  tags = {
    Name     = "${var.tag_name_prefix}-Sec-rt"
  }
}

# TGW routes
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc_sec" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-sec.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.TGW-VPC-SEC-rt.id
}

# Route Tables Associations
