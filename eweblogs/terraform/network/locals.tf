locals {
  transit_gateway_name = "${var.environment}-core-net-tgw-attach-${var.name.service}-${var.name.identifier}"
  vpc_endpoint_name    = "${var.environment}-core-net-vpce-${var.name.service}-${var.name.identifier}"
  security_group_name  = "${var.environment}-core-net-sg-vpce-${var.name.service}-${var.name.identifier}"
  domain_credentials   = jsondecode(var.domain_credentials)
}