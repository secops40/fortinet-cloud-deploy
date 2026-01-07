// FGTVM instance

resource "aws_network_interface" "eth0" {
  description = "${var.tag_name_prefix}-Fortigate - port1"
  subnet_id   = aws_subnet.publicsubnetaz1.id
  private_ips = [cidrhost(var.publiccidraz1, 10)]
  tags = {
    Name = "${var.tag_name_prefix}-Fortigate - port1"
  }
}

resource "aws_network_interface" "eth1" {
  description       = "${var.tag_name_prefix}-Fortigate -port2"
  subnet_id         = aws_subnet.privatesubnetaz1.id
  private_ips       = [cidrhost(var.privatecidraz1, 10)]
  source_dest_check = false
  tags = {
    Name = "${var.tag_name_prefix}-Fortigate - port2"
  }
}


resource "aws_network_interface_sg_attachment" "publicattachment" {
  depends_on           = [aws_network_interface.eth0]
  security_group_id    = aws_security_group.public_allow.id
  network_interface_id = aws_network_interface.eth0.id
}

resource "aws_network_interface_sg_attachment" "internalattachment" {
  depends_on           = [aws_network_interface.eth1]
  security_group_id    = aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.eth1.id
}

# Cloudinit config in MIME format
data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  # Main cloud-config configuration file.
  part {
    filename     = "config"
    content_type = "text/x-shellscript"
    content = templatefile("${var.bootstrap-fgtvm}", {
      adminsport     = var.adminsport
      fgt_public_ip  = join("/", [element(tolist(aws_network_interface.eth0.private_ips), 0), cidrnetmask("${var.publiccidraz1}")])
      fgt_private_ip = join("/", [element(tolist(aws_network_interface.eth1.private_ips), 0), cidrnetmask("${var.privatecidraz1}")])
      dst            = var.vpccidr
      private_gw     = cidrhost(var.privatecidraz1, 1)
      public_gw      = cidrhost(var.publiccidraz1, 1)
      hostname       = "${var.tag_name_prefix}-Fortigate"
    })
  }

  part {
    filename     = "license"
    content_type = "text/plain"
    content      = var.license_format == "token" ? "LICENSE-TOKEN:${chomp(file("${var.license}"))} INTERVAL:4 COUNT:4" : "${file("${var.license}")}"
  }
}

resource "aws_instance" "fgtvm" {
  //it will use region, architect, and license type to decide which ami to use for deployment
  //ami               = data.aws_ami.fgt_ami.id
  ami               = local.ami_id
  instance_type     = var.instance_type
  availability_zone = var.availability_zone1
  key_name          = var.keypair

  user_data = var.bucket ? (var.license_format == "file" ? "${jsonencode({ bucket = aws_s3_bucket.s3_bucket[0].id,
    region                        = var.region,
    license                       = var.license,
    config                        = "${var.bootstrap-fgtvm}"
    })}" : "${jsonencode({ bucket = aws_s3_bucket.s3_bucket[0].id,
    region                        = var.region,
    license-token                 = file("${var.license}"),
    config                        = "${var.bootstrap-fgtvm}"
  })}") : "${data.cloudinit_config.config.rendered}"

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
    network_interface_id = aws_network_interface.eth0.id
  }

  tags = {
    Name = "${var.tag_name_prefix}-Fortigate"
  }
}

resource "aws_network_interface_attachment" "eth1-attach" {
  instance_id          = aws_instance.fgtvm.id
  network_interface_id = aws_network_interface.eth1.id
  device_index         = 1
}

