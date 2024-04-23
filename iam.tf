module "lambda_role" {
  for_each = local.audit_lambdas_names2

  source = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.3.3"

  name                  = "LambdaRole-${each.value}"
  create_policy         = false
  postfix               = false
  principal_identifiers = ["edgelambda.amazonaws.com", "lambda.amazonaws.com"]
  principal_type        = "Service"
  #role_policy           = var.policy
  tags = {}

  policy_arns = [
    aws_iam_policy.lambda_cloudwatch_group.arn,
    aws_iam_policy.lambda_kms_access.arn,
    aws_iam_policy.lambda_put_s3_bucket.arn,
    aws_iam_policy.terraform_lambda_to_sqs.arn,
    aws_iam_policy.terraform_secret_access.arn,
  ]
}

# Terraform
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

# Okta
resource "aws_iam_policy" "okta_secret_access" {
  provider    = aws.audit
  name        = "PolicyAllowOktaTokenSecret"
  description = "Policy allowing lambda to read token from secrets"
  path        = "/"
  policy      = data.aws_iam_policy_document.okta_secret_access.json
}

resource "aws_iam_role_policy_attachment" "okta_secret_access" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.okta_secret_access.arn
  role       = module.okta_audit_logs_lambda.role_name
}

# Gitlab
resource "aws_iam_policy" "gitlab_secret_access" {
  provider    = aws.audit
  name        = "PolicyAllowGitlabTokenSecret"
  description = "Policy allowing lambda to read token from secrets"
  path        = "/"
  policy      = data.aws_iam_policy_document.gitlab_secret_access.json
}

resource "aws_iam_role_policy_attachment" "gitlab_secret_access" {
  provider   = aws.audit
  policy_arn = aws_iam_policy.gitlab_secret_access.arn
  role       = module.gitlab_audit_logs_lambda.role_name
}
