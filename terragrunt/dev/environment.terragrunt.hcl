locals {
  common = read_terragrunt_config("${get_terragrunt_dir()}/../common.terragrunt.hcl")

  # Configure environment
  region             = get_env("AWS_REGION")
  account_id         = get_env("AWS_ACCOUNT_ID")
  environment        = get_env("ENVIRONMENT")
  service            = local.common.locals.service
  project_name       = "${local.environment}-${local.service}"
  region_prefix      = format("%s%s%s", substr("${local.region}", 0, 2), substr("${local.region}", 3, 1), substr("${local.region}", 8, 1))
  service_identifier = "${local.common.locals.service_location}"

### SFTP ###
#  ssh_key = get_env("ssh_key")
#  transfer_users = {
#    test = {
#      user_name      = "test"
#      home_directory = "test"
#      ssh_key        = local.ssh_key # This is a ssh key owned by IBI team to test client connection. A customer ssh key will be manaully added via the management console.
#    }
#  }

### VPC ###
  ipv4_primary_cidr_block       = "100.68.63.192/26" # UPDATE_ME to 100.68.58.192/26
# sftp_ipv4_primary_cidr_block  = "100.68.70.32/27" # UPDATE_ME
  tgw_id_backbone               = "tgw-0f28603fcaf843cb9"

  intra_subnets = {
    ewl = {
      ewl-2a = {
        cidr_block           = "100.68.63.192/27" # UPDATE_ME to 100.68.58.192/27
        availability_zone_id = "euw2-az1"
        map_public_ip_on_launch = false
      }
    }
  }

  name = {
    environment = "${local.environment}"
    service     = "eweb"
    identifier  = "ibi"
  }

  kms_service = "eweb"

 # route53_resolver_rules = {
    # dev_england_emis_web_com = {
    #   rule_id = "rslvr-rr-6cefc1a34e264c61b"
    # }
    # dev_shared-services_emis-web_com = {
    #   rule_id = "rslvr-rr-4b6ebb37adf24a43b"
    # }
    # dev_iom_emis_web_com = {
    #   rule_id = "rslvr-rr-aa135d6f2ba942caa"
    # }
 # }

### KMS ###
  key_users        = [
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/${local.region}/AWSReservedSSO_generic-dev-access_235380602eb3a234",
  # "arn:aws:iam::${local.account_id}:role/${local.environment}-eweblogs-net-ec2-role"
    ]
  key_administrors = [
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/${local.region}/AWSReservedSSO_generic-dev-access_235380602eb3a234"
    ]

### EC2 ###
  ec2_name_prefix    = "dv"
  domain_password_secret_arn = "arn:aws:secretsmanager:eu-west-2:069082606602:secret:dev-ew-sec-sm-sharedservices-ad-directory-domain-joiner-GcIT0Q"
  servers = [
    {
      name                    = "SIS01"
      subnet_id               = "subnet-0dd861662c290f07f"
      az                      = "eu-west-2c"
      instance_type           = "t3.large"
      server_function         = "ibi-ssis"
      server_type             = "db"
      ami_id                  = "ami-06eb09971f4a1acdb"
      wsus_group              = "scan_only"
      wsus_qsid               = "QSConfigName-${local.wsus_qsconfig_id_ringscan}"
      wsus_policy_group       = "${local.wsus_policy_scan_only_name}"
      root_volume_size        = 50
      d_volume_size           = 100
      d_volume_throughput     = 125
      d_volume_iops           = 3000
      multithreading_enabled  = false
      rg = "aws-eweblogs"
    },
    {
      name                    = "SRS01"
      subnet_id               = "subnet-0dd861662c290f07f"
      az                      = "eu-west-2c"
      instance_type           = "t3.medium"
      server_function         = "ibi-ssrs"
      server_type             = "db"
      ami_id                  = "ami-06eb09971f4a1acdb"
      wsus_group              = "scan_only"
      wsus_qsid               = "QSConfigName-${local.wsus_qsconfig_id_ringscan}"
      wsus_policy_group       = "${local.wsus_policy_scan_only_name}"
      root_volume_size        = 50
      d_volume_size           = 50
      d_volume_throughput     = 125
      d_volume_iops           = 3000
      multithreading_enabled  = false
      rg = "aws-eweblogs"
    },
  ]

  wsus_qsconfig_id_ring1     = "74udy"
  wsus_qsconfig_id_ringscan  = "5883p"
  wsus_policy_scan_only_name = "ibi_ewbl_pol_wsus_scan_only"

### SGs ###
  delinea_cidr_block           = ["100.68.6.0/25"]
  ss_ad_cidr                   = ["100.68.36.176/28", "100.68.38.32/28"]
  wsus_cidr                    = ["100.68.39.32/28", "100.68.39.48/28"]
  bastion_generic_cidr         = ["100.68.52.0/27"]
  fsx_shares_cidr              = ["100.68.39.0/27"]
  hda_cidr                     = ["100.68.39.64/28"]
  sentryone_app_cidr           = ["100.68.36.64/32"]
  eng_sql_subnet_cidr          = ["100.68.32.32/27", "100.68.32.64/28"]
  nat_sql_subnet_cidr          = ["100.68.61.0/27", "100.68.61.32/28"]
  ss_sql_subnet_cidr           = ["100.68.37.64/26", "100.68.38.192/26", "100.68.37.128/27"]
  on_prem_sql_instance_cidr    = ["172.16.0.0/16", "192.168.0.0/16", "44.0.0.0/8"]
  r53_outbound_endpoint_subnet = ["100.88.8.128/26"]
  hscn_dns                     = ["155.231.231.1/32", "155.231.231.2/32"]

  bastion_sg_rules_cidr_blocks = {
    rule1 = { type = "ingress", from = 3389, to = 3389, protocol = "tcp", cidr = local.delinea_cidr_block,     desc = "Allow RDP in from Delinea Distributed Engine CIDR" }
  }

  route53_resolver_rules = {
    # dev_england_emis_web_com = {
    #   rule_id = "rslvr-rr-6cefc1a34e264c61b"
    # }
    dev_shared-services_emis-web_com = {
      rule_id = "rslvr-rr-4b6ebb37adf24a43b"
    }
    # dev_iom_emis_web_com = {
    #   rule_id = "rslvr-rr-aa135d6f2ba942caa"
    # }
  }

  sql_sg_rules_cidr_blocks    = {
    rule1   = { type = "egress",  from = 445,   to = 445,   protocol = "tcp", cidr = local.fsx_shares_cidr,           desc = "allow 445 to fsx subnets" }
    rule2   = { type = "egress",  from = 5985,  to = 5985,  protocol = "tcp", cidr = local.fsx_shares_cidr,           desc = "allow 5985 to fsx subnets" }
    rule5   = { type = "egress",  from = 1433,  to = 1433,  protocol = "tcp", cidr = local.eng_sql_subnet_cidr,       desc = "allow 1433 outbound to england sql subnets" }
    rule6   = { type = "egress",  from = 1433,  to = 1433,  protocol = "tcp", cidr = local.nat_sql_subnet_cidr,       desc = "allow 1433 outbound to nations sql subnets" }
    rule7   = { type = "egress",  from = 1433,  to = 1433,  protocol = "tcp", cidr = local.ss_sql_subnet_cidr,        desc = "allow 1433 outbound to shared services sql subnets" }
    rule8   = { type = "egress",  from = 1433,  to = 1433,  protocol = "tcp", cidr = local.on_prem_sql_instance_cidr, desc = "allow 1433 outbound to on-prem sql instances" }
    rule11  = { type = "ingress", from = 1433,  to = 1433,  protocol = "tcp", cidr = "${local.hda_cidr}",             desc = "Allow TCP 1433 inbound from HDA Subnets" }
    rule12  = { type = "ingress", from = 5985,  to = 5986,  protocol = "tcp", cidr = "${local.hda_cidr}",             desc = "Allow TCP 5985 to 5986 inbound from HDA Subnets" }
    rule13  = { type = "ingress", from = 1434,  to = 1434,  protocol = "udp", cidr = "${local.hda_cidr}",             desc = "Allow UDP 1434 inbound from HDA Subnets" }
    rule14  = { type = "ingress", from = 1433,  to = 1433,  protocol = "tcp", cidr = local.sentryone_app_cidr,        desc = "Allow tcp 1433 inbound from SentryOne APP Tier" }
  }

  standard_sg_rules_cidr_blocks = {
    rule1  = { type = "ingress", from = 443,   to = 443,   protocol = "tcp", cidr = concat(["${local.ipv4_primary_cidr_block}"]), desc = "allow 443 inbound from VPC CIDR" }
    rule2  = { type = "ingress", from = 53,    to = 53,    protocol = "udp", cidr = concat(["${local.ipv4_primary_cidr_block}"]), desc = "Allow DNS in from VPC CIDR" }
    rule3  = { type = "ingress", from = 53,    to = 53,    protocol = "udp", cidr = "${local.r53_outbound_endpoint_subnet}",      desc = "Allow DNS in from networks services route 53 resolver endpoint" }
    rule4  = { type = "ingress", from = 3389,  to = 3389,  protocol = "tcp", cidr = "${local.delinea_cidr_block}",                desc = "Allow RDP in from Delinea Distributed Engine CIDR" }
    rule5  = { type = "egress",  from = 53,    to = 53,    protocol = "udp", cidr = "${local.r53_outbound_endpoint_subnet}",      desc = "Allow DNS outbound to networks services route 53 resolver endpoint" }
    rule6  = { type = "egress",  from = 88,    to = 88 ,   protocol = "udp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow UDP 88 to Kerberos SS AD subnet" }
    rule7  = { type = "egress",  from = 88,    to = 88 ,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP 88 to Kerberos SS AD subnet" }
    rule8  = { type = "egress",  from = 135,   to = 135,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP 135 to RPC SS AD subnet" }
    rule9  = { type = "egress",  from = 139,   to = 139,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP 139 to NetBios SS AD subnet" }
    rule10 = { type = "egress",  from = 445,   to = 445,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP 445 to SMB SS AD subnet" }
    rule11 = { type = "egress",  from = 445,   to = 445,   protocol = "udp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow UDP 445 to SMB SS AD subnet" }
    rule12 = { type = "egress",  from = 389,  to = 389,    protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP 389 to LDAP SS AD subnet" }
    rule13 = { type = "egress",  from = 389,  to = 389,    protocol = "udp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow UDP 389 to LDAP SS AD subnet" }
    rule14 = { type = "egress",  from = 49152, to = 65535, protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP to apps SS AD subnet" }
    rule15 = { type = "egress",  from = 464,   to = 464,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP to AD SS AD subnet" }
    rule16 = { type = "egress",  from = 3268,  to = 3269,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP to AD SS AD subnet" }
    rule17 = { type = "egress",  from = 53,    to = 53,    protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP 53 to DNS SS AD subnet" }
    rule18 = { type = "egress",  from = 53,    to = 53,    protocol = "UDP", cidr = "${local.ss_ad_cidr}",                        desc = "Allow UDP 53 to DNS SS AD subnet" }
    rule19 = { type = "egress",  from = 636,   to = 636,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP ldaps to DNS SS AD subnet" }
    rule20 = { type = "egress",  from = 123,   to = 123,   protocol = "UDP", cidr = "${local.ss_ad_cidr}",                        desc = "Allow TCP NTP time sync to DNS SS AD subnet" }
    rule21 = { type = "ingress", from = 5985,  to = 5986,  protocol = "tcp", cidr = "${local.bastion_generic_cidr}",              desc = "Allow TCP 5985 from Generic Bastion Subnets" }
    rule22 = { type = "ingress", from = 135,   to = 135,   protocol = "tcp", cidr = "${local.bastion_generic_cidr}",              desc = "Allow TCP 135 from Generic Bastion Subnets" }
    rule23 = { type = "egress",  from = 8530,  to = 8531,  protocol = "tcp", cidr = "${local.wsus_cidr}",                         desc = "Allow TCP 8530 - 8531 to WSUS" }
    rule24 = { type = "egress",  from = 53,    to = 53,    protocol = "udp", cidr = "${local.hscn_dns}",                          desc = "Allow DNS outbound udp to HSCN" }
    rule25 = { type = "egress",  from = 53,    to = 53,    protocol = "tcp", cidr = "${local.hscn_dns}",                          desc = "Allow DNS outbound tcp to HSCN" }  
    rule26 = { type = "ingress", from = 5985,  to = 5986,  protocol = "tcp", cidr = local.ss_ad_cidr,                             desc = "allow 5985-5986 inbound from shared services m-ad subnets" }
    rule27 = { type = "ingress", from = 135,   to = 135,   protocol = "tcp", cidr = local.ss_ad_cidr,                             desc = "allow 135 inbound from shared services m-ad subnets" }
    rule28 = { type = "ingress", from = 0,     to = 65535, protocol = "udp", cidr = local.ss_ad_cidr,                             desc = "SQL dynamic UDP ports from Shared Services MAD subnets" }
    rule29 = { type = "ingress", from = 1430,  to = 1440,  protocol = "tcp", cidr = local.ss_ad_cidr,                             desc = "SQL standard ports from Shared Services MAD subnets" }
    rule30 = { type = "ingress", from = 49152, to = 65535, protocol = "tcp", cidr = local.ss_ad_cidr,                             desc = "Allow TCP Winmgmt from SS AD subnet" }
    rule31 = { type = "egress",  from = 443,   to = 443,   protocol = "tcp", cidr = ["0.0.0.0/0"],                                desc = "Allow all egress https traffic" }
  }

}