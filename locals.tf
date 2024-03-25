locals {
  audit_lambdas = {
    #    gitlab = "GitLab"
    terraform = "TerraformCloud"
    #    okta      = "Okta"
  }
  audit_lambda_names = {
    #    gitlab = "gitlab_audit_logs"
    terraform = "terraform_cloud_audit_logs"
    #    okta      = "okta_audit_logs"
  }
  environment = {
    gitlab_api_url         = "https://gitlab.com/api/v4"
    gitlab_token_secret    = "/audit-log-tokens/gitlab"
    okta_token_secret      = "/audit-log-tokens/okta"
    terraform_api_url      = "https://app.terraform.io/api/v2/organization/audit-trail"
    terraform_token_secret = "/audit-log-tokens/terraform"
  }
  account_id = data.aws_caller_identity.audit.account_id
}
