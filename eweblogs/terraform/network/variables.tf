variable "ipv4_primary_cidr_block" {
  description = "(Optional) The IPv4 CIDR block for the VPC."
  type        = string
}

variable "ipv4_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  type        = list(string)
  default     = []
}

variable "kms_service" {
  description = "short service name for kms key naming"
  type        = string
  default     = "eweb"
}

variable "public_subnets" {
  type = map(object({
    cidr_block           = string
    availability_zone_id = string
  }))
  default = {}
}

variable "private_subnets" {
  type = map(object({
    cidr_block           = string
    availability_zone_id = string
  }))
  default = {}
}

variable "intra_subnets" {
  type = map(map(object({
    cidr_block           = string
    availability_zone_id = string
  })))
  default = null
}

variable "tgw_id_backbone" {
  type        = string
  description = "TGW Backbone ID"
}

/* variable "route53_resolver_rules" {
  type = map(object({
    rule_id = string
  }))
  description = "Route53 resolver rules to attach to VPC"
} */

/* variable "vpc_peering_connections" {
  type = map(object({
    peer_vpc_id   = string
    peer_owner_id = string
  }))
  default = {}
} */

variable "transit_gateway_attachments" {
  description = "Map of objects that define the transit gateway attachments to be created"
  type = map(object({
    vpc_id             = string
    subnet_ids         = string
    transit_gateway_id = string
    #  Whether Appliance Mode support is enabled. If enabled, a traffic flow between a source and destination uses the same Availability Zone for the VPC attachment for the lifetime of that flow. Valid values: `disable`, `enable`. Default value: `disable`."
    appliance_mode_support = string
  }))
  default = {}
}

variable "name" {
  type = object({
    environment = string
    service     = string
    identifier  = string
  })
  description = "environment, service and identifier. part of naming standards"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "auto_accept" {
  type        = bool
  description = "Accept the peering (both VPCs need to be in the same AWS account and region)"
  default     = false
}

variable "wsus_rg_prefix" {
  type        = string
  description = "resource group prefix i.e eweblogs"
  default     = "eweb_ibi"
}

variable "domain_credentials" {
  description = "Domain Credentials in key-value format. password secret value from Managed AD Account"
  default     = ""
}

variable "key_users" {
  description = "A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users)"
  type        = list(string)
  default     = []
}

variable "key_service_users" {
  description = "A list of IAM ARNs for [key service users]"
  type        = list(string)
  default     = []
}

variable "key_administrators" {
  description = "A list of IAM ARNs for [key administrators]"
  type        = list(string)
  default     = []
}

variable "environment" {
  type        = string
  description = "environment name i.e. dev/stg/prod"
}


variable "standard_sg_rules_cidr_blocks" {
  type = map(object({
    desc     = string
    type     = string
    from     = number
    to       = number
    protocol = string
    cidr     = list(string)
  }))
  description = "Security group rules to CIDR blocks - standard."
  default     = {}
}

variable "standard_sg_rules_self" {
  type = map(object({
    desc     = string
    type     = string
    from     = number
    to       = number
    protocol = string
    self     = bool
  }))
  description = "Security group rules to self reference - standard."
  default     = {}
}

variable "standard_sg_rules_security_group" {
  type = map(object({
    desc      = string
    type      = string
    from      = number
    to        = number
    protocol  = string
    source_sg = string
  }))
  description = "Security group rules to another sg - standard."
  default     = {}
}

variable "bastion_sg_rules_cidr_blocks" {
  type = map(object({
    desc     = string
    type     = string
    from     = number
    to       = number
    protocol = string
    cidr     = list(string)
  }))
  description = "Security group rules to CIDR blocks - bastion."
  default     = {}
}

variable "bastion_sg_rules_self" {
  type = map(object({
    desc     = string
    type     = string
    from     = number
    to       = number
    protocol = string
    self     = bool
  }))
  description = "Security group rules to self reference - bastion."
  default     = {}
}

variable "sql_sg_rules_cidr_blocks" {
  type = map(object({
    desc     = string
    type     = string
    from     = number
    to       = number
    protocol = string
    cidr     = list(string)
  }))
  description = "Security group rules to CIDR blocks - eweblogs sql"
  default     = {}
}

variable "sql_sg_rules_self" {
  type = map(object({
    desc     = string
    type     = string
    from     = number
    to       = number
    protocol = string
    self     = bool
  }))
  description = "Security group rules to self reference - eweblogs sql."
  default     = {}
}

variable "jit_access" {
  type = string
}

