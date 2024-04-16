resource "aws_cloudwatch_event_rule" "audit_trigger_daily" {
  provider            = aws.audit
  name                = "audit-trigger-daily"
  description         = "Triggers audit lambdas daily."
  schedule_expression = "cron(0 9 ? * * *)"
}

# resource "aws_cloudwatch_event_target" "gitlab_audit_trigger_daily" {
#   provider  = aws.audit
#   arn       = module.gitlab_audit_logs_lambda.arn
#   rule      = aws_cloudwatch_event_rule.audit_trigger_daily.name
#   target_id = "gitlab_audit_logs_lambda"
# 
#   retry_policy {
#     maximum_retry_attempts       = 3
#     maximum_event_age_in_seconds = 60
#   }
# }

resource "aws_cloudwatch_event_target" "terraform_audit_trigger_daily" {
  provider  = aws.audit
  arn       = module.terraform_cloud_audit_logs_lambda.arn
  rule      = aws_cloudwatch_event_rule.audit_trigger_daily.name
  target_id = "terraform_cloud_audit_logs_lambda"

  dead_letter_config {
    arn = aws_sqs_queue.terraform_audit_log_dlq.arn
  }

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 60
  }
}

resource "aws_cloudwatch_event_target" "okta_audit_trigger_daily" {
  provider  = aws.audit
  arn       = module.okta_audit_logs_lambda.arn
  rule      = aws_cloudwatch_event_rule.audit_trigger_daily.name
  target_id = "okta_audit_logs_lambda"

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 60
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_audit_lambda" {
  for_each      = local.audit_lambdas
  provider      = aws.audit
  statement_id  = "Allow${each.value}AuditLambdaExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = local.audit_lambda_names[each.key]
  #function_name = module.terraform_cloud_audit_logs_lambda.name
  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.audit_trigger_daily.arn
}
