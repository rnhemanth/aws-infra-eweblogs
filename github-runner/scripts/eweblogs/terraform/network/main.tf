# VPC
module "vpc" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
  source = "git::https://github.com/emisgroup/terraform-aws-vpc.git?ref=v0.2.0"

  ipv4_primary_cidr_block              = var.ipv4_primary_cidr_block
  manage_default_security_group        = true
  manage_default_route_table           = true
  manage_default_network_acl           = true
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  create_dhcp_options                  = true
  create_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  intra_subnets                        = var.intra_subnets
  name                                 = var.name
}

# VPC Endpoints
module "vpc_endpoints" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
  source = "git::https://github.com/emisgroup/terraform-aws-vpc-endpoints.git?ref=v0.2.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpce_tls.id]

  endpoints = {
    s3 = {
      service            = "s3"
      subnet_ids         = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
      security_group_ids = [aws_security_group.vpce_tls.id]
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
      security_group_ids  = [aws_security_group.vpce_tls.id]
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
      security_group_ids  = [aws_security_group.vpce_tls.id]
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
      security_group_ids  = [aws_security_group.vpce_tls.id]
    },
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = [module.vpc.intra_subnet_ids["ewl-2a"][0]]
      security_group_ids  = [aws_security_group.vpce_tls.id]
    },
  }
  name = local.vpc_endpoint_name
}

data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}

resource "aws_security_group" "vpce_tls" {
  # checkov:skip=CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC for VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    "Name" = local.security_group_name
  }
}

data "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  depends_on = [
    module.vpc_endpoints
  ]
}

#resource "aws_route53_zone" "this" {
#  # checkov:skip=CKV2_AWS_38: "Ensure Domain Name System Security Extensions (DNSSEC) signing is enabled for Amazon Route 53 public hosted zones - Skipping private hosted zone"
#  # checkov:skip=CKV2_AWS_39: ""Ensure Domain Name System (DNS) query logging is enabled for Amazon Route 53 hosted zones - Skipping private hosted zone"
#  name = "s3.${data.aws_region.current.name}.amazonaws.com"
#  vpc {
#    vpc_id = module.vpc.vpc_id
#  }
#}

#resource "aws_route53_record" "this" {
#  zone_id = aws_route53_zone.this.id
#  name    = ""
#  type    = "A"

#  alias {
#    name                   = replace(data.aws_vpc_endpoint.s3.dns_entry[0].dns_name, "*", "\\052")
#    zone_id                = data.aws_vpc_endpoint.s3.dns_entry[0].hosted_zone_id
#    evaluate_target_health = true
#  }
#}

# This specific resource is for the PHZs that need one extra alias with a "*" (for example, Amazon S3)
#resource "aws_route53_record" "this_wildcard" {
#  zone_id = aws_route53_zone.this.id
#  name    = "*"
#  type    = "A"

#  alias {
#    name                   = replace(data.aws_vpc_endpoint.s3.dns_entry[0].dns_name, "*", "\\052")
#    zone_id                = data.aws_vpc_endpoint.s3.dns_entry[0].hosted_zone_id
#    evaluate_target_health = true
#  }
#}

#module "transit_gateway_attachment" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
#  source = "git::https://github.com/emisgroup/terraform-aws-tgw-attach.git?ref=v0.2.0"
#  transit_gateway_attachments = {
#    tgw-backbone = {
#      vpc_id                 = module.vpc.vpc_id
#      transit_gateway_id     = var.tgw_id_backbone
#      subnet_ids             = [module.vpc.intra_subnet_ids["ewll-2a"][0]]
#      appliance_mode_support = "disable"
#    }
#  }
#  name = local.transit_gateway_name
#}

/* module "vpc_peering" {
  source   = "git::https://github.com/emisgroup/terraform-aws-vpc-peering.git?ref=v0.2.0"
  for_each = var.vpc_peering_connections
  vpc_peering_connections = {
    peer = {
      vpc_id        = module.vpc.vpc_id
      peer_vpc_id   = each.value.peer_vpc_id
      peer_owner_id = each.value.peer_owner_id
      peer_region   = data.aws_region.current.name
    }
  }
  tags        = var.tags
  name        = local.vpc_peering_name
  auto_accept = var.auto_accept
} */