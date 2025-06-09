module "kms" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
  source = "git::https://github.com/emisgroup/terraform-aws-kms-cmk.git?ref=v0.2.1"

  name                    = "${var.environment}-${var.name.service}-sec-kk-infra"
  deletion_window_in_days = 7
  description             = "KMS Customer Managed Key - infra"
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  # Policy
  enable_default_policy = false
  key_owners = [
    data.aws_caller_identity.current.arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
  ]
  key_users          = var.key_users
  key_administrators = var.key_administrators
  key_service_users  = var.key_service_users
  key_statements = [
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*",
          ]
        }
      ]
    }
  ]

  # Aliases
  aliases                 = ["${var.environment}-${var.name.service}-sec-kk-infra"]
  aliases_use_name_prefix = false

  tags = {
    Repository = "https://github.com/emisgroup/terraform-aws-kms-cmk"
  }
}