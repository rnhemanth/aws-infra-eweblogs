data "aws_ec2_transit_gateway_attachment" "tgw_backbone" {
  filter {
    name   = "transit-gateway-id"
    values = toset([var.tgw_id_backbone])
  }
  filter {
    name   = "tag:Name"
    values = toset(["${var.name.environment}-core-net-tgw-attach-${var.name.service}-${var.name.identifier}-${data.aws_vpc.this.id}"])
  }
}

resource "aws_route" "tgw_backbone_route" {
  for_each = { for id in data.aws_route_tables.this.ids : id => id if data.aws_ec2_transit_gateway_attachment.tgw_backbone.state == "available" }

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