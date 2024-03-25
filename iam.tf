#resource "aws_iam_policy" "gitlab_secret_access" {
#  provider    = aws.audit
#  name        = "PolicyAllowGitlabTokenSecret"
#  description = "Policy allowing lambda to read token from secrets"
#  path        = "/"
#  policy      = data.aws_iam_policy_document.gitlab_secret_access.json
#}
#
#resource "aws_iam_policy" "okta_secret_access" {
#  provider    = aws.audit
#  name        = "PolicyAllowOktaTokenSecret"
#  description = "Policy allowing lambda to read token from secrets"
#  path        = "/"
#  policy      = data.aws_iam_policy_document.okta_secret_access.json
#}
#
resource "aws_iam_policy" "lambda_cloudwatch_group" {
  provider    = aws.audit
  name        = "PolicyLambdaCloudWatchLogGroup"
  description = "Policy allowing lambda to store logs to CloudWatch log group"
  path        = "/"
  policy      = data.aws_iam_policy_document.log_group_audit_logs.json
}

resource "aws_iam_policy" "lambda_kms_access" {
  provider    = aws.audit
  name        = "PolicyLambdaKMSAccess"
  description = "Policy allowing lambda to encrypt/decrypt messages using KMS"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_kms_access.json
}

resource "aws_iam_policy" "lambda_put_s3_bucket" {
  provider    = aws.audit
  name        = "PolicyLambdaPutToS3"
  description = "Policy allowing lambda to put logs into S3 bucket"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_to_s3.json
}

resource "aws_iam_policy" "terraform_lambda_to_sqs" {
  provider    = aws.audit
  name        = "PolicyTerraformLambdaToFromSQS"
  description = "Policy allowing lambda to read/send messages to/from sqs"
  path        = "/"
  policy      = data.aws_iam_policy_document.terraform_lambda_to_sqs.json
}

resource "aws_iam_policy" "terraform_secret_access" {
  provider    = aws.audit
  name        = "PolicyAllowTerraformTokenSecret"
  description = "Policy allowing lambda to read token from secrets"
  path        = "/"
  policy      = data.aws_iam_policy_document.terraform_secret_access.json
}

#resource "aws_iam_role" "role_lambda_audit_logs" {
#  for_each = local.audit_lambdas
#  provider = aws.audit
#  name     = "Role${each.value}AuditLogsLambda"
#
#  assume_role_policy = jsonencode(
#    {
#      "Version" : "2012-10-17",
#      "Statement" : [{
#        "Action" : "sts:AssumeRole",
#        "Principal" : {
#          "Service" : "lambda.amazonaws.com"
#        },
#        "Effect" : "Allow"
#      }]
#    }
#  )
#}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_group" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.lambda_cloudwatch_group.arn
  role       = module.terraform_cloud_audit_logs_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_kms_access" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.lambda_kms_access.arn
  role       = module.terraform_cloud_audit_logs_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_put_s3_bucket" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.lambda_put_s3_bucket.arn
  role       = module.terraform_cloud_audit_logs_lambda.name
}

# resource "aws_iam_role_policy_attachment" "gitlab_secret_access" {
#   provider   = aws.audit
#   policy_arn = aws_iam_policy.gitlab_secret_access.arn
#   role       = aws_iam_role.role_lambda_audit_logs["gitlab"].name
# }
# 
# resource "aws_iam_role_policy_attachment" "okta_secret_access" {
#   provider   = aws.audit
#   policy_arn = aws_iam_policy.okta_secret_access.arn
#   role       = aws_iam_role.role_lambda_audit_logs["okta"].name
# }

resource "aws_iam_role_policy_attachment" "terraform_lambda_to_sqs" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.terraform_lambda_to_sqs.arn
  role       = module.terraform_cloud_audit_logs_lambda.name
}

resource "aws_iam_role_policy_attachment" "terraform_secret_access" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.terraform_secret_access.arn
  role       = module.terraform_cloud_audit_logs_lambda.name
}
