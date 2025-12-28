// AWS VPC - FortiGate
resource "aws_vpc" "fgtvm-vpc" {
  cidr_block           = var.vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.tag_name_prefix}-Sec"
  }
}

resource "aws_subnet" "publicsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.publiccidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Sec-mgmt-az1"
  }
}
//
resource "aws_subnet" "publicsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.publiccidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Sec-mgmt-az2"
  }
}

resource "aws_subnet" "privatesubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Sec-data-az1"
  }
}

resource "aws_subnet" "privatesubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.privatecidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Sec-data-az2"
  }
}

resource "aws_subnet" "transitsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.attachcidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Sec-transit-az1"
  }
}

resource "aws_subnet" "transitsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.attachcidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Sec-transit-az2"
  }
}
resource "aws_subnet" "gwlbsubnetaz1" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.gwlbcidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Sec-gwlb-az1"
  }
}

resource "aws_subnet" "gwlbsubnetaz2" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.gwlbcidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Sec-gwlb-az2"
  }
}

// AWS VPC - Spoke1
resource "aws_vpc" "customer-vpc" {
  count                = var.spokeVpc ? 1 : 0
  cidr_block           = var.csvpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1"
  }
}

resource "aws_subnet" "cspublicsubnetaz1" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.cspubliccidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-GWLBe-az1"
  }
}

resource "aws_subnet" "csprivatesubnetaz1" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.csprivatecidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-App-az1"
  }
}

resource "aws_subnet" "cspublicsubnetaz2" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.cspubliccidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-GWLBe-az2"
  }
}

resource "aws_subnet" "csprivatesubnetaz2" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  cidr_block        = var.csprivatecidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-App-az2"
  }
}


// AWS VPC - Spoke2
resource "aws_vpc" "customer2-vpc" {
  count                = var.spokeVpc ? 1 : 0
  cidr_block           = var.cs2vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2"
  }
}

resource "aws_subnet" "cs2publicsubnetaz1" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer2-vpc[count.index].id
  cidr_block        = var.cs2publiccidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-GWLBe-az1"
  }
}

resource "aws_subnet" "cs2privatesubnetaz1" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer2-vpc[count.index].id
  cidr_block        = var.cs2privatecidraz1
  availability_zone = var.availability_zone1
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-App-az1"
  }
}

resource "aws_subnet" "cs2publicsubnetaz2" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer2-vpc[count.index].id
  cidr_block        = var.cs2publiccidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-GWLBe-az2"
  }
}

resource "aws_subnet" "cs2privatesubnetaz2" {
  count             = var.spokeVpc ? 1 : 0
  vpc_id            = aws_vpc.customer2-vpc[count.index].id
  cidr_block        = var.cs2privatecidraz2
  availability_zone = var.availability_zone2
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-Appe-az2"
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
    Name = "${var.tag_name_prefix}-fgtvm-endpoint-to-s3"
  }
}
