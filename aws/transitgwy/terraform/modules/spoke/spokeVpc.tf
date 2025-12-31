#############################################################################################################
# VPC SPOKE1
#############################################################################################################
resource "aws_vpc" "spoke_vpc1" {
  cidr_block = var.spoke_vpc1_cidr

  tags = {
    Name     = "${var.tag_name_prefix}-Spoke1"
  }
}

# Subnets
resource "aws_subnet" "spoke_vpc1-priv1" {
  vpc_id            = aws_vpc.spoke_vpc1.id
  cidr_block        = var.spoke_vpc1_private_subnet_cidr1
  availability_zone = var.availability_zone1

  tags = {
    Name = "${aws_vpc.spoke_vpc1.tags.Name}-az1"
  }
}

resource "aws_subnet" "spoke_vpc1-priv2" {
  vpc_id            = aws_vpc.spoke_vpc1.id
  cidr_block        = var.spoke_vpc1_private_subnet_cidr2
  availability_zone = var.availability_zone2

  tags = {
    Name = "${aws_vpc.spoke_vpc1.tags.Name}-az2"
  }
}

# Routes
resource "aws_route_table" "spoke1-rt" {
  vpc_id = aws_vpc.spoke_vpc1.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.tgw_id
  }

  tags = {
    Name     = "${aws_vpc.spoke_vpc1.tags.Name}-rt"
  }
}

# Route tables associations
resource "aws_route_table_association" "spoke1_rt_association1" {
  subnet_id      = aws_subnet.spoke_vpc1-priv1.id
  route_table_id = aws_route_table.spoke1-rt.id
}

resource "aws_route_table_association" "spoke1_rt_association2" {
  subnet_id      = aws_subnet.spoke_vpc1-priv2.id
  route_table_id = aws_route_table.spoke1-rt.id
}

# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-spoke-vpc1" {
  subnet_ids                                      = [aws_subnet.spoke_vpc1-priv1.id, aws_subnet.spoke_vpc1-priv2.id]
  transit_gateway_id                              = var.tgw_id
  vpc_id                                          = aws_vpc.spoke_vpc1.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "${var.tag_name_prefix}-att-Spoke1"
  }
}

#############################################################################################################
# VPC SPOKE2
#############################################################################################################
resource "aws_vpc" "spoke_vpc2" {
  cidr_block = var.spoke_vpc2_cidr

  tags = {
    Name     = "${var.tag_name_prefix}-Spoke2"
  }
}

# Subnets
resource "aws_subnet" "spoke_vpc2-priv1" {
  vpc_id            = aws_vpc.spoke_vpc2.id
  cidr_block        = var.spoke_vpc2_private_subnet_cidr1
  availability_zone = var.availability_zone1

  tags = {
    Name = "${aws_vpc.spoke_vpc2.tags.Name}-az1"
  }
}

resource "aws_subnet" "spoke_vpc2-priv2" {
  vpc_id            = aws_vpc.spoke_vpc2.id
  cidr_block        = var.spoke_vpc2_private_subnet_cidr2
  availability_zone = var.availability_zone2

  tags = {
    Name = "${aws_vpc.spoke_vpc2.tags.Name}-az2"
  }
}

# Routes
resource "aws_route_table" "spoke2-rt" {
  vpc_id = aws_vpc.spoke_vpc2.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.tgw_id
  }

  tags = {
    Name     = "${aws_vpc.spoke_vpc2.tags.Name}-rt"
  }
}

# Route tables associations
resource "aws_route_table_association" "spoke2_rt_association1" {
  subnet_id      = aws_subnet.spoke_vpc2-priv1.id
  route_table_id = aws_route_table.spoke2-rt.id
}

resource "aws_route_table_association" "spoke2_rt_association2" {
  subnet_id      = aws_subnet.spoke_vpc2-priv2.id
  route_table_id = aws_route_table.spoke2-rt.id
}

# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-spoke-vpc2" {
  subnet_ids                                      = [aws_subnet.spoke_vpc2-priv1.id, aws_subnet.spoke_vpc2-priv2.id]
  transit_gateway_id                              = var.tgw_id
  vpc_id                                          = aws_vpc.spoke_vpc2.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "${var.tag_name_prefix}-att-Spoke2"
  }
}
