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