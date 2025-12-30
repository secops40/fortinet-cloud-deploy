# Create an IAM Role to assign to the FortiGate VM instance
#
resource "aws_iam_role" "fortigate" {
  count = var.bucket ? 1 : 0
  name  = "FGT-${var.tag_name_prefix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Sid = ""
      }
    ]
  })
}

# IAM Policy for FortiGate to access the S3 Buckets
#
resource "aws_iam_role_policy" "fortigate-iam_role_policy" {
  count  = var.bucket ? 1 : 0
  name   = "FGT-${var.tag_name_prefix}-policy"
  role   = aws_iam_role.fortigate[0].id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.s3_bucket[0].id}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.s3_bucket[0].id}/*"]
    }
  ]
}
EOF
}

# Assign the IAM Profile to the FortiGate instance
#
resource "aws_iam_instance_profile" "fortigate" {
  count = var.bucket ? 1 : 0
  name  = "FGT-${var.tag_name_prefix}-profile"

  role = aws_iam_role.fortigate[0].name
}

# Create S3 bucket
#
resource "aws_s3_bucket" "s3_bucket" {
  count  = var.bucket ? 1 : 0
  bucket = "${var.tag_name_prefix}-fgt-boot"
}

# S3 Bucket license file for BYOL License
#
resource "aws_s3_object" "lic1" {
  count  = var.bucket ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  key    = var.licenses[0]
  source = var.licenses[0]
  etag   = filemd5(var.licenses[0])
}

# S3 Bucket license file for BYOL License
#
resource "aws_s3_object" "lic2" {
  count  = var.bucket ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  key    = var.licenses[1]
  source = var.licenses[1]
  etag   = filemd5(var.licenses[1])
}

# S3 Bucket config file for storing fgtvm config
#
resource "aws_s3_object" "conf" {
  count  = var.bucket ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  key    = var.bootstrap-fgtvm
  content = templatefile("${var.bootstrap-fgtvm}", {
    adminsport  = "${var.adminsport}"
    dst         = var.vpccidr
    data_gw     = cidrhost(var.privatecidraz1, 1)
    mgmt_gw     = cidrhost(var.publiccidraz1, 1)
    fgt_mgmt_ip = join("/", [element(tolist(aws_network_interface.eth0.private_ips), 0), cidrnetmask("${var.publiccidraz1}")])
    fgt_data_ip = join("/", [element(tolist(aws_network_interface.eth1.private_ips), 0), cidrnetmask("${var.privatecidraz1}")])
    endpointip  = "${data.aws_network_interface.vpcendpointip.private_ip}"
    endpointip2 = "${data.aws_network_interface.vpcendpointip2.private_ip}"
    hostname    = "${var.tag_name_prefix}-fgt1"
  })
}

#
# S3 Bucket config file for storing fgtvm2 config
#
resource "aws_s3_object" "conf2" {
  count  = var.bucket ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  key    = "${var.bootstrap-fgtvm}"
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

