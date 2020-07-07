// TODO: see if we can find a way to write a test for this
// With retries
data "aws_caller_identity" "current" {}

locals {
  s3_bucket_log_prefix = "cloudtrail_logs"
}

// TODO: encrypt this
// TODO: is there a limit/cost implication to KMS keys
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name = "${var.prefix}-cloudtrail-log-group"

  tags = var.tags
}

resource "aws_cloudtrail" "pttp_cloudtrail" {
  name                          = "${var.prefix}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix                 = local.s3_bucket_log_prefix
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail_log_group.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
  include_global_service_events = true
  is_multi_region_trail         = true

  tags = var.tags
}
resource "aws_kms_key" "cloudtrail_s3_bucket_key" {
  description             = "${var.prefix}-cloudtrail-s3-bucket-key"
  deletion_window_in_days = 10

  tags = var.tags
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  // TODO: turn this value into a local variable
  bucket        = "${var.prefix}-cloudtrail-bucket"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.cloudtrail_s3_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = var.tags

  // TODO: put this policy into its own file
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.prefix}-cloudtrail-bucket"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.prefix}-cloudtrail-bucket/${local.s3_bucket_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}
