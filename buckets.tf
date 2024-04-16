module "audit_logs_archive_bucket" {
  providers         = { aws = aws.audit }
  source            = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.11.0"
  name              = "${var.bucket_base_name}-${local.account_id}"
  object_lock_mode  = try(var.object_locking.mode, null)
  object_lock_years = try(var.object_locking.years, null)
  versioning        = true
  tags              = {}
  kms_key_arn       = var.kms_key_arn

  logging = {
    target_bucket = module.audit_logs_archive_logging_bucket.name
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
  name              = "${var.bucket_base_name}-logging-${local.account_id}"
  object_lock_mode  = try(var.object_locking.mode, null)
  object_lock_years = try(var.object_locking.years, null)
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
  name        = "${var.bucket_base_name}-lambda-${local.account_id}"
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

