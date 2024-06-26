terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.40.0"
      configuration_aliases = [aws.audit]
    }
  }
  required_version = ">= 1.3"
}
