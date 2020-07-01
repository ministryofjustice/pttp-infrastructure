resource "aws_sqs_queue" "custom_log_queue" {
  name = "CustomLogQueue"

  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}


//resource "aws_kms_key" "asdf" {
//  description             = "KMS key 1"
//  deletion_window_in_days = 10
//  policy = data.template_file.sqs_kms_encrypt_policy.rendered
//
//  depends_on = [
//    aws_iam_role.thing
//  ]
//}
