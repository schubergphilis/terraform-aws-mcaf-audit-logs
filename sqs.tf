resource "aws_lambda_event_source_mapping" "terraform_audit_sqs_trigger" {
  provider         = aws.audit
  batch_size       = 1
  event_source_arn = aws_sqs_queue.terraform_audit_log_queue.arn
  function_name    = module.terraform_cloud_audit_logs_lambda.arn
}

resource "aws_sqs_queue" "terraform_audit_log_dlq" {
  provider                  = aws.audit
  name                      = "terraform-audit-log-dlq"
  kms_master_key_id         = var.kms_key_arn
  message_retention_seconds = 691200
}

resource "aws_sqs_queue" "terraform_audit_log_queue" {
  provider                   = aws.audit
  name                       = "terraform-audit-log-queue"
  delay_seconds              = 90
  kms_master_key_id          = var.kms_key_arn
  max_message_size           = 2048
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 1200

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_audit_log_dlq.arn
    maxReceiveCount     = 4
  })
}
