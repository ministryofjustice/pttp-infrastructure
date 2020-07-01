resource "aws_iam_policy" "api-gateway-sqs-send-msg-policy" {
  policy = data.template_file.gateway_policy.rendered
}

data "template_file" "gateway_policy" {
  template = file("${path.module}/ApiGatewayPolicies.json")

  vars = {
    sqs_arn   = aws_sqs_queue.custom_log_queue.arn
  }
}

