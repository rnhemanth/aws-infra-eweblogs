variable "environment" {
  type        = string
  description = "environment name i.e. dev/stg/prod"
}

variable "service" {
  type        = string
  description = "service name i.e eweblogs"
}

variable "service_identifier" {
  type        = string
  description = "service identifier i.e migration"
}

variable "ec2_name_prefix" {
  type        = string
  description = "Name prefix for the hostnames"
}

variable "region_prefix" {
  type        = string
  description = "region prefix to add to hostnames"
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

variable "kms_service" {
  description = "short service name for km key naming"
  type = string
  default = "eweb"
}

variable "wsus_qsconfig_id_ring1" {
  type        = string
  description = "WSUS quick setup config ID for ring 1"
}

variable "wsus_qsconfig_id_ringscan" {
  type        = string
  description = "WSUS quick setup config ID for ring scan only"
}

variable "servers" {
  type = list(object({
    name                    = string
    subnet_id               = string
    az                      = string
    instance_type           = string
    server_function         = string
    server_type             = string
    wsus_group              = string
    wsus_qsid               = string
    wsus_policy_group       = string
    ami_id                  = string
    root_volume_size        = optional(number)
    
    # D Drive (Data)
    d_volume_size           = optional(number)
    d_volume_throughput     = optional(number)  
    d_volume_iops           = optional(number)  
    
    # E Drive
    e_volume_size           = optional(number)
    e_volume_throughput     = optional(number)  
    e_volume_iops           = optional(number)  
    
    # F Drive - NEW
    f_volume_size           = optional(number)  
    f_volume_throughput     = optional(number)  
    f_volume_iops           = optional(number)  
    
    # G Drive - NEW
    g_volume_size           = optional(number)  
    g_volume_throughput     = optional(number)  
    g_volume_iops           = optional(number)  
    
    # H Drive - NEW
    h_volume_size           = optional(number)  
    h_volume_throughput     = optional(number)  
    h_volume_iops           = optional(number)  
    
    # I Drive - NEW
    i_volume_size           = optional(number)  
    i_volume_throughput     = optional(number)  
    i_volume_iops           = optional(number)  
    
    # J Drive - NEW
    j_volume_size           = optional(number)  
    j_volume_throughput     = optional(number)  
    j_volume_iops           = optional(number)  
    
    # K Drive - NEW
    k_volume_size           = optional(number)  
    k_volume_throughput     = optional(number)  
    k_volume_iops           = optional(number)  
    
    # L Drive (Logs)
    l_volume_size           = optional(number)
    l_volume_throughput     = optional(number)  
    l_volume_iops           = optional(number)  
    
    # M Drive - NEW
    m_volume_size           = optional(number)  
    m_volume_throughput     = optional(number)  
    m_volume_iops           = optional(number)  
    
    # N Drive - NEW
    n_volume_size           = optional(number)  
    n_volume_throughput     = optional(number)  
    n_volume_iops           = optional(number)  
    
    # O Drive - NEW
    o_volume_size           = optional(number)  
    o_volume_throughput     = optional(number)  
    o_volume_iops           = optional(number)  
    
    # Q Drive - NEW
    q_volume_size           = optional(number)  
    q_volume_throughput     = optional(number)  
    q_volume_iops           = optional(number)  

    # T Drive (Temp) - FIX NAMING
    t_volume_size           = optional(number)
    t_volume_throughput     = optional(number)  
    t_volume_iops           = optional(number)  
    

    lifecycle_tag           = optional(string)
    multithreading_enabled  = optional(bool)
    primary_ip              = optional(string)
    secondary_ip_1          = optional(string)
    secondary_ip_2          = optional(string)
    secondary_ip_3          = optional(string)
    eip_tag                 = optional(string)
    rg                      = optional(string)
  }))
  description = "details of server instances"
}

variable "ipv4_primary_cidr_block" {
  description = "(Optional) The IPv4 CIDR block for the VPC."
  type        = string
}

variable "sql_ag" {
  type        = bool
  description = "Is the DB part of a sql ag"
  default     = false
}

variable "security_groups" {
  description = "Map of security group configurations"
  type = map(object({
    sg_rules_cidr_blocks     = map(object({
      cidr      = list(string)
      desc      = string
      from      = number
      protocol  = string
      to        = number
      type      = string
    }))
    sg_rules_self            = map(object({
      self      = bool
      desc      = string
      from      = number
      protocol  = string
      to        = number
      type      = string
    }))
  }))
  default = {}
}

variable "name" {
  type = object({
    environment = string
    service     = string
    identifier  = string
  })
  description = "environment, service and identifier, part of naming standards"
}

variable "jit_access" {
  type    = string
  default = ""
}
