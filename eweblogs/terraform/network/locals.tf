locals {
  transit_gateway_name = "${var.environment}-core-net-tgw-attach-${var.name.service}-${var.name.identifier}"
  vpc_endpoint_name    = "${var.environment}-core-net-vpce-${var.name.service}-${var.name.identifier}"
  security_group_name  = "${var.environment}-core-net-sg-vpce-${var.name.service}-${var.name.identifier}"
 # domain_credentials   = var.domain_password_secret_arn != "" ? jsondecode(data.aws_secretsmanager_secret_version.domain_creds[0].secret_string) : null
}