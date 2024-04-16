data "aws_region" "current" {}

data "aws_caller_identity" "audit" {
  provider = aws.audit
}

#data "aws_iam_policy_document" "gitlab_secret_access" {
#  statement {
#    sid = "AllowGitlabTokenSecret"
#    actions = [
#      "secretsmanager:GetSecretValue",
#      "secretsmanager:DescribeSecret",
#    ]
#    effect = "Allow"
#    resources = [
#      aws_secretsmanager_secret.gitlab_token_secret.arn
#    ]
#  }
#}

data "aws_iam_policy_document" "lambda_kms_access" {
  statement {
    sid = "LambdaKMSAccess"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncryptTo",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyPair",
      "kms:ReEncryptFrom"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "lambda_to_s3" {
  statement {
    sid     = "LambdaUploadToS3"
    actions = ["s3:PutObject"]
    resources = [
      "${module.audit_logs_archive_bucket.arn}/gitlab_groups_audit_log/*",
      "${module.audit_logs_archive_bucket.arn}/gitlab_projects_audit_log/*",
      "${module.audit_logs_archive_bucket.arn}/terraform_logs/*",
      "${module.audit_logs_archive_bucket.arn}/okta_logs/*"
    ]
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "log_group_audit_logs" {
  statement {
    sid = "TrustEventsToStoreLogEvent"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${local.account_id}:*"
    ]
  }
}

data "aws_iam_policy_document" "terraform_lambda_to_sqs" {
  statement {
    sid = "TerraformLambdaToFromSQS"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:SendMessageBatch",
      "sqs:SetQueueAttributes"
    ]
    effect = "Allow"
    resources = [
      aws_sqs_queue.terraform_audit_log_queue.arn
    ]
  }
}

data "aws_iam_policy_document" "terraform_secret_access" {
  statement {
    sid = "AllowTerraformTokenSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.terraform_token_secret.arn
    ]
  }
}

data "aws_iam_policy_document" "okta_secret_access" {
  statement {
    sid = "AllowGitlabTokenSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    effect = "Allow"
    resources = [
      aws_secretsmanager_secret.okta_token_secret.arn
    ]
  }
}
