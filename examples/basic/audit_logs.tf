module "audit_logs" {
  providers = { aws.audit = aws.audit }
  source    = "../../"

  gitlab_token    = "EXAMPLE_GITLAB_TOKEN"
  okta_token      = "EXAMPLE_OKTA_TOKEN"
  terraform_token = "EXAMPLE_TF_TOKEN"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  python_version = "3.8" # Depends on the available version of python in the runner of your TF binary
}
