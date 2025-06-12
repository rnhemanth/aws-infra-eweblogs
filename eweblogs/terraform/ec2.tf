locals {
  instance_types = { for server in var.servers : server.name => server.instance_type }
  default_cores = {
    for name, instance_type in local.instance_types :
    name => data.aws_ec2_instance_type.default[instance_type].default_cores
  }
}

data "aws_ec2_instance_type" "default" {
  for_each      = toset(values(local.instance_types))
  instance_type = each.value
}

module "ec2" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
  source = "git::https://github.com/emisgroup/terraform-aws-ec2.git?ref=v0.1.4-ignore_ami"
  for_each = { for server in var.servers : server.name => server }

  name                      = "${upper(var.ec2_name_prefix)}${upper(var.region_prefix)}${upper(local.instance_service_name)}${upper(each.value.name)}"
  vpc_id                    = data.aws_vpc.vpc.id
  ami                       = each.value.ami_id
  associate_public_ip_address = false
  create_iam_instance_profile = false
  subnet_id                 = each.value.subnet_id
  availability_zone         = each.value.az
  instance_type             = each.value.instance_type
  root_kms_key_id           = module.kms.key_arn
  default_ebs_kms_key_id    = module.kms.key_arn
  ebs_kms_key_id            = module.kms.key_arn
  disable_api_termination   = true

  cpu_core_count            = coalesce(each.value.multithreading_enabled, false) ? null : local.default_cores[each.key]
  cpu_threads_per_core      = each.value.server_type == "db" ? coalesce(each.value.multithreading_enabled, false) ? 2 : 1 : null

  private_ip                = lookup(each.value, "primary_ip", null)

  secondary_private_ips = var.sql_ag ? [
    "${each.value.secondary_ip_1}",
    "${each.value.secondary_ip_2}",
    "${each.value.secondary_ip_3}"
  ] : null

  vpc_security_group_ids = [
    data.aws_security_group.standard.id,
    data.aws_security_group.sql.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 125
      volume_size = coalesce(each.value.root_volume_size, 50)
      iops        = 3000
    }
  ]

  ebs_block_device = [
    for device in [
      {
        device_name = "/dev/sdb"
        volume_type = "gp3"
        volume_size = coalesce(each.value.d_volume_size, 20)
        throughput  = coalesce(each.value.d_throughput, 125)
        iops        = coalesce(each.value.d_iops, 3000)
        encrypted   = true
        tags = {
          DriveName   = "DATA"
          DriveLetter = "D"
        }
      },
      each.value.server_function == "eweblogs-ssis" ? {
        device_name = "/dev/sdc"
        volume_type = "gp3"
        volume_size = coalesce(each.value.l_volume_size, 20)
        throughput  = coalesce(each.value.l_throughput, 125)
        iops        = coalesce(each.value.l_iops, 3000)
        encrypted   = true
        tags = {
          DriveName   = "LOGS"
          DriveLetter = "L"
        }
      } : null,
      each.value.server_function == "eweblogs-ssis" ? {
        device_name = "/dev/sdf"
        volume_type = "gp3"
        volume_size = coalesce(each.value.t_volume_size, 20)
        throughput  = coalesce(each.value.t_throughput, 125)
        iops        = coalesce(each.value.t_iops, 3000)
        encrypted   = true
        tags = {
          DriveName   = "TEMP"
          DriveLetter = "T"
        }
      } : null,
    ] : device if device != null
  ]

  tags = {
    server_type         = each.value.server_type
    server_function     = each.value.server_function
    wsus                = each.value.wsus_group
    "${each.value.wsus_qsid}" = "${each.value.wsus_policy_group}"
    lifecycle           = coalesce(each.value.lifecycle_tag, "production")
    rg_service          = coalesce(each.value.rg, "aws-eweblogs")
  }

  user_data_base64 = base64encode(templatefile("${path.module}/files/user_data.ps1", {
   DomainPassword = data.aws_secretsmanager_secret.defaultadsecret.id
    hostname       = "${upper(var.ec2_name_prefix)}${upper(var.region_prefix)}${upper(local.instance_service_name)}${upper(each.value.name)}"
    OUPath         = local.ou_path
   }))
}
