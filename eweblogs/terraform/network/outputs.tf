output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = module.vpc.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "vpc_owner_id" {
  description = "The ID of the AWS account that owns the VPC"
  value       = module.vpc.vpc_owner_id
}

output "public_subnet_ids" {
  description = "A list of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "public_route_table_id" {
  description = "Public subnet route table ID"
  value       = module.vpc.public_route_table_id
}

output "public_subnet_id_map" {
  description = "A map of public subnet IDs using the AZ as the key"
  value       = module.vpc.public_subnet_id_map
}

output "public_subnet_arn_map" {
  description = "A map of public subnet ARNS using the AZ as the key"
  value       = module.vpc.public_subnet_arn_map
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_arns" {
  description = "Private Subnet ARNs"
  value       = module.vpc.private_subnet_arns
}

output "private_subnet_ip_map" {
  description = "Private Subnet Map"
  value       = module.vpc.private_subnet_ip_map
}

output "private_route_table_ids" {
  description = "Private Subnet Route Table IDs"
  value       = module.vpc.private_route_table_ids
}

output "private_route_table_azs" {
  description = "A map of private subnets availablity zones"
  value       = module.vpc.private_route_table_azs
}

output "intra_subnet_ids" {
  description = "Intra Subnet IDs"
  value       = module.vpc.intra_subnet_ids
}

output "intra_subnet_arns" {
  description = "Intra Subnet ARNs"
  value       = module.vpc.intra_subnet_arns
}

output "intra_subnet_ip_map" {
  description = "Intra Subnet Map"
  value       = module.vpc.intra_subnet_ip_map
}

output "intra_route_table_ids" {
  description = "Intra Subnet Route Table IDs"
  value       = module.vpc.intra_route_table_ids
}

output "intra_route_table_azs" {
  description = "A map of intra subnets availablity zones"
  value       = module.vpc.intra_route_table_azs
}

output "dhcp_options_id" {
  description = "The ID of the DHCP options"
  value       = module.vpc.dhcp_options_id
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

# VPC flow log
output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "vpc_flow_log_destination_type" {
  description = "The type of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_type
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "azs_map" {
  value = module.vpc.azs_map
}

output "vpc_endpoints" {
  description = "Array containing all resource objects and attributes for all endpoints created"
  value       = module.vpc_endpoints.endpoints
}

#output "transit_gateway_attachments" {
#  description = "Map of transit gateway attachments."
#  value       = module.transit_gateway_attachment.transit_gateway_attachments
#}

/* output "vpc_peering_ids" {
  description = "Map of vpc peering attachments."
  value       = module.vpc_peering[*].vpc_peering_ids
} */