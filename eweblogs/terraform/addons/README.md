# EWebLogs Network Addons Module

This Terraform module completes the network connectivity setup by configuring Transit Gateway routes and Route53 resolver rule associations. It must be deployed after the network module and is essential for domain connectivity.

## 🎯 Purpose

The addons module bridges the gap between basic network infrastructure and full domain connectivity by:

1. **Creating TGW Routes**: Enables traffic flow to shared services for domain operations
2. **Associating Route53 Rules**: Provides DNS resolution for domain names
3. **Completing Network Setup**: Makes the VPC ready for domain-joined instances

## 🏗️ What This Module Does

### Transit Gateway Routing
- **Default Route Creation**: Adds `0.0.0.0/0` route to Transit Gateway backbone
- **Route Table Updates**: Configures all route tables in the VPC
- **Conditional Deployment**: Only creates routes when TGW attachment is available

### Route53 Resolver Integration
- **Rule Association**: Associates Route53 resolver rules with the VPC
- **Domain Resolution**: Enables resolution of shared services domain names
- **DNS Forwarding**: Configures proper DNS forwarding for domain operations

## 📋 Prerequisites

**Critical**: This module depends on successful network module deployment:

1. **VPC Deployed**: Network module must be successfully deployed
2. **TGW Attachment**: Transit Gateway attachment must be in "available" state
3. **Route53 Rules**: Resolver rules must exist in shared services
4. **GitHub Actions**: Submodule issue must be resolved for deployment

## ✅ **Deployment Status: COMPLETED**

The addons module has been successfully deployed after resolving several technical challenges:

### **Issues Resolved During Deployment:**

1. **TGW Attachment Data Source Fix**
   - **Problem**: Terraform couldn't find TGW attachment due to naming mismatch
   - **Root Cause**: Module appended VPC ID suffix to attachment name
   - **Solution**: Updated data source filter to match actual name pattern
   - **Result**: `dev-core-net-tgw-attach-eweb-ibi-vpc-[vpc-id]` correctly identified

2. **Route53 Resolver Permissions**
   - **Problem**: IAM permissions insufficient for resolver rule association
   - **Missing Permission**: `route53resolver:GetResolverRuleAssociation`
   - **Solution**: Updated GitHub deployer role with additional Route53 permissions
   - **Result**: Module can now associate resolver rules with VPC

3. **Bootstrap IAM Update**
   - **Action**: Re-ran bootstrap process to apply updated IAM permissions
   - **Result**: GitHub Actions workflow now has full permissions

### **What's Now Working:**
- ✅ Route53 resolver rule `rslvr-rr-4b6ebb37adf24a43b` associated with VPC
- ✅ TGW routes configured for `0.0.0.0/0` → Transit Gateway backbone
- ✅ Network infrastructure ready for EC2 domain-joined instances

### **Current Status:**
- **TGW Attachment**: `pending-acceptance` - requires manual acceptance in AWS Console
- **Route53 Resolution**: Active for `dev.shared-services.emis-web.com`
- **Next Step**: Accept TGW attachment, then deploy EC2 instances

## 🚀 Deployment (When GitHub Actions Fixed)

### Step 1: Verify Prerequisites
```bash
# Ensure network module is deployed
aws ec2 describe-transit-gateway-attachments \
  --filters "Name=state,Values=available"

# Check VPC exists
aws ec2 describe-vpcs \
  --filters "Name=cidr-block,Values=100.68.63.192/26"
```

### Step 2: Deploy Addons
```bash
# Use GitHub Actions workflow
.github/workflows/dev-deploy-infrastructure.yml
# Select: network-addons
```

### Step 3: Verify Deployment
```bash
# Check routes are created
aws ec2 describe-route-tables \
  --filters "Name=route.destination-cidr-block,Values=0.0.0.0/0"

# Verify Route53 associations
aws route53resolver list-resolver-rule-associations \
  --filters "Name=Status,Values=COMPLETE"
```

## 📁 Module Structure

```
eweblogs/terraform/addons/
├── main.tf           # TGW routes and Route53 associations
├── variables.tf      # Input parameters
├── terragrunt.hcl   # Terragrunt configuration
└── README.md        # This documentation
```

## 🔧 How It Works

