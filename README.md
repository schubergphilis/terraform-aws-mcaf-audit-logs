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