locals {
  s3_object_keys = {
    terraform = "terraformcloud/${element(split("/", module.lambda_terraform_deployment_package.local_filename), length(split("/", module.lambda_terraform_deployment_package.local_filename)) - 1)}"
    okta      = "okta/${element(split("/", module.lambda_okta_deployment_package.local_filename), length(split("/", module.lambda_okta_deployment_package.local_filename)) - 1)}"
  }
}

# Terraform
module "lambda_terraform_deployment_package" {
  providers                = { aws = aws.audit }
  source                   = "terraform-aws-modules/lambda/aws"
  version                  = "~> 7.2.5"
  create_function          = false
  recreate_missing_package = false
  runtime                  = "python${var.python_version}"
  source_path              = "${path.module}/src/terraformcloud"
  artifacts_dir            = "${path.root}/package/terraformcloud"
}

resource "aws_s3_object" "lambda_terraform_deployment_package" {
  provider   = aws.audit
  bucket     = module.lambda_deployment_package_bucket.name
  key        = local.s3_object_keys.terraform
  kms_key_id = var.kms_key_arn
  source     = module.lambda_terraform_deployment_package.local_filename
}

module "terraform_cloud_audit_logs_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  providers = { aws = aws.audit }
  #source                 = "schubergphilis/mcaf-lambda/aws"
  #version                = "~> 1.2.1"
  source                 = "github.com/schubergphilis/terraform-aws-mcaf-lambda?ref=f-add-role-name-output" #TODO Pending https://github.com/schubergphilis/terraform-aws-mcaf-lambda/pull/73
  name                   = local.audit_lambda_names.terraform
  create_policy          = false
  create_s3_dummy_object = false
  description            = "Lambda for gathering audit logs from Terraform Cloud and storing them in S3"
  handler                = "${local.audit_lambda_names.terraform}.handler"
  kms_key_arn            = var.kms_key_arn
  log_retention          = 365
  memory_size            = 512
  runtime                = "python${var.python_version}"
  s3_bucket              = "${var.bucket_base_name}-lambda-${local.account_id}"
  s3_key                 = local.s3_object_keys.terraform
  s3_object_version      = aws_s3_object.lambda_terraform_deployment_package.version_id
  source_code_hash       = aws_s3_object.lambda_terraform_deployment_package.checksum_sha256
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

# Okta
module "lambda_okta_deployment_package" {
  providers                = { aws = aws.audit }
  source                   = "terraform-aws-modules/lambda/aws"
  version                  = "~> 7.2.5"
  create_function          = false
  recreate_missing_package = false
  runtime                  = "python${var.python_version}"
  source_path              = "${path.module}/src/okta"
  artifacts_dir            = "${path.root}/package/okta"
}

resource "aws_s3_object" "lambda_okta_deployment_package" {
  provider   = aws.audit
  bucket     = module.lambda_deployment_package_bucket.name
  key        = local.s3_object_keys.okta
  kms_key_id = var.kms_key_arn
  source     = module.lambda_okta_deployment_package.local_filename
}

module "okta_audit_logs_lambda" {
  #checkov:skip=CKV_AWS_272:Code signing not used for now
  providers = { aws = aws.audit }
  #source                 = "schubergphilis/mcaf-lambda/aws"
  #version                = "~> 1.2.1"
  source                 = "github.com/schubergphilis/terraform-aws-mcaf-lambda?ref=f-add-role-name-output" #TODO Pending https://github.com/schubergphilis/okta-aws-mcaf-lambda/pull/73
  name                   = local.audit_lambda_names.okta
  create_policy          = false
  create_s3_dummy_object = false
  description            = "Lambda for gathering audit logs from Okta and storing them in S3"
  handler                = "${local.audit_lambda_names.okta}.handler"
  kms_key_arn            = var.kms_key_arn
  log_retention          = 365
  memory_size            = 512
  runtime                = "python${var.python_version}"
  s3_bucket              = "${var.bucket_base_name}-lambda-${local.account_id}"
  s3_key                 = local.s3_object_keys.okta
  s3_object_version      = aws_s3_object.lambda_okta_deployment_package.version_id
  source_code_hash       = aws_s3_object.lambda_okta_deployment_package.checksum_sha256
  tags                   = {}
  timeout                = 600

  environment = {
    file_prefix       = "okta_logs/"
    log_level         = "info"
    logs_bucket       = module.audit_logs_archive_bucket.name
    token_secret_name = local.environment.okta_token_secret
  }
}

# # Gitlab
# module "lambda_gitlab_deployment_package" {
#   providers                = { aws = aws.audit }
#   source                   = "terraform-aws-modules/lambda/aws"
#   version                  = "~> 6.4.0"
#   create_function          = false
#   recreate_missing_package = false
#   runtime                  = "python${var.python_version}"
#   s3_bucket                = module.lambda_deployment_package_bucket.name
#   s3_object_storage_class  = "STANDARD"
#   source_path              = "src/gitlab"
#   store_on_s3              = true
#   artifacts_dir            = "gitlab"
# }
# 
# resource "aws_s3_object" "lambda_okta_deployment_package" {
#   provider   = aws.audit
#   bucket     = module.lambda_deployment_package_bucket.name
#   key        = local.s3_object_keys.okta
#   kms_key_id = var.kms_key_arn
#   source     = module.lambda_okta_deployment_package.local_filename
# }
#
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
#   runtime                = "python${var.python_version}"
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
