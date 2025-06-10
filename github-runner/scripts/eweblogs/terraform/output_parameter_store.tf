locals {
  secondary_ips = {
    for server in var.servers :
    server.name => {
      secondary_ip_1 = try(server.secondary_ip_1, null)
      secondary_ip_2 = try(server.secondary_ip_2, null)
    }
  }
  subnets = {
    for server in var.servers :
    server.name => server.subnet_id
  }
}

data "aws_subnet" "subnets" {
  for_each = toset(values(local.subnets))
  id       = each.value
}

# SSM Parameters for instance information
resource "aws_ssm_parameter" "instance_ids" {
  for_each = module.ec2

  name  = "/eweblogs/${var.environment}/ec2/${each.key}/instance-id"
  type  = "SecureString"
  key_id = module.kms.key_id
  value = each.value.id

  tags = {
    Environment = var.environment
    Service     = var.service
    Instance    = each.key
  }
}

resource "aws_ssm_parameter" "instance_private_ips" {
  for_each = module.ec2

  name  = "/eweblogs/${var.environment}/ec2/${each.key}/private-ip"
  type  = "SecureString"
  key_id = module.kms.key_id
  value = each.value.private_ip

  tags = {
    Environment = var.environment
    Service     = var.service
    Instance    = each.key
  }
}