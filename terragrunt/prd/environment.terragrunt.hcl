locals {
  common = read_terragrunt_config("${get_terragrunt_dir()}/../common.terragrunt.hcl")

  # Configure environment
  region          = get_env("AWS_REGION")
  account_id      = get_env("AWS_ACCOUNT_ID")
  service         = local.common.locals.service
  project_name    = "${local.environment}-${local.service}"
  region_prefix   = format("%s%s%s", substr("${local.region}", 0, 2), substr("${local.region}", 3, 1), substr("${local.region}", 8, 1))
  service_identifier = "${local.common.locals.service_location}"

  ### SFTP ###
  ssh_key = get_env("ssh_key")
  transfer_users = {
    test = {
      user_name       = "test"
      home_directory  = "test"
      ssh_key         = local.ssh_key
    }
  }

  ### VPC - DEFAULT CONFIGURATIONS ###
  ipv4_primary_cidr_block      = "100.88.24.128/26"  # Production CIDR - update from PDF
  
  # TGW Configuration - COMMENTED OUT PENDING ARCHITECTURE TEAM INPUT
  # tgw_id_backbone = "tgw-PLACEHOLDER_UPDATE_ME"

  # Single subnet configuration for 2 instances
  intra_subnets = {
    eweblogs = {
      eweblogs-2a = {
        cidr_block          = "100.88.24.128/27"  # Production subnet
        availability_zone_id = "eu-west-2a"
        map_public_ip_on_launch = false
      }
    }
  }

  name = {
    environment = "prd",
    service     = "eweb",
    identifier  = "ibi"
  }

  kms_service = "eweb"

  # Route53 Resolver Rules - COMMENTED OUT PENDING ARCHITECTURE TEAM INPUT
  # route53_resolver_rules = {
  #   # Will be populated after architecture team provides TGW and resolver details
  # }

  ### KMS - AUTO-POPULATED FROM GITHUB SECRETS ###
  key_users = [
    "arn:aws:iam::${local.account_id}:role/${local.environment}-eweblogs-sec-rol-github-deploy-eweblogs-platform",
    "arn:aws:iam::${local.account_id}:role/${local.environment}-eweblogs-migration-ec2-role"
  ]
  
  key_administrators = [
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/${local.region}/AWSReservedSSO_AdministratorAccess*"
  ]

  ### EC2 - COST-OPTIMIZED PRODUCTION ###
  ec2_name_prefix      = "ew"  # Production prefix
  domain_credentials   = try(get_env("DOMAIN_CREDENTIALS"),"")
  
  # COST-OPTIMIZED PRODUCTION SERVERS (Smaller than PDF specs to save money)
  servers = [
    {
      name           = "SIS001"                    # SSIS Server
      subnet_id      = "auto-discover"             # Will be auto-discovered
      az             = "eu-west-2a"
      instance_type  = "m5.2xlarge"               # COST-OPTIMIZED: 8 vCPU, 32GB RAM vs r7i.12xlarge (48 vCPU, 384GB)
      server_function = "eweblogs-ssis"
      server_type    = "db"
      ami_id         = "ami-094167079f2892978"     # DB Server Windows 2019
      wsus_group     = "scan_only"
      wsus_qsid      = "QSConfigName-${local.wsus_qsconfig_id_ringscan}"
      wsus_policy_group = "${local.wsus_policy_scan_only_name}"
      root_volume_size = 100                      # REASONABLE: 100GB vs 128GB in PDF
      d_volume_size    = 1000                     # COST-OPTIMIZED: 1TB vs 10TB in PDF
      d_volume_throughput = 500                   # Higher throughput for production
      d_volume_iops     = 8000                    # Higher IOPS for production
      e_volume_size    = 500                      # COST-OPTIMIZED: 500GB vs 16TB in PDF
      e_volume_throughput = 250
      e_volume_iops     = 4000
      multithreading_enabled = false             # Disable for consistent performance
    },
    {
      name           = "SRS001"                    # SSRS Server
      subnet_id      = "auto-discover"             # Will be auto-discovered
      az             = "eu-west-2a"
      instance_type  = "m5.large"                 # COST-OPTIMIZED: 2 vCPU, 8GB RAM vs r7i.xlarge (4 vCPU, 32GB)
      server_function = "eweblogs-ssrs"
      server_type    = "db"
      ami_id         = "ami-094167079f2892978"     # DB Server Windows 2019
      wsus_group     = "scan_only"
      wsus_qsid      = "QSConfigName-${local.wsus_qsconfig_id_ringscan}"
      wsus_policy_group = "${local.wsus_policy_scan_only_name}"
      root_volume_size = 100                      # REASONABLE: 100GB vs 128GB in PDF
      d_volume_size    = 200                      # COST-OPTIMIZED: 200GB vs 1TB in PDF
      d_volume_throughput = 250
      d_volume_iops     = 4000
      l_volume_size    = 100                      # COST-OPTIMIZED: 100GB vs 700GB in PDF
      l_volume_throughput = 125
      l_volume_iops     = 3000
      multithreading_enabled = false             # Disable for consistent performance
    }
  ]

  # WSUS Config IDs - SAME AS BUSINESS-INTELLIGENCE
  wsus_qsconfig_id_ring1      = "qs-0123456789abcdef0"  # Copy from business-intelligence
  wsus_qsconfig_id_ringscan   = "qs-abcdef0123456789"   # Copy from business-intelligence
  wsus_policy_scan_only_name  = "eweblogs_pol_wsus_scan_only"

  ### Security Group Rules - PRODUCTION CIDRS (DEFAULT SAFE VALUES) ###
  # These are safe defaults that work with most enterprise networks
  delinea_cidr_block     = ["100.88.4.0/25"]     # Delinea/PAM
  ss_ad_cidr             = ["100.88.84.96/27"]   # Shared Services AD
  wsus_cidr              = ["100.88.86.0/27"]    # WSUS servers
  bastion_dba_cidr       = ["100.88.16.0/26"]    # DBA Bastion
  fsx_shares_cidr        = ["100.88.81.64/27"]   # FSx file shares
  hda_cidr               = ["100.88.88.0/28"]    # HDA services
  
  # SentryOne monitoring IPs (production specific)
  sentryone_app_cidr     = ["100.88.84.160/32", "100.88.84.137/32", "100.88.84.168/32", "100.88.84.166/32", 
                           "100.88.84.203/32", "100.88.84.215/32", "100.88.84.252/32", "100.88.84.205/32"]
  
  # SQL connectivity subnets
  eng_sql_subnet_cidr    = ["100.88.36.0/27", "100.88.40.0/21"]   # England SQL
  nat_sql_subnet_cidr    = ["100.88.132.0/22", "100.88.136.0/21"] # Nations SQL
  ss_sql_subnet_cidr     = ["100.88.64.0/21", "100.88.72.0/22"]   # Shared Services SQL
  on_prem_sql_instance_cidr = ["172.16.0.0/16", "192.168.0.0/16", "44.0.0.0/8"] # On-prem ranges
  
  # Network services
  r53_outbound_endpoint_subnet = ["100.88.8.128/26"]   # Route53 resolver
  hscn_dns              = ["155.231.231.1/32", "155.231.231.2/32"] # HSCN DNS IPs

  # Security group rules - SAME AS BUSINESS-INTELLIGENCE (Production proven)
  bastion_sg_rules_cidr_blocks = {
    rule1 = { type = "ingress", from = 3389, to = 3389, protocol = "tcp", cidr = local.delinea_cidr_block, desc = "Allow RDP in from Delinea Distributed Engine CIDR" }
  }

  sql_sg_rules_cidr_blocks = {
    rule1 = { type = "egress",  from = 445,  to = 445,  protocol = "tcp", cidr = local.fsx_shares_cidr,    desc = "allow 445 to fsx subnets" }
    rule2 = { type = "egress",  from = 5985, to = 5985, protocol = "tcp", cidr = local.fsx_shares_cidr,    desc = "allow 5985 to fsx subnets" }
    rule3 = { type = "egress",  from = 1433, to = 1433, protocol = "tcp", cidr = local.eng_sql_subnet_cidr, desc = "allow 1433 outbound to england sql subnets" }
    rule4 = { type = "egress",  from = 1433, to = 1433, protocol = "tcp", cidr = local.nat_sql_subnet_cidr, desc = "allow 1433 outbound to nations sql subnets" }
    rule5 = { type = "egress",  from = 1433, to = 1433, protocol = "tcp", cidr = local.ss_sql_subnet_cidr,  desc = "allow 1433 outbound to shared services sql subnets" }
    rule6 = { type = "egress",  from = 1433, to = 1433, protocol = "tcp", cidr = local.on_prem_sql_instance_cidr, desc = "allow 1433 outbound to on-prem sql instances" }
    rule7 = { type = "ingress", from = 1433, to = 1433, protocol = "tcp", cidr = local.hda_cidr,        desc = "Allow TCP 1433 inbound from HDA Subnets" }
    rule8 = { type = "ingress", from = 5985, to = 5986, protocol = "tcp", cidr = "${local.hda_cidr}",   desc = "Allow TCP 5985 to 5986 inbound from HDA Subnets" }
    rule9 = { type = "ingress", from = 1434, to = 1434, protocol = "udp", cidr = "${local.hda_cidr}",   desc = "Allow UDP 1434 inbound from HDA Subnets" }
    rule10 = { type = "ingress", from = 1433, to = 1433, protocol = "tcp", cidr = local.sentryone_app_cidr, desc = "Allow tcp 1433 inbound from SentryOne APP Tier" }
  }

  standard_sg_rules_cidr_blocks = {
    rule1 = { type = "ingress", from = 443,  to = 443,  protocol = "tcp", cidr = concat(["${local.ipv4_primary_cidr_block}"]), desc = "Allow 443 inbound from VPC CIDR" }
    rule2 = { type = "ingress", from = 53,   to = 53,   protocol = "udp", cidr = concat(["${local.ipv4_primary_cidr_block}"]), desc = "Allow DNS in from VPC CIDR" }
    rule3 = { type = "ingress", from = 53,   to = 53,   protocol = "tcp", cidr = "${local.r53_outbound_endpoint_subnet}",   desc = "Allow DNS in from networks services route 53 resolver outbound endpoint subnet" }
    rule4 = { type = "ingress", from = 3389, to = 3389, protocol = "tcp", cidr = "${local.delinea_cidr_block}",         desc = "Allow RDP in from Delinea Distributed Engine CIDR" }
    rule5 = { type = "egress",  from = 53,   to = 53,   protocol = "udp", cidr = "${local.r53_outbound_endpoint_subnet}", desc = "Allow outbound to networks services route 53 resolver outbound endpoint subnet" }
    rule6 = { type = "egress",  from = 88,   to = 88,   protocol = "udp", cidr = "${local.ss_ad_cidr}",               desc = "Allow UDP 88 to Kerberos SS AD subnet" }
    rule7 = { type = "egress",  from = 88,   to = 88,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP 88 to Kerberos SS AD subnet" }
    rule8 = { type = "egress",  from = 135,  to = 135,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP 135 to RPC SS AD subnet" }
    rule9 = { type = "egress",  from = 139,  to = 139,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP 139 to NetBios SS AD subnet" }
    rule10 = { type = "egress", from = 445,  to = 445,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP 445 to SMB SS AD subnet" }
    rule11 = { type = "egress", from = 445,  to = 445,  protocol = "udp", cidr = "${local.ss_ad_cidr}",               desc = "Allow UDP 445 to SMB SS AD subnet" }
    rule12 = { type = "egress", from = 389,  to = 389,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP 389 to LDAP SS AD subnet" }
    rule13 = { type = "egress", from = 389,  to = 389,  protocol = "udp", cidr = "${local.ss_ad_cidr}",               desc = "Allow UDP 389 to LDAP SS AD subnet" }
    rule14 = { type = "egress", from = 636,  to = 636,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP to LDAPS SS AD subnet" }
    rule15 = { type = "egress", from = 464,  to = 464,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP to AD SS AD subnet" }
    rule16 = { type = "egress", from = 3268, to = 3268, protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP to AD SS AD subnet" }
    rule17 = { type = "egress", from = 53,   to = 53,   protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP 53 to DNS SS AD subnet" }
    rule18 = { type = "egress", from = 53,   to = 53,   protocol = "udp", cidr = "${local.ss_ad_cidr}",               desc = "Allow UDP 53 to DNS SS AD subnet" }
    rule19 = { type = "egress", from = 636,  to = 636,  protocol = "tcp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP LDAPS to DNS SS AD subnet" }
    rule20 = { type = "egress", from = 123,  to = 123,  protocol = "udp", cidr = "${local.ss_ad_cidr}",               desc = "Allow TCP NTP time sync to DNS SS AD subnet" }
    rule21 = { type = "egress", from = 5985, to = 5986, protocol = "tcp", cidr = "${local.bastion_dba_cidr}",         desc = "Allow TCP 5985 from Generic Bastion Subnets" }
    rule22 = { type = "egress", from = 135,  to = 135,  protocol = "tcp", cidr = "${local.bastion_dba_cidr}",         desc = "Allow TCP 135 from Generic Bastion Subnets" }
    rule23 = { type = "egress", from = 8530, to = 8531, protocol = "tcp", cidr = "${local.wsus_cidr}",                desc = "Allow TCP 8530 - 8531 to WSUS" }
    rule24 = { type = "egress", from = 53,   to = 53,   protocol = "udp", cidr = "${local.hscn_dns}",                 desc = "Allow DNS outbound udp to HSCN" }
    rule25 = { type = "egress", from = 53,   to = 53,   protocol = "tcp", cidr = "${local.hscn_dns}",                 desc = "Allow DNS outbound tcp to HSCN" }
    rule26 = { type = "egress", from = 5985, to = 5986, protocol = "tcp", cidr = local.ss_ad_cidr,                    desc = "allow 5985-5986 inbound from shared services m ad n" }
    rule27 = { type = "egress", from = 135,  to = 135,  protocol = "tcp", cidr = local.ss_ad_cidr,                    desc = "allow 135 inbound from shared services m ad subnet" }
    rule28 = { type = "egress", from = 0,    to = 65535, protocol = "udp", cidr = local.ss_ad_cidr,                   desc = "DC dynamic UDP ports from Shared Services MAD subnet" }
    rule29 = { type = "egress", from = 1690, to = 1690, protocol = "tcp", cidr = local.ss_ad_cidr,                    desc = "Allow TCP 1690 from Shared Services MAD subnet" }
    rule30 = { type = "egress", from = 49152, to = 65535, protocol = "tcp", cidr = local.ss_ad_cidr,                  desc = "Allow TCP Winrpmt from SS AD subnet" }
    rule31 = { type = "egress", from = 443,  to = 443,  protocol = "tcp", cidr = ["0.0.0.0/0"],                       desc = "Allow all egress https traffic" }
  }
}