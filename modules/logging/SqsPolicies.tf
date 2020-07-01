data "template_file" "sqs_kms_encrypt_policy" {
  template = file("${path.module}/SqsPolicies.json")

  vars = {
    some_account_id: data.aws_caller_identity.current.account_id
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "thing" {
  assume_role_policy = data.aws_iam_policy_document.thing-assume-policy.json
}



data "aws_iam_policy_document" "thing-assume-policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "sqs.amazonaws.com"]
      type = "Service"
    }
  }
}

