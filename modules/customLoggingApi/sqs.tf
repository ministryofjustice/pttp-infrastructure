resource "aws_sqs_queue" "custom_log_queue" {
  name = "${var.prefix}-custom-log-queue"

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}
