// FGTVM instance AZ2

resource "aws_network_interface" "fgt2eth0" {
  description = "${var.tag_name_prefix}-fgt2 port1"
  subnet_id   = aws_subnet.publicsubnetaz2.id
  private_ips = [cidrhost(var.publiccidraz2, 10)]
  tags = {
    Name = "${var.tag_name_prefix}-fgt2 port1"
  }
}

resource "aws_network_interface" "fgt2eth1" {
  description       = "${var.tag_name_prefix}-fgt2 port2"
  subnet_id         = aws_subnet.privatesubnetaz2.id
  private_ips       = [cidrhost(var.privatecidraz2, 10)]
  source_dest_check = false
  tags = {
    Name = "${var.tag_name_prefix}-fgt2 port2"
  }
}

data "aws_network_interface" "fgt2eth1" {
  id = aws_network_interface.fgt2eth1.id
}

resource "aws_network_interface_sg_attachment" "fgt2publicattachment" {
  depends_on           = [aws_network_interface.fgt2eth0]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.fgt2eth0.id
}

resource "aws_network_interface_sg_attachment" "fgt2internalattachment" {
  depends_on           = [aws_network_interface.fgt2eth1]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.fgt2eth1.id
}

# Cloudinit config in MIME format
data "cloudinit_config" "config2" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "license"
    content_type = "text/plain"
    content      = var.license_format == "token" ? "LICENSE-TOKEN:${chomp(file("${var.licenses[1]}"))}" : "${file("${var.licenses[1]}")}"
  }

  # Main cloud-config configuration file.
  part {
    filename     = "config"
    content_type = "text/x-shellscript"
    content = templatefile("${var.bootstrap-fgtvm}", {
      adminsport  = "${var.adminsport}"
      dst         = var.vpccidr
      data_gw     = cidrhost(var.privatecidraz2, 1)
      mgmt_gw     = cidrhost(var.publiccidraz2, 1)
      fgt_mgmt_ip = join("/", [element(tolist(aws_network_interface.fgt2eth0.private_ips), 0), cidrnetmask("${var.publiccidraz2}")])
      fgt_data_ip = join("/", [element(tolist(aws_network_interface.fgt2eth1.private_ips), 0), cidrnetmask("${var.privatecidraz2}")])
      endpointip  = "${data.aws_network_interface.vpcendpointip.private_ip}"
      endpointip2 = "${data.aws_network_interface.vpcendpointip2.private_ip}"
      hostname    = "${var.tag_name_prefix}-fgt2"
    })
  }
}

resource "aws_instance" "fgtvm2" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  ami               = data.aws_ami.fgt_ami.id
  instance_type     = var.instance_type
  availability_zone = var.availability_zone2
  key_name          = var.keypair

  user_data = var.bucket ? (var.license_format == "file" ? "${jsonencode({ bucket = aws_s3_bucket.s3_bucket[0].id,
    region                        = var.region,
    license                       = var.licenses[1],
    config                        = "${var.bootstrap-fgtvm}2"
    })}" : "${jsonencode({ bucket = aws_s3_bucket.s3_bucket[0].id,
    region                        = var.region,
    license-token                 = file("${var.licenses[1]}"),
    config                        = "${var.bootstrap-fgtvm}2"
  })}") : "${data.cloudinit_config.config2.rendered}"

  iam_instance_profile = var.bucket ? aws_iam_instance_profile.fortigate[0].id : ""

  root_block_device {
    volume_type = "gp3"
    volume_size = "2"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "30"
    volume_type = "gp3"
  }

  primary_network_interface {
    network_interface_id = aws_network_interface.fgt2eth0.id
  }

  tags = {
    Name = "${var.tag_name_prefix}-fgt2"
  }
}

resource "aws_network_interface_attachment" "fgt2eth1-attach" {
  instance_id          = aws_instance.fgtvm2.id
  network_interface_id = aws_network_interface.fgt2eth1.id
  device_index         = 1
}
