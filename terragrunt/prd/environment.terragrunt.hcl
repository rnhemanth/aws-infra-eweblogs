locals {
  common = read_terragrunt_config("${get_terragrunt_dir()}/../common.terragrunt.hcl")

  # Configure environment
  region          = get_env("AWS_REGION")
  account_id      = get_env("AWS_ACCOUNT_ID")
  environment     = get_env("ENVIRONMENT")
  service         = local.common.locals.service
  project_name    = "${local.environment}-${local.service}"
  region_prefix   = format("%s%s%s", substr("${local.region}", 0, 2), substr("${local.region}", 3, 1), substr("${local.region}", 8, 1))
  service_identifier = "${local.common.locals.service_location}"
  jit_access         = "gen-developer-full"

  /*
  ### SFTP ###
  ssh_key = get_env("ssh_key")
  transfer_users = {
    test = {
      user_name       = "test"
      home_directory  = "test"
      ssh_key         = local.ssh_key
    }
  }
  */

  ### VPC - DEFAULT CONFIGURATIONS ###
  ipv4_primary_cidr_block      = "100.88.24.128/26"  # Production CIDR - update from confluence
  
  # TGW Configuration 
  tgw_id_backbone = "tgw-0f28603fcaf843cb9"

  # Single subnet configuration for 2 instances
  intra_subnets = {
    ewl = {
      ewl-2a = {
        cidr_block          = "100.88.24.128/27"  # Production subnet
        availability_zone_id = "euw2-az1"
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

  # Route53 Resolver Rules

  route53_resolver_rules = {
    prd_england_emis_web_com = {
      rule_id = "rslvr-rr-80152c982c564b66b"
    }
    analytics1 = {
      rule_id = "rslvr-rr-a7fecadc99a427b9e"
    }
    ccmh = {
      rule_id = "rslvr-rr-94e332794c0e4b698"
    }
    gplive = {
      rule_id = "rslvr-rr-9034c75c4cf140de8"
    }
    white = {
      rule_id = "rslvr-rr-bc9a029abd864d828"
    }
    emishosting = {
      rule_id = "rslvr-rr-c991720e03ad4d56a"
    }
    emishome = {
      rule_id = "rslvr-rr-5f337ace7b014f3fb"
    }
    hscn_catch_all = {
      rule_id = "rslvr-rr-c233db4579f54d369"
    }
    shared_services = {
      rule_id = "rslvr-rr-2ca09cef339c4cedb"
    }
    hscni = {
      rule_id = "rslvr-rr-f871cf10594b4339a"
    }
    hscninet = {
      rule_id = "rslvr-rr-bbb34f8986634178b"
    }
    iom = {
      rule_id = "rslvr-rr-8b829e0e495440bf9"
    }
    jersey = {
      rule_id = "rslvr-rr-2900e554858743a6b"
    }
    cp = {
      rule_id = "rslvr-rr-3a698c3f20434754b"
    }
    prod_iom_emis_web_com = {
      rule_id = "rslvr-rr-1da8e8c0d7484cf79"
    }   
    prod_scotland_emis_web_com = {
      rule_id = "rslvr-rr-9ad8081235d246a5b"
    }
    prod_northernireland_emis_web_com = {
      rule_id = "rslvr-rr-efe83ae95304dafb8"
    }
    prod_jersey_emis_web_com = {
      rule_id = "rslvr-rr-f9f52acb83a441df8"
    }
    awshosted_emis-clinical_com = {
      rule_id = "rslvr-rr-1e7f598835214f529"
    }
  }

  ### KMS - AUTO-POPULATED FROM GITHUB SECRETS ###
  key_users = [
    "arn:aws:iam::${local.account_id}:role/${local.environment}-eweblogs-sec-rol-github-deploy-eweblogs-platform",
  # "arn:aws:iam::${local.account_id}:role/${local.environment}-eweblogs-migration-ec2-role"
  ]
  
  key_administrators = [
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/${local.region}/AWSReservedSSO_AdministratorAccess*"
  ]

  ### EC2###
  ec2_name_prefix      = "em"  # Production prefix
  domain_credentials   = try(get_env("DOMAIN_CREDENTIALS"),"")
  servers = [
  {
    name                    = "SIS01"                    # SSIS Server (SQL 2019)
    subnet_id               = "auto-discover"             # Still need to update this
    az                      = "eu-west-2a"
    instance_type           = "r7i.12xlarge"             # 48 cores, 384GB RAM
    server_function         = "eweblogs-ssis"
    server_type             = "db"
    ami_id                  = "ami-04a5e298fa2b15f9c"     # SQL Standard AMI
    wsus_group              = "scan_only"
    wsus_qsid               = "QSConfigName-${local.wsus_qsconfig_id_ringscan}"
    wsus_policy_group       = "${local.wsus_policy_scan_only_name}"
    root_volume_size        = 128                        # OS Disk: 128GB
    
    # D: Drive - 10TB
    d_volume_size           = 10240                      # 10TB = 10,240GB
    d_volume_throughput     = 1000                       # Max throughput
    d_volume_iops           = 16000                      # Max IOPS
    
    # E: Drive - 16TB  
    e_volume_size           = 16384                      # 16TB = 16,384GB
    e_volume_throughput     = 1000
    e_volume_iops           = 16000
    
    # F: Drive - 5TB
    f_volume_size           = 5120                       # 5TB = 5,120GB
    f_volume_throughput     = 1000
    f_volume_iops           = 16000
    
    # G: Drive - 15TB
    g_volume_size           = 15360                      # 15TB = 15,360GB
    g_volume_throughput     = 1000
    g_volume_iops           = 16000
    
    # H: Drive - 5TB
    h_volume_size           = 5120                       # 5TB = 5,120GB
    h_volume_throughput     = 1000
    h_volume_iops           = 16000
    
    # I: Drive - 15TB
    i_volume_size           = 15360                      # 15TB = 15,360GB
    i_volume_throughput     = 1000
    i_volume_iops           = 16000
    
    # J: Drive - 5TB
    j_volume_size           = 5120                       # 5TB = 5,120GB
    j_volume_throughput     = 1000
    j_volume_iops           = 16000
    
    # K: Drive - 15TB
    k_volume_size           = 15360                      # 15TB = 15,360GB
    k_volume_throughput     = 1000
    k_volume_iops           = 16000
    
    # L: Drive - 2TB
    l_volume_size           = 2048                       # 2TB = 2,048GB
    l_volume_throughput     = 500
    l_volume_iops           = 8000
    
    # M: Drive - 3TB
    m_volume_size           = 3072                       # 3TB = 3,072GB
    m_volume_throughput     = 500
    m_volume_iops           = 8000
    
    # N: Drive - 15TB
    n_volume_size           = 15360                      # 15TB = 15,360GB
    n_volume_throughput     = 1000
    n_volume_iops           = 16000
    
    # O: Drive - 14TB
    o_volume_size           = 14336                      # 14TB = 14,336GB
    o_volume_throughput     = 1000
    o_volume_iops           = 16000
    
    multithreading_enabled  = false                     # Hyperthreading disabled
    rg                      = "aws-eweblogs"
  },
  {
    name                    = "SRS01"                    # SSRS Server
    subnet_id               = "auto-discover"             # Still need to update this
    az                      = "eu-west-2a"
    instance_type           = "r7i.xlarge"               # 4 cores, 32GB RAM
    server_function         = "eweblogs-ssrs"
    server_type             = "db"
    ami_id                  = "ami-04a5e298fa2b15f9c"     # SQL Standard AMI
    wsus_group              = "scan_only"
    wsus_qsid               = "QSConfigName-${local.wsus_qsconfig_id_ringscan}"
    wsus_policy_group       = "${local.wsus_policy_scan_only_name}"
    root_volume_size        = 128                        # OS Disk: 128GB
    
    # D: Drive - 1TB
    d_volume_size           = 1024                       # 1TB = 1,024GB
    d_volume_throughput     = 500
    d_volume_iops           = 8000
    
    multithreading_enabled  = false                     # Hyperthreading disabled
    rg                      = "aws-eweblogs"
  }
]


  # WSUS Config IDs - SAME AS BUSINESS-INTELLIGENCE
  wsus_qsconfig_id_ring1      = "qubhi"  # Same as business-intelligence
  wsus_qsconfig_id_ringscan   = "85ycu"   # Same as business-intelligence
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
