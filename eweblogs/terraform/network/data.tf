data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# data "aws_secretsmanager_secret_version" "domain_creds" {
#    count = var.domain_password_secret_arn != "" ? 1 : 0
#    secret_id = var.domain_password_secret_arn
# }