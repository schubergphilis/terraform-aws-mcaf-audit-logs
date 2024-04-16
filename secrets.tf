
# Terraform
resource "aws_secretsmanager_secret" "terraform_token_secret" {
  provider   = aws.audit
  name       = local.environment.terraform_token_secret
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "terraform_token_secret_version" {
  provider      = aws.audit
  secret_id     = aws_secretsmanager_secret.terraform_token_secret.id
  secret_string = var.terraform_token
}

# Okta
resource "aws_secretsmanager_secret" "okta_token_secret" {
  provider   = aws.audit
  name       = local.environment.okta_token_secret
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "okta_token_secret_version" {
  provider      = aws.audit
  secret_id     = aws_secretsmanager_secret.okta_token_secret.id
  secret_string = var.okta_token
}

## Gitlab
#resource "aws_secretsmanager_secret" "gitlab_token_secret" {
#  provider   = aws.audit
#  name       = local.environment.gitlab_token_secret
#  kms_key_id = var.kms_key_arn
#}
#
#resource "aws_secretsmanager_secret_version" "gitlab_token_secret_version" {
#  provider      = aws.audit
#  secret_id     = aws_secretsmanager_secret.gitlab_token_secret.id
#  secret_string = var.gitlab_token
#}
