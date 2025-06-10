variable "tgw_id_backbone" {
  type        = string
  description = "TGW Backbone ID"
}

variable "ipv4_primary_cidr_block" {
  description = "(Optional) The IPv4 CIDR block for the VPC."
  type        = string
}

variable "route53_resolver_rules" {
  type = map(object({
    rule_id = string
  }))
  description = "Route53 resolver rules to attach to VPC"
}

variable "name" {
  type = object({
    environment = string
    service     = string
    identifier  = string
  })
  description = "environment, service and identifier. part of naming standards"
}