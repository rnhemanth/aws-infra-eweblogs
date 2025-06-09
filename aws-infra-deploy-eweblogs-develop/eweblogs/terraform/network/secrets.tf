resource "aws_secretsmanager_secret" "defaultad" {
  # checkov:skip=CKV2_AWS_57: "Ensure Secrets Manager secrets should have automatic rotation enabled"
  name = "${var.name.environment}-${var.name.service}-sec-sm-default-ad"
  kms_key_id  = module.kms.key_arn
  description = "Default Password for AD users"
  tags = {
    Name = "${var.name.environment}-${var.name.service}-sec-sm-default-ad"
  }
}

resource "aws_secretsmanager_secret_version" "defaultad" {
  secret_id     = aws_secretsmanager_secret.defaultad.id
  secret_string = jsonencode(local.domain_credentials)
}

resource "aws_ssm_parameter" "DEFAULT_AD_SECRET_NAME" {
  # checkov:skip=CKV_AWS_337: "Ensure SSM parameters are using KMS CMK"
  name  = "/tf/output/DEFAULT_AD_SECRET_NAME"
  type  = "SecureString"
  value = aws_secretsmanager_secret.defaultad.name
}