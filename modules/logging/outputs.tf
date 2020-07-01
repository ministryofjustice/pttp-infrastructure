//resource "local_file" "ec2_private_key" {
//  filename          = "ec2.pem"
//  file_permission   = "0600"
//  sensitive_content = tls_private_key.ec2.private_key_pem
//}

output "logging_endpoint_path" {
  value = "${aws_api_gateway_deployment.custom_log_api_deployment.invoke_url}/${aws_api_gateway_resource.proxy.path_part}"
}

output "custom_log_queue_url" {
  value = aws_sqs_queue.custom_log_queue.id
}

// TODO: Should this be stored as a secret somewhere?
output "custom_logging_api_key" {
  value = aws_api_gateway_api_key.custom_log_api_key.value
}

output "foo" {
  value = data.template_file.sqs_kms_encrypt_policy.rendered
}