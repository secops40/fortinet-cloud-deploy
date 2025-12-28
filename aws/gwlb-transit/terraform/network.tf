// Creating Internet Gateway
resource "aws_internet_gateway" "fgtvmigw" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "${var.tag_name_prefix}-Sec-igw"
  }
}

// Spoke 1 IGW
resource "aws_internet_gateway" "csigw" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-igw"
  }
}

// Spoke 2 IGW
resource "aws_internet_gateway" "cs2igw" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer2-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-igw"
  }
}

// FGT VPC Route Table
resource "aws_route_table" "fgtvmpublicrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-mgmt-rt"
  }
}

resource "aws_route_table" "fgtvmprivatert" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-data-rt"
  }
}

resource "aws_route_table" "fgtvmtgwrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-tgw1-rt"
  }
}

resource "aws_route_table" "fgtvmtgwrt2" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-tgw2-rt"
  }
}

resource "aws_route_table" "fgtvmgwlbrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-gwlbe-rt"
  }
}



# FGT VPC Route
resource "aws_route" "externalroute" {
  route_table_id         = aws_route_table.fgtvmpublicrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fgtvmigw.id
}

# mark by Linda
# resource "aws_route" "externalroutetovpc1" {
#   depends_on             = [aws_vpc_endpoint.gwlbendpointfgt]
#   route_table_id         = aws_route_table.fgtvmpublicrt.id
#   destination_cidr_block = var.csvpccidr
#   vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpointfgt.id
# }

# mark by Linda
# resource "aws_route" "externalroutetovpc2" {
#   depends_on             = [aws_vpc_endpoint.gwlbendpointfgt2]
#   route_table_id         = aws_route_table.fgtvmpublicrt.id
#   destination_cidr_block = var.cs2vpccidr
#   vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpointfgt2.id
# }

// Comment this out for now
//resource "aws_route" "internalroute" {
//  depends_on             = [aws_instance.fgtvm]
//  route_table_id         = aws_route_table.fgtvmprivatert.id
//  destination_cidr_block = "0.0.0.0/0"
//  network_interface_id   = aws_network_interface.eth1.id
//}

resource "aws_route" "tgwyroute" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.fgtvmtgwrt.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpointfgt.id
}

resource "aws_route" "tgwyroute2" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.fgtvmtgwrt2.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpointfgt2.id
}

resource "aws_route" "gwlbroutecs" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.fgtvmgwlbrt.id
  destination_cidr_block = var.csvpccidr
  transit_gateway_id     = aws_ec2_transit_gateway.terraform-tgwy.id
}

resource "aws_route" "gwlbroutecs2" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.fgtvmgwlbrt.id
  destination_cidr_block = var.cs2vpccidr
  transit_gateway_id     = aws_ec2_transit_gateway.terraform-tgwy.id
}

// FGT Route Association
resource "aws_route_table_association" "fgttgwyassociateaz1" {
  subnet_id      = aws_subnet.transitsubnetaz1.id
  route_table_id = aws_route_table.fgtvmtgwrt.id
}

resource "aws_route_table_association" "fgttgwyassociateaz2" {
  subnet_id      = aws_subnet.transitsubnetaz2.id
  route_table_id = aws_route_table.fgtvmtgwrt2.id
}

resource "aws_route_table_association" "fgtgwlbassociateaz1" {
  subnet_id      = aws_subnet.gwlbsubnetaz1.id
  route_table_id = aws_route_table.fgtvmgwlbrt.id
}

resource "aws_route_table_association" "fgtgwlbassociateaz2" {
  subnet_id      = aws_subnet.gwlbsubnetaz2.id
  route_table_id = aws_route_table.fgtvmgwlbrt.id
}

resource "aws_route_table_association" "fgtpublicassociateaz1" {
  subnet_id      = aws_subnet.publicsubnetaz1.id
  route_table_id = aws_route_table.fgtvmpublicrt.id
}

resource "aws_route_table_association" "fgtpublicassociateaz2" {
  subnet_id      = aws_subnet.publicsubnetaz2.id
  route_table_id = aws_route_table.fgtvmpublicrt.id
}

resource "aws_route_table_association" "fgtprivateassociateaz1" {
  subnet_id      = aws_subnet.privatesubnetaz1.id
  route_table_id = aws_route_table.fgtvmprivatert.id
}

resource "aws_route_table_association" "fgtprivateassociateaz2" {
  subnet_id      = aws_subnet.privatesubnetaz2.id
  route_table_id = aws_route_table.fgtvmprivatert.id
}



//Spoke 1 VPC Route Table
resource "aws_route_table" "cspublicrt" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-gwlbe-ingress-rt"
  }
}

resource "aws_route_table" "cspublicrt2" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-gwlbe-egress-rt"
  }
}

resource "aws_route_table" "csprivatert" {
  count  = var.spokeVpc ? 1 : 0
  depends_on = [aws_vpc_endpoint.gwlbendpoint1_1]
  vpc_id     = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-app1-rt"
  }
}

resource "aws_route_table" "csprivatert2" {
  count  = var.spokeVpc ? 1 : 0
  depends_on = [aws_vpc_endpoint.gwlbendpoint1_2]
  vpc_id     = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-app2-rt"
  }
}

//Spoke 2 VPC Route Table
resource "aws_route_table" "cs2publicrt" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer2-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-gwlbe-ingress-rt"
  }
}

resource "aws_route_table" "cs2publicrt2" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer2-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-gwlbe-egress-rt"
  }
}

resource "aws_route_table" "cs2privatert" {
  count      = var.spokeVpc ? 1 : 0
  depends_on = [aws_vpc_endpoint.gwlbendpoint2_1]
  vpc_id     = aws_vpc.customer2-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-app1-rt"
  }
}

resource "aws_route_table" "cs2privatert2" {
  count      = var.spokeVpc ? 1 : 0
  depends_on = [aws_vpc_endpoint.gwlbendpoint2_2]
  vpc_id     = aws_vpc.customer2-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-app2-rt"
  }
}


# Spoke 1 VPC Route
resource "aws_route" "cspublicrouteaz1" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cspublicrt]
  route_table_id         = aws_route_table.cspublicrt[count.index].id
  destination_cidr_block = var.csprivatecidraz1
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint1_1[count.index].id
}

resource "aws_route" "cspublicrouteaz2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cspublicrt]
  route_table_id         = aws_route_table.cspublicrt[count.index].id
  destination_cidr_block = var.csprivatecidraz2
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint1_2[count.index].id
}

resource "aws_route" "csinternalroute" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.csprivatert]
  route_table_id         = aws_route_table.csprivatert[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint1_1[count.index].id
}

resource "aws_route" "csinternalroute2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.csprivatert2]
  route_table_id         = aws_route_table.csprivatert2[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint1_2[count.index].id
}

resource "aws_route" "csinternalroutetgwy" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.csprivatert]
  route_table_id         = aws_route_table.csprivatert[count.index].id
  destination_cidr_block = var.cs2vpccidr
  transit_gateway_id     = aws_ec2_transit_gateway.terraform-tgwy.id
}

resource "aws_route" "csinternalroutetgwy2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.csprivatert2]
  route_table_id         = aws_route_table.csprivatert2[count.index].id
  destination_cidr_block = var.cs2vpccidr
  transit_gateway_id     = aws_ec2_transit_gateway.terraform-tgwy.id
}

resource "aws_route" "csexternalroute" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cspublicrt2]
  route_table_id         = aws_route_table.cspublicrt2[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csigw[count.index].id
}

# Spoke 2 VPC Route
resource "aws_route" "cs2publicrouteaz1" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2publicrt]
  route_table_id         = aws_route_table.cs2publicrt[count.index].id
  destination_cidr_block = var.cs2privatecidraz1
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint2_1[count.index].id
}

resource "aws_route" "cs2publicrouteaz2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2publicrt]
  route_table_id         = aws_route_table.cs2publicrt[count.index].id
  destination_cidr_block = var.cs2privatecidraz2
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint2_2[count.index].id
}

resource "aws_route" "cs2internalroute" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2privatert]
  route_table_id         = aws_route_table.cs2privatert[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint2_1[count.index].id
}

resource "aws_route" "cs2internalroute2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2privatert]
  route_table_id         = aws_route_table.cs2privatert2[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint2_2[count.index].id
}

resource "aws_route" "cs2internalroutetgwy" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2privatert]
  route_table_id         = aws_route_table.cs2privatert[count.index].id
  destination_cidr_block = var.csvpccidr
  transit_gateway_id     = aws_ec2_transit_gateway.terraform-tgwy.id
}

resource "aws_route" "cs2internalroutetgwy2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2privatert]
  route_table_id         = aws_route_table.cs2privatert2[count.index].id
  destination_cidr_block = var.csvpccidr
  transit_gateway_id     = aws_ec2_transit_gateway.terraform-tgwy.id
}

resource "aws_route" "cs2externalroute" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cs2publicrt2]
  route_table_id         = aws_route_table.cs2publicrt2[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cs2igw[count.index].id
}

# Spoke 1 Route association
resource "aws_route_table_association" "cspublicassociate" {
  count          = var.spokeVpc ? 1 : 0
  route_table_id = aws_route_table.cspublicrt[count.index].id
  gateway_id     = aws_internet_gateway.csigw[count.index].id
}

resource "aws_route_table_association" "csinternalassociateaz1" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.csprivatesubnetaz1[count.index].id
  route_table_id = aws_route_table.csprivatert[count.index].id
}

resource "aws_route_table_association" "csinternalassociateaz2" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.csprivatesubnetaz2[count.index].id
  route_table_id = aws_route_table.csprivatert2[count.index].id
}

resource "aws_route_table_association" "csexternalassociateaz1" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.cspublicsubnetaz1[count.index].id
  route_table_id = aws_route_table.cspublicrt2[count.index].id
}

resource "aws_route_table_association" "csexternalassociateaz2" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.cspublicsubnetaz2[count.index].id
  route_table_id = aws_route_table.cspublicrt2[count.index].id
}

# Spoke 2 Route association
resource "aws_route_table_association" "cs2publicassociate" {
  count          = var.spokeVpc ? 1 : 0
  route_table_id = aws_route_table.cs2publicrt[count.index].id
  gateway_id     = aws_internet_gateway.cs2igw[count.index].id
}

resource "aws_route_table_association" "cs2internalassociateaz1" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.cs2privatesubnetaz1[count.index].id
  route_table_id = aws_route_table.cs2privatert[count.index].id
}

resource "aws_route_table_association" "cs2internalassociateaz2" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.cs2privatesubnetaz2[count.index].id
  route_table_id = aws_route_table.cs2privatert2[count.index].id
}

resource "aws_route_table_association" "cs2externalassociateaz1" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.cs2publicsubnetaz1[count.index].id
  route_table_id = aws_route_table.cs2publicrt2[count.index].id
}

resource "aws_route_table_association" "cs2externalassociateaz2" {
  count          = var.spokeVpc ? 1 : 0
  subnet_id      = aws_subnet.cs2publicsubnetaz2[count.index].id
  route_table_id = aws_route_table.cs2publicrt2[count.index].id
}


resource "aws_eip" "FGTPublicIP" {
  depends_on        = [aws_instance.fgtvm]
  domain            = "vpc"
  network_interface = aws_network_interface.eth0.id

  tags = {
    Name = "${var.tag_name_prefix}-fgt1"
  }
}

resource "aws_eip" "FGT2PublicIP" {
  depends_on        = [aws_instance.fgtvm2]
  domain            = "vpc"
  network_interface = aws_network_interface.fgt2eth0.id

  tags = {
    Name = "${var.tag_name_prefix}-fgt2"
  }
}


// Security Group

resource "aws_security_group" "public_allow" {
  name        = "${var.tag_name_prefix}-Sec - Public Allow"
  description = "Public Allow traffic"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_name_prefix}-Sec - Public Allow"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "${var.tag_name_prefix}-Sec - Allow All"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_name_prefix}-Sec - Allow All"
  }
}

//  Gateway Load Balancer on FGT VPC to single FGT
resource "aws_lb" "gateway_lb" {
  name                             = "${var.tag_name_prefix}"
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true

  // AZ1
  subnet_mapping {
    subnet_id = aws_subnet.privatesubnetaz1.id
  }

  // AZ2
  subnet_mapping {
    subnet_id = aws_subnet.privatesubnetaz2.id
  }
}

resource "aws_lb_target_group" "fgt_target" {
  name        = "${var.tag_name_prefix}-fgttarget"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = aws_vpc.fgtvm-vpc.id

  health_check {
    port     = 8008
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "fgt_listener" {
  load_balancer_arn = aws_lb.gateway_lb.id

  default_action {
    target_group_arn = aws_lb_target_group.fgt_target.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "fgtattach" {
  depends_on       = [aws_instance.fgtvm]
  target_group_arn = aws_lb_target_group.fgt_target.arn
  target_id        = data.aws_network_interface.eth1.private_ip
  port             = 6081
}

resource "aws_lb_target_group_attachment" "fgt2attach" {
  depends_on       = [aws_instance.fgtvm2]
  target_group_arn = aws_lb_target_group.fgt_target.arn
  target_id        = data.aws_network_interface.fgt2eth1.private_ip
  port             = 6081
}


resource "aws_vpc_endpoint_service" "fgtgwlbservice" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gateway_lb.arn]
  tags = {
    Name = "${var.tag_name_prefix}"
  }
}

# FGT Endpoint
resource "aws_vpc_endpoint" "gwlbendpointfgt" {
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.gwlbsubnetaz1.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "${var.tag_name_prefix}-Sec-az1"
  }
}
resource "aws_vpc_endpoint" "gwlbendpointfgt2" {
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.gwlbsubnetaz2.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "${var.tag_name_prefix}-Sec-az2"
  }
}

# Spoke 1 Endpoint
resource "aws_vpc_endpoint" "gwlbendpoint1_1" {
  count          = var.spokeVpc ? 1 : 0
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.cspublicsubnetaz1[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-az1"
  }
}

resource "aws_vpc_endpoint" "gwlbendpoint1_2" {
  count          = var.spokeVpc ? 1 : 0
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.cspublicsubnetaz2[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke1-az2"
  }
}

# Spoke 2 Endpoint
resource "aws_vpc_endpoint" "gwlbendpoint2_1" {
  count             = var.spokeVpc ? 1 : 0
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.cs2publicsubnetaz1[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.customer2-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-az1"
  }
}

resource "aws_vpc_endpoint" "gwlbendpoint2_2" {
  count             = var.spokeVpc ? 1 : 0
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.cs2publicsubnetaz2[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.customer2-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke2-az2"
  }
}
