# terraform-aws-mcaf-audit-lambdas

## Required update on Audit KMS key
```
data "aws_iam_policy_document" "kms_allow_secretsmanager" {
  statement {
    sid = "Allow Secrets Manager to use the KMS key"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]

    resources = [
      "arn:aws:kms:eu-west-1:${data.aws_caller_identity.audit.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"

      values = [
        "${data.aws_caller_identity.audit.account_id}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "secretsmanager.eu-west-1.amazonaws.com"
      ]
    }
  }

  statement {
    sid = "Allow CloudWatch to use the KMS key"

    principals {
      type        = "Service"
      identifiers = ["logs.eu-west-1.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.audit.account_id}:log-group:/aws/lambda/*"
      ]
    }
  }

  statement {
    sid = "Allow S3 to use the KMS key"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Allow reading encrypted deploymentCloudWatch to use the KMS key"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Decrypt",
      "kms:Encrypt"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"

      values = [
        "arn:aws:iam::${data.aws_caller_identity.audit.account_id}:role/AWSControlTowerExecution"
      ]
    }
  }
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.40.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.40.0 |
| <a name="provider_aws.audit"></a> [aws.audit](#provider\_aws.audit) | >= 4.40.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_audit_logs_archive_bucket"></a> [audit\_logs\_archive\_bucket](#module\_audit\_logs\_archive\_bucket) | schubergphilis/mcaf-s3/aws | 0.13.1 |
| <a name="module_audit_logs_archive_logging_bucket"></a> [audit\_logs\_archive\_logging\_bucket](#module\_audit\_logs\_archive\_logging\_bucket) | schubergphilis/mcaf-s3/aws | 0.13.1 |
| <a name="module_gitlab_audit_logs_lambda"></a> [gitlab\_audit\_logs\_lambda](#module\_gitlab\_audit\_logs\_lambda) | schubergphilis/mcaf-lambda/aws | ~> 1.3.0 |
| <a name="module_lambda_deployment_package_bucket"></a> [lambda\_deployment\_package\_bucket](#module\_lambda\_deployment\_package\_bucket) | schubergphilis/mcaf-s3/aws | 0.13.1 |
| <a name="module_lambda_gitlab_deployment_package"></a> [lambda\_gitlab\_deployment\_package](#module\_lambda\_gitlab\_deployment\_package) | terraform-aws-modules/lambda/aws | ~> 7.2.5 |
| <a name="module_lambda_okta_deployment_package"></a> [lambda\_okta\_deployment\_package](#module\_lambda\_okta\_deployment\_package) | terraform-aws-modules/lambda/aws | ~> 7.2.5 |
| <a name="module_lambda_terraform_deployment_package"></a> [lambda\_terraform\_deployment\_package](#module\_lambda\_terraform\_deployment\_package) | terraform-aws-modules/lambda/aws | ~> 7.2.5 |
| <a name="module_okta_audit_logs_lambda"></a> [okta\_audit\_logs\_lambda](#module\_okta\_audit\_logs\_lambda) | schubergphilis/mcaf-lambda/aws | ~> 1.3.0 |
| <a name="module_terraform_cloud_audit_logs_lambda"></a> [terraform\_cloud\_audit\_logs\_lambda](#module\_terraform\_cloud\_audit\_logs\_lambda) | schubergphilis/mcaf-lambda/aws | ~> 1.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.audit_trigger_daily](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.gitlab_audit_trigger_daily](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.okta_audit_trigger_daily](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.terraform_audit_trigger_daily](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.gitlab_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_cloudwatch_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_kms_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_put_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.okta_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.terraform_lambda_to_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.terraform_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.gitlab_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_cloudwatch_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_kms_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_put_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.okta_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.terraform_lambda_to_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.terraform_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_event_source_mapping.terraform_audit_sqs_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_permission.allow_cloudwatch_to_invoke_audit_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_object.lambda_gitlab_deployment_package](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.lambda_okta_deployment_package](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.lambda_terraform_deployment_package](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_secretsmanager_secret.gitlab_token_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.okta_token_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.terraform_token_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.gitlab_token_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.okta_token_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.terraform_token_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_sqs_queue.terraform_audit_log_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.terraform_audit_log_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_caller_identity.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.gitlab_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_kms_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.log_group_audit_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.okta_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.terraform_lambda_to_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.terraform_secret_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_token"></a> [gitlab\_token](#input\_gitlab\_token) | The GitLab token used to authenticate with the GitLab API | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the resources | `string` | n/a | yes |
| <a name="input_okta_token"></a> [okta\_token](#input\_okta\_token) | The Okta token used to authenticate with the Okta API | `string` | n/a | yes |
| <a name="input_terraform_token"></a> [terraform\_token](#input\_terraform\_token) | The Terraform Cloud Organisation token used to authenticate with the Terraform Cloud API | `string` | n/a | yes |
| <a name="input_bucket_base_name"></a> [bucket\_base\_name](#input\_bucket\_base\_name) | The base name for the S3 buckets | `string` | `"audit-logs"` | no |
| <a name="input_object_locking"></a> [object\_locking](#input\_object\_locking) | The object locking configuration for the S3 buckets | <pre>object({<br>    mode  = string<br>    years = number<br>  })</pre> | <pre>{<br>  "mode": "GOVERNANCE",<br>  "years": 1<br>}</pre> | no |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | The version of Python to use in the Lambda functions | `string` | `"3.12"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->