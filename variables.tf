variable "bucket_base_name" {
  type        = string
  default     = "audit-logs"
  description = "The base name for the S3 buckets"
}

variable "gitlab_token" {
  type        = string
  description = "The GitLab token used to authenticate with the GitLab API"
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt the resources"
}

variable "object_locking" {
  type = object({
    mode  = string
    years = number
  })
  default = {
    mode  = "GOVERNANCE"
    years = 1
  }
  description = "The object locking configuration for the S3 buckets"
}

variable "okta_token" {
  type        = string
  description = "The Okta token used to authenticate with the Okta API"
}

variable "terraform_token" {
  type        = string
  description = "The Terraform Cloud Organisation token used to authenticate with the Terraform Cloud API"
}
