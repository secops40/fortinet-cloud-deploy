##############################################################################################################
# VPC SECURITY
##############################################################################################################
resource "aws_vpc" "vpc_sec" {
  cidr_block           = var.security_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.tag_name_prefix}-vpc_sec"
  }
}

# IGW
resource "aws_internet_gateway" "igw_sec" {
  vpc_id = aws_vpc.vpc_sec.id
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-igw_sec"
  }
}

# Subnets
resource "aws_subnet" "data_subnet1" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_data_subnet_cidr1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-data-subnet1"
  }
}

resource "aws_subnet" "data_subnet2" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_data_subnet_cidr2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-data-subnet2"
  }
}

resource "aws_subnet" "heartbeat_subnet1" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_heartbeat_subnet_cidr1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-heartbeat-subnet1"
  }
}

resource "aws_subnet" "heartbeat_subnet2" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_heartbeat_subnet_cidr2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-heartbeat-subnet2"
  }
}

resource "aws_subnet" "mgmt_subnet1" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_mgmt_subnet_cidr1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-mgmt-subnet1"
  }
}

resource "aws_subnet" "mgmt_subnet2" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_mgmt_subnet_cidr2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-mgmt-subnet2"
  }
}

resource "aws_subnet" "relay_subnet1" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_relay_subnet_cidr1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-relay-subnet1"
  }
}

resource "aws_subnet" "relay_subnet2" {
  vpc_id            = aws_vpc.vpc_sec.id
  cidr_block        = var.security_vpc_relay_subnet_cidr2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-relay-subnet2"
  }
}

# Routes
resource "aws_route_table" "data_rt" {
  vpc_id = aws_vpc.vpc_sec.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_sec.id
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-data-and-mgmt-rt"
  }
}

resource "aws_route_table" "heartbeat_rt" {
  vpc_id = aws_vpc.vpc_sec.id
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-heartbeat-rt"
  }
}

resource "aws_route_table" "relay_rt" {
  vpc_id = aws_vpc.vpc_sec.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.eni-fgt1-data.id
  }
  tags = {
    Name = "${var.tag_name_prefix}-${var.tag_name_unique}-relay-rt"
  }
}

# Route tables associations
resource "aws_route_table_association" "data_rt_association1" {
  subnet_id      = aws_subnet.data_subnet1.id
  route_table_id = aws_route_table.data_rt.id
}

resource "aws_route_table_association" "data_rt_association2" {
  subnet_id      = aws_subnet.data_subnet2.id
  route_table_id = aws_route_table.data_rt.id
}

resource "aws_route_table_association" "mgmt_rt_association1" {
  subnet_id      = aws_subnet.mgmt_subnet1.id
  route_table_id = aws_route_table.data_rt.id
}

resource "aws_route_table_association" "mgmt_rt_association2" {
  subnet_id      = aws_subnet.mgmt_subnet2.id
  route_table_id = aws_route_table.data_rt.id
}

resource "aws_route_table_association" "relay_rt_association1" {
  subnet_id      = aws_subnet.relay_subnet1.id
  route_table_id = aws_route_table.relay_rt.id
}

resource "aws_route_table_association" "relay_rt_association2" {
  subnet_id      = aws_subnet.relay_subnet2.id
  route_table_id = aws_route_table.relay_rt.id
}

# Attachment to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-sec" {
  subnet_ids                                      = [aws_subnet.relay_subnet1.id, aws_subnet.relay_subnet2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.TGW-XAZ.id
  vpc_id                                          = aws_vpc.vpc_sec.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "${var.tag_name_prefix}-att-vpc_sec"
  }
  depends_on = [aws_ec2_transit_gateway.TGW-XAZ]
}


# S3 endpoint inside the VPC
resource "aws_vpc_endpoint" "s3-endpoint-fgtvm-vpc" {
  count           = var.bucket ? 1 : 0
  vpc_id          = aws_vpc.vpc_sec.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.data_rt.id]
  policy          = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
  tags = {
    Name = "fgtvm-endpoint-to-s3"
  }
}