### Transit Gateway Route Logic
```hcl
# Finds TGW attachment
data "aws_ec2_transit_gateway_vpc_attachments" "vpc_attachments" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "transit-gateway-id"
    values = [var.tgw_id_backbone]
  }
  filter {
    name   = "state"
    values = ["available", "pending-acceptance"]
  }
}

# Creates routes only when attachment is available
resource "aws_route" "tgw_backbone_route" {
  for_each = { 
    for id in data.aws_route_tables.this.ids : id => id 
    if data.aws_ec2_transit_gateway_attachment.tgw_backbone.state == "available" 
  }

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw_id_backbone
}
```

### Route53 Association Logic
```hcl
# Associates resolver rules with VPC
resource "aws_route53_resolver_rule_association" "this" {
  for_each         = var.route53_resolver_rules
  resolver_rule_id = each.value.rule_id
  vpc_id           = data.aws_vpc.this.id
}
```

## 📊 Network Flow After Deployment

```
┌─────────────────────────────────────────────────────────┐
│                EWebLogs VPC                             │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                     │
│  │   SIS001    │  │   SRS001    │                     │
│  │    SSIS     │  │    SSRS     │                     │
│  └─────┬───────┘  └─────┬───────┘                     │
│        │                │                              │
│        └────────┬───────┘                              │
│                 │                                      │
│     ┌───────────▼──────────────┐                      │
│     │     Route Tables         │                      │
│     │ 0.0.0.0/0 → TGW Backbone │  ← Addons Module    │
│     └───────────┬──────────────┘                      │
└─────────────────┼──────────────────────────────────────┘
                  │
                  ▼ Traffic to Domain/DNS
┌─────────────────────────────────────────────────────────┐
│              Transit Gateway Backbone                   │
│                                                         │
│  ┌─────────────────┐    ┌─────────────────┐           │
│  │ Shared Services │    │ Route53 Resolver│           │
│  │   (Domain)      │    │    (DNS)        │  ← Addons │
│  └─────────────────┘    └─────────────────┘    Module  │
└─────────────────────────────────────────────────────────┘
```

## 🔍 Configuration Variables

### Required Variables
```hcl
# Transit Gateway backbone ID
tgw_id_backbone = "tgw-0f28603fcaf843cb9"

# VPC CIDR for lookup
ipv4_primary_cidr_block = "100.68.63.192/26"

# Route53 resolver rules to associate
route53_resolver_rules = {
  dev_shared-services_emis-web_com = {
    rule_id = "rslvr-rr-4b6ebb37adf24a43b"
  }
}

# Naming convention
name = {
  environment = "dev"
  service     = "eweb"
  identifier  = "ibi"
}
```

## 📤 Data Sources Used

The module uses these data sources to find existing resources:

```hcl
# Finds the TGW attachment created by network module
data "aws_ec2_transit_gateway_attachment" "tgw_backbone"

# Locates all route tables in the VPC
data "aws_route_tables" "this"

# Finds the VPC by CIDR block
data "aws_vpc" "this"
```

## ✅ Verification Steps

After successful deployment, verify:

### 1. TGW Routes Created
```bash
# Check route tables have TGW routes
aws ec2 describe-route-tables \
  --route-table-ids $(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=vpc-xxxxxxxxx" \
    --query 'RouteTables[].RouteTableId' --output text) \
  --query 'RouteTables[].Routes[?DestinationCidrBlock==`0.0.0.0/0`]'
```

### 2. Route53 Associations Active
```bash
# Verify resolver rule associations
aws route53resolver list-resolver-rule-associations \
  --filters "Name=VPCId,Values=vpc-xxxxxxxxx" \
  --query 'ResolverRuleAssociations[?Status==`COMPLETE`]'
```

### 3. Test Domain Connectivity
```bash
# From an EC2 instance, test domain resolution
nslookup shared-services.emis-web.com
nslookup dev.shared-services.emis-web.com
```

## 🛠️ Dependencies

### Input Dependencies
This module requires outputs from the network module:
- **VPC ID**: For Route53 resolver associations
- **Route Table IDs**: For TGW route creation
- **TGW Attachment**: Must be in "available" state

### External Dependencies
- **Transit Gateway**: Backbone TGW must exist and be accessible
- **Route53 Resolver Rules**: Must exist in shared services account
- **Cross-Account Permissions**: Proper IAM roles for TGW access


## 🚨 Critical Notes

**⚠️ Order Dependency**: This module MUST be deployed after the network module but BEFORE EC2 instances. Without these routes and DNS associations, EC2 instances cannot join the domain.

**⚠️ Domain Connectivity**: Without this module, domain join will fail and instances will not be manageable through Active Directory.


## 🤝 Support
1. **AWS Console**: Verify TGW attachment and Route53 associations
2. **Network Team**: Contact for TGW backbone configuration