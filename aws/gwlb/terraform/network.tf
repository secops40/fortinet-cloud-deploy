// Creating Internet Gateway
resource "aws_internet_gateway" "fgtvmigw" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = "${var.tag_name_prefix}-Sec-igw"
  }
}

resource "aws_internet_gateway" "csigw" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-Spoke-igw"
  }
}

// Route Table
resource "aws_route_table" "fgtvmpublicrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-Mgmt-rt"
  }
}


resource "aws_route_table" "fgtvmprivatert" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = "${var.tag_name_prefix}-Sec-GWLB-rt"
  }
}

resource "aws_route_table" "cspublicrt" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke-Public-ingress-rt"
  }
}

resource "aws_route_table" "cspublicrt2" {
  count  = var.spokeVpc ? 1 : 0
  vpc_id = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke-Public-egress-rt"
  }
}

resource "aws_route_table" "csprivatert" {
  count      = var.spokeVpc ? 1 : 0
  depends_on = [aws_vpc_endpoint.gwlbendpoint]
  vpc_id     = aws_vpc.customer-vpc[count.index].id

  tags = {
    Name = "${var.tag_name_prefix}-Spoke-Service-rt"
  }
}

resource "aws_route" "externalroute" {
  route_table_id         = aws_route_table.fgtvmpublicrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fgtvmigw.id
}

resource "aws_route" "internalroute" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.fgtvmprivatert.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.eth1.id

}

resource "aws_route" "cspublicrouteaz1" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cspublicrt]
  route_table_id         = aws_route_table.cspublicrt[count.index].id
  destination_cidr_block = var.csprivatecidraz1
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint[count.index].id
}

resource "aws_route" "cspublicrouteaz2" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cspublicrt]
  route_table_id         = aws_route_table.cspublicrt[count.index].id
  destination_cidr_block = var.csprivatecidraz2
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint[count.index].id
}

resource "aws_route" "csinternalroute" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.csprivatert]
  route_table_id         = aws_route_table.csprivatert[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbendpoint[count.index].id
}

resource "aws_route" "csexternalroute" {
  count                  = var.spokeVpc ? 1 : 0
  depends_on             = [aws_route_table.cspublicrt2]
  route_table_id         = aws_route_table.cspublicrt2[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csigw[count.index].id
}

resource "aws_route_table_association" "public1associate" {
  subnet_id      = aws_subnet.publicsubnetaz1.id
  route_table_id = aws_route_table.fgtvmpublicrt.id
}

resource "aws_route_table_association" "internalassociate" {
  subnet_id      = aws_subnet.privatesubnetaz1.id
  route_table_id = aws_route_table.fgtvmprivatert.id
}

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
  route_table_id = aws_route_table.csprivatert[count.index].id
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

resource "aws_eip" "FGTPublicIP" {
  depends_on        = [aws_instance.fgtvm]
  domain            = "vpc"
  network_interface = aws_network_interface.eth0.id
  tags = {
    Name = "${var.tag_name_prefix}-FortiGate - Port1"
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
  name               = "${var.tag_name_prefix}-gwlb"
  load_balancer_type = "gateway"

  subnet_mapping {
    subnet_id = aws_subnet.privatesubnetaz1.id
  }
}

resource "aws_lb_target_group" "fgt_target" {
  name        = "${var.tag_name_prefix}-fgt-target"
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


resource "aws_vpc_endpoint_service" "fgtgwlbservice" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gateway_lb.arn]
  tags = {
    Name = "${var.tag_name_prefix}-gwlb"
  }
}


resource "aws_vpc_endpoint" "gwlbendpoint" {
  count             = var.spokeVpc ? 1 : 0
  service_name      = aws_vpc_endpoint_service.fgtgwlbservice.service_name
  subnet_ids        = [aws_subnet.cspublicsubnetaz1[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.fgtgwlbservice.service_type
  vpc_id            = aws_vpc.customer-vpc[count.index].id
  tags = {
    Name = "${var.tag_name_prefix}-gwlb-Spoke-az1"
  }
}
