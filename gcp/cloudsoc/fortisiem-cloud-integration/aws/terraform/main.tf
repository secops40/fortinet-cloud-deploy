# Trail with FortiSIEM through Amazon SQS, with optional expanded permissions. Maintained by Linda.

variable "prefix" {
  type        = string
  description = "Resource naming prefix (Required, cannot be empty)"

  validation {
    condition     = length(var.prefix) > 0
    error_message = "The prefix value cannot be empty."
  }
}

variable "region" {
  type    = string
  default = "ap-east-2"
}

variable "enable_kms" {
  type        = bool
  description = "Enable custom KMS Key encryption for S3? (Does not apply to SNS/SQS)"
  default     = false
}

variable "log_retention_days" {
  type        = number
  description = "S3 log retention days. 0 means no lifecycle deletion rule."
  default     = 0
}

variable "expand_user_permission" {
  type        = bool
  description = "Allow FortiSIEM global read permissions for other resource integrations"
  default     = false
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# --- KMS Key ---
resource "aws_kms_key" "fs_kms" {
  count               = var.enable_kms ? 1 : 0
  description         = "KMS Key for CloudTrail"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudTrail to encrypt logs"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringLike = { "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/${var.prefix}-cloudtrail" }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "fs_kms_alias" {
  count         = var.enable_kms ? 1 : 0
  name          = "alias/${var.prefix}-cloudtrail"
  target_key_id = aws_kms_key.fs_kms[0].key_id
}

# --- S3 Bucket ---
resource "aws_s3_bucket" "ct_bucket" {
  bucket        = "${var.prefix}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ct_bucket_pab" {
  bucket                  = aws_s3_bucket.ct_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ct_bucket_sse" {
  count  = var.enable_kms ? 1 : 0
  bucket = aws_s3_bucket.ct_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.fs_kms[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ct_bucket_lifecycle" {
  count  = var.log_retention_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.ct_bucket.id
  rule {
    id     = "auto-delete-logs"
    status = "Enabled"
    expiration {
      days = var.log_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "ct_bucket_policy" {
  bucket = aws_s3_bucket.ct_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.ct_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.ct_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

# --- SNS Topic ---
resource "aws_sns_topic" "ct_sns" {
  name = "${var.prefix}-cloudtrail-sns"
}

resource "aws_sns_topic_policy" "ct_sns_policy" {
  arn = aws_sns_topic.ct_sns.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.ct_sns.arn
    }]
  })
}

# --- SQS Queue ---
resource "aws_sqs_queue" "ct_sqs" {
  name                      = "${var.prefix}-cloudtrail-sqs"
  message_retention_seconds = 604800 
}

resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn = aws_sns_topic.ct_sns.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ct_sqs.arn
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.ct_sqs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.ct_sqs.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.ct_sns.arn } }
    }]
  })
}

# --- CloudTrail ---
resource "aws_cloudtrail" "trail" {
  name                          = "${var.prefix}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.ct_bucket.id
  sns_topic_name                = aws_sns_topic.ct_sns.name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true 
  kms_key_id                    = var.enable_kms ? aws_kms_key.fs_kms[0].arn : null

  depends_on = [
    aws_s3_bucket_policy.ct_bucket_policy,
    aws_sns_topic_policy.ct_sns_policy
  ]
}

# --- IAM User ---
resource "aws_iam_user" "fsiem_user" {
  name = "${var.prefix}-user"
}

resource "aws_iam_access_key" "fsiem_key" {
  user = aws_iam_user.fsiem_user.name
}

locals {
  fsiem_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]
}

resource "aws_iam_user_policy_attachment" "fsiem_managed_attach" {
  count      = var.expand_user_permission ? length(local.fsiem_managed_policies) : 0
  user       = aws_iam_user.fsiem_user.name
  policy_arn = local.fsiem_managed_policies[count.index]
}

data "aws_iam_policy_document" "fsiem_policy_doc" {
  # --- Core Policy ---
  statement {
    sid       = "SQSPermissions"
    effect    = "Allow"
    actions   = [
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [aws_sqs_queue.ct_sqs.arn]
  }
  statement {
    sid       = "S3BucketPermissions"
    effect    = "Allow"
    actions   = ["s3:Get*", "s3:List*"]
    resources = [aws_s3_bucket.ct_bucket.arn]
  }
  statement {
    sid       = "S3BucketObjectPermissions"
    effect    = "Allow"
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["${aws_s3_bucket.ct_bucket.arn}/*"]
  }
  
  dynamic "statement" {
    for_each = var.enable_kms ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [aws_kms_key.fs_kms[0].arn]
    }
  }

  # --- Extended Policy ---
  dynamic "statement" {
    for_each = var.expand_user_permission ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "sqs:List*",
        "sqs:Get*",
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage",
        "sqs:PurgeQueue"
      ]
      resources = ["*"]
    }
  }
  dynamic "statement" {
    for_each = var.expand_user_permission ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["s3:Get*", "s3:List*"]
      resources = ["*"]
    }
  }
  dynamic "statement" {
    for_each = var.expand_user_permission ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_user_policy" "fsiem_policy" {
  name   = "${var.prefix}-fortisiem-policy"
  user   = aws_iam_user.fsiem_user.name
  policy = data.aws_iam_policy_document.fsiem_policy_doc.json
}

# --- Outputs ---
output "fortisiem_iam_user_name" {
  value       = aws_iam_user.fsiem_user.name
  description = "FortiSIEM: IAM User Name"
}
output "fortisiem_aws_access_key" {
  value       = aws_iam_access_key.fsiem_key.id
  description = "FortiSIEM Credentials: Access Key"
}
output "fortisiem_aws_secret_key" {
  value       = aws_iam_access_key.fsiem_key.secret
  description = "FortiSIEM Credentials: Secret Key"
  sensitive   = true
}
output "fortisiem_s3_bucket_region" {
  value       = var.region
  description = "FortiSIEM: SQS Region Name"
}
output "fortisiem_s3_bucket" {
  value       = aws_s3_bucket.ct_bucket.id
  description = "FortiSIEM: S3 Bucket Name"
}
output "fortisiem_sqs_queue_url" {
  value       = aws_sqs_queue.ct_sqs.url
  description = "FortiSIEM: SQS Queue URL"
}

