data "aws_ec2_transit_gateway_vpc_attachments" "vpc_attachments" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "transit-gateway-id"
    values = [var.tgw_id_backbone]
  }
  filter {
    name   = "state"
    values = ["available", "pending-acceptance"]
  }
}

resource "aws_route" "tgw_backbone_route" {
  for_each = length(data.aws_ec2_transit_gateway_vpc_attachments.vpc_attachments.ids) > 0 ? toset(data.aws_route_tables.this.ids) : toset([])

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw_id_backbone
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each         = var.route53_resolver_rules
  resolver_rule_id = each.value.rule_id
  vpc_id           = data.aws_vpc.this.id
}

data "aws_route_tables" "this" {
  vpc_id = data.aws_vpc.this.id
}

data "aws_vpc" "this" {
  cidr_block = var.ipv4_primary_cidr_block
}