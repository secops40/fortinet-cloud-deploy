// AWS VPC - FortiGate 
resource "aws_vpc" "fgtvm-vpc" {
  cidr_block           = var.vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.tag_name_prefix}-SecVpc"
  }
}

resource "aws_subnet" "publicsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.publiccidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-SecVpc - Mgt Subnet1"
  }
}

resource "aws_subnet" "privatesubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-SecVpc - GWLB Subnet1"
  }
}

resource "aws_subnet" "publicsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.publiccidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-SecVpc - Mgt Subnet2"
  }
}

resource "aws_subnet" "privatesubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-SecVpc - GWLB Subnet2"
  }
}

// AWS VPC - Customer
resource "aws_vpc" "customer-vpc" {
  count                = var.appVpc ? 1 : 0
  cidr_block           = var.csvpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.tag_name_prefix}-AppVpc"
  }
}

resource "aws_subnet" "cspublicsubnetaz1" {
  count             = var.appVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.cspubliccidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-AppVpc - GWLBe Subnet1"
  }
}

resource "aws_subnet" "csprivatesubnetaz1" {
  count             = var.appVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.csprivatecidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-AppVpc - App Subnet1"
  }
}

resource "aws_subnet" "cspublicsubnetaz2" {
  count             = var.appVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.cspubliccidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-AppVpc - GWLBe Subnet2"
  }
}

resource "aws_subnet" "csprivatesubnetaz2" {
  count             = var.appVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.csprivatecidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-AppVpc - App Subnet2"
  }
}

# S3 endpoint inside the VPC
resource "aws_vpc_endpoint" "s3-endpoint-fgtvm-vpc" {
  count           = var.bucket ? 1 : 0
  vpc_id          = aws_vpc.fgtvm-vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.fgtvmpublicrt.id]
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
    Name = "${var.tag_name_prefix} - fgtvm-endpoint-to-s3"
  }
}
