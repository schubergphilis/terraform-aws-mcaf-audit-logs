module "audit_logs_archive_bucket" {
  providers         = { aws = aws.audit }
  source            = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.11.0"
  name              = "ep-audit-logs-${local.account_id}"
  object_lock_mode  = "COMPLIANCE"
  object_lock_years = 1
  versioning        = true
  tags              = {}
  kms_key_arn       = var.kms_key_arn

  logging = {
    target_bucket = "ep-audit-logs-logging-${local.account_id}"
    target_prefix = "ep-audit-logs/"
  }

  lifecycle_rule = [
    {
      id      = "retention"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 14
      }

      expiration = {
        days = 365
      }

      noncurrent_version_expiration = {
        noncurrent_days = 365
      }

      noncurrent_version_transition = {
        noncurrent_days = 90
        storage_class   = "INTELLIGENT_TIERING"
      }

      transition = {
        days          = 90
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

module "audit_logs_archive_logging_bucket" {
  providers         = { aws = aws.audit }
  source            = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.11.0"
  name              = "ep-audit-logs-logging-${local.account_id}"
  object_lock_mode  = "COMPLIANCE"
  object_lock_years = 1
  versioning        = true
  tags              = {}
  kms_key_arn       = var.kms_key_arn

  lifecycle_rule = [
    {
      id      = "retention"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 14
      }

      expiration = {
        days = 365
      }

      noncurrent_version_expiration = {
        noncurrent_days = 365
      }

      noncurrent_version_transition = {
        noncurrent_days = 90
        storage_class   = "INTELLIGENT_TIERING"
      }

      transition = {
        days          = 90
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

module "lambda_deployment_package_bucket" {
  providers   = { aws = aws.audit }
  source      = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.11.0"
  name        = "ep-audit-logs-lambda-deployments-${local.account_id}"
  versioning  = true
  tags        = {}
  kms_key_arn = var.kms_key_arn

  lifecycle_rule = [
    {
      id      = "default"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }

      expiration = {
        expired_object_delete_marker = true
      }

      noncurrent_version_expiration = {
        noncurrent_days = 7
      }
    }
  ]
}

#module "lambda_terraform_deployment_package" {
#  providers                = { aws = aws.audit }
#  source                   = "terraform-aws-modules/lambda/aws"
#  version                  = "~> 6.4.0"
#  create_function          = false
#  recreate_missing_package = false
#  runtime                  = "python3.12"
#  s3_bucket                = module.lambda_deployment_package_bucket.name
#  s3_object_storage_class  = "STANDARD"
#  source_path              = "${path.module}/src/terraformcloud"
#  store_on_s3              = true
#  artifacts_dir            = "terraformcloud"
#}

data "archive_file" "lambda_terraform_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/terraformcloud"
  output_path = "${path.module}/src/terraformcloud.zip"
}

resource "aws_s3_object" "lambda_terraform_deployment_package" {
  bucket     = module.lambda_deployment_package_bucket.name
  key        = "terraformcloud.zip"
  kms_key_id = var.kms_key_arn
  source     = data.archive_file.lambda_terraform_zip.output_path
}

module "terraform_cloud_audit_logs_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  providers              = { aws = aws.audit }
  source                 = "schubergphilis/mcaf-lambda/aws"
  version                = "~> 1.2.1"
  name                   = local.audit_lambda_names.terraform
  create_policy          = false
  create_s3_dummy_object = false
  description            = "Lambda for gathering audit logs from terraform cloud and storing them in S3"
  filename               = data.archive_file.lambda_terraform_zip.output_path
  handler                = "${local.audit_lambda_names.terraform}.handler"
  kms_key_arn            = var.kms_key_arn
  log_retention          = 365
  memory_size            = 512
  runtime                = "python3.12"
  s3_bucket              = "ep-audit-logs-lambda-${local.account_id}" #TODO parameterise
  s3_key                 = aws_s3_object.lambda_terraform_deployment_package.key
  s3_object_version      = aws_s3_object.lambda_terraform_deployment_package.version_id
  source_code_hash       = data.archive_file.lambda_terraform_zip.output_base64sha256
  tags                   = {}
  timeout                = 600

  environment = {
    token_secret_name = local.environment.terraform_token_secret
    logs_bucket       = module.audit_logs_archive_bucket.name
    logs_url          = local.environment.terraform_api_url
    queue_url         = aws_sqs_queue.terraform_audit_log_queue.id
    file_prefix       = "terraform_logs/"
  }
}

#module "lambda_gitlab_deployment_package" {
#  providers                = { aws = aws.audit }
#  source                   = "terraform-aws-modules/lambda/aws"
#  version                  = "~> 6.4.0"
#  create_function          = false
#  recreate_missing_package = false
#  runtime                  = "python3.12"
#  s3_bucket                = module.lambda_deployment_package_bucket.name
#  s3_object_storage_class  = "STANDARD"
#  source_path              = "src/gitlab"
#  store_on_s3              = true
#  artifacts_dir            = "gitlab"
#}
#
#module "lambda_okta_deployment_package" {
#  providers                = { aws = aws.audit }
#  source                   = "terraform-aws-modules/lambda/aws"
#  version                  = "~> 6.4.0"
#  create_function          = false
#  recreate_missing_package = false
#  runtime                  = "python3.12"
#  s3_bucket                = module.lambda_deployment_package_bucket.name
#  s3_object_storage_class  = "STANDARD"
#  source_path              = "src/okta"
#  store_on_s3              = true
#  artifacts_dir            = "okta"
#}

# module "gitlab_audit_logs_lambda" {
#   #checkov:skip=CKV_AWS_272:Code signing not used for now
#   providers              = { aws = aws.audit }
#   source                 = "schubergphilis/mcaf-lambda/aws"
#   version                = "~> 1.1.0"
#   name                   = local.audit_lambda_names.gitlab
#   create_policy          = false
#   create_s3_dummy_object = false
#   description            = "Lambda for gathering audit logs from gitlab and storing them in S3"
#   filename               = module.lambda_gitlab_deployment_package.local_filename
#   handler                = "${local.audit_lambda_names.gitlab}.handler"
#   kms_key_arn            = var.kms_key_arn
#   log_retention          = 365
#   memory_size            = 512
#   role_arn               = aws_iam_role.role_lambda_audit_logs["gitlab"].arn
#   runtime                = "python3.12"
#   s3_bucket              = module.lambda_deployment_package_bucket.name
#   s3_key                 = module.lambda_gitlab_deployment_package.s3_object.key
#   s3_object_version      = module.lambda_gitlab_deployment_package.s3_object.version_id
#   tags                   = {}
#   timeout                = 600
# 
#   environment = {
#     token_secret_name  = local.environment.gitlab_token_secret
#     logs_bucket        = module.audit_logs_archive_bucket.name
#     logs_url           = local.environment.gitlab_api_url
#     log_level          = "info"
#     days_of_audit_logs = 1
#   }
# }

#module "okta_audit_logs_lambda" {
#  #checkov:skip=CKV_AWS_272:Code signing not used for now
#  providers              = { aws = aws.audit }
#  source                 = "schubergphilis/mcaf-lambda/aws"
#  version                = "~> 1.1.0"
#  name                   = local.audit_lambda_names.okta
#  create_policy          = false
#  create_s3_dummy_object = false
#  description            = "Lambda for gathering audit logs from Okta and storing them in S3"
#  filename               = module.lambda_okta_deployment_package.local_filename
#  handler                = "${local.audit_lambda_names.okta}.handler"
#  kms_key_arn            = var.kms_key_arn
#  log_retention          = 365
#  memory_size            = 512
#  role_arn               = aws_iam_role.role_lambda_audit_logs["okta"].arn
#  runtime                = "python3.12"
#  s3_bucket              = module.lambda_deployment_package_bucket.name
#  s3_key                 = module.lambda_okta_deployment_package.s3_object.key
#  s3_object_version      = module.lambda_okta_deployment_package.s3_object.version_id
#  tags                   = {}
#  timeout                = 600
#
#  environment = {
#    token_secret_name = local.environment.okta_token_secret
#    logs_bucket       = module.audit_logs_archive_bucket.name
#    log_level         = "info"
#    file_prefix       = "okta_logs/"
#  }
#}
