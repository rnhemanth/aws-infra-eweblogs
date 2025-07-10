# EWebLogs Network Infrastructure Module

This Terraform module creates the foundational network infrastructure for the EWebLogs platform, including VPC, subnets, security groups, and connectivity components.

## 🏗️ What This Module Creates

### Core Networking
- **VPC**: Isolated network environment with DNS support
- **Subnets**: Private subnets for secure instance placement
- **Route Tables**: Routing configuration for traffic flow
- **DHCP Options**: Custom DNS and domain configuration
- **Flow Logs**: Network traffic monitoring and security

### Connectivity
- **Transit Gateway Attachment**: Connection to backbone TGW for domain services
- **VPC Endpoints**: Private AWS service access (S3, SSM, EC2, KMS, Secrets Manager)
- **DNS Configuration**: Integration with shared services domain resolution

### Security
- **Security Groups**: Network-level security controls
  - Standard ports (common services)
  - Bastion access (administrative)
  - SQL connectivity (database services)
- **KMS Keys**: Encryption for infrastructure components
- **Network ACLs**: Additional network security layer

### Storage & Secrets
- **S3 Buckets**: Setup files and software distribution
- **Secrets Manager**: Domain credentials for cross-account access
- **SSM Parameters**: Configuration values for other modules

## 📋 Network Design

### CIDR Allocation
- **VPC CIDR**: `100.68.63.192/26` (64 total IPs)
- **Subnet**: `100.68.63.192/27` (32 usable IPs)
- **Availability Zone**: `eu-west-2c` (euw2-az1)

### Connectivity Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    EWebLogs VPC                         │
│                100.68.63.192/26                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         ewl-2a Subnet                           │   │
│  │      100.68.63.192/27                          │   │
│  │                                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │   SIS001    │  │   SRS001    │             │   │
│  │  │    SSIS     │  │    SSRS     │             │   │
│  │  └─────────────┘  └─────────────┘             │   │
│  └─────────────────────────────────────────────────┘   │
│                          │                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │              VPC Endpoints                      │   │
│  │         (S3, SSM, EC2, KMS, etc.)              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                           │
                           │ TGW Attachment
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Transit Gateway Backbone                   │
│                                                         │
│  ┌─────────────────┐    ┌─────────────────┐           │
│  │ Shared Services │    │   Other VPCs    │           │
│  │   (Domain/DNS)  │    │                 │           │
│  └─────────────────┘    └─────────────────┘           │
└─────────────────────────────────────────────────────────┘
```

## 🔐 Security Groups

### Standard Security Group
**Purpose**: Common ports and services for all instances

**Key Rules**:
- HTTPS (443) within VPC
- DNS (53) to Route53 resolvers
- RDP (3389) from Delinea PAM
- Active Directory communication to shared services
- WSUS connectivity for patching

### Bastion Security Group
**Purpose**: Administrative access controls

**Key Rules**:
- RDP access to SQL security group
- Controlled administrative connectivity

### SQL Security Group
**Purpose**: Database-specific connectivity

**Key Rules**:
- SQL Server (1433) from authorized sources
- PowerShell remoting (5985-5986) for management
- RPC (135) for administrative tools
- File share access (445) to FSx
- Connectivity to other SQL environments

## 🛠️ Prerequisites

Before deploying this module:

1. **AWS Account Setup**: Proper IAM permissions and account configuration
2. **Bootstrap Complete**: GitHub deployer role must be created
3. **Shared Services**: Domain credentials and cross-account access configured
4. **Transit Gateway**: Backbone TGW must exist and be accessible

## 🚀 Deployment Process

### Step 1: Prepare Environment
```bash
# Set required environment variables
export AWS_REGION=eu-west-2
export AWS_ACCOUNT_ID=296062593024
export ENVIRONMENT=dev
```

### Step 2: Deploy Network
```bash
# Use GitHub Actions workflow
.github/workflows/dev-deploy-infrastructure.yml
# Select: network
```

### Step 3: Verify Deployment
Check the following components are created:
- ✅ VPC with correct CIDR
- ✅ Subnet in correct AZ
- ✅ Transit Gateway attachment
- ✅ Security groups with proper rules
- ✅ VPC endpoints for AWS services
- ✅ KMS keys for encryption
- ✅ S3 buckets for setup files

## 📁 Module Structure

```
eweblogs/terraform/network/
├── main.tf              # VPC, subnets, TGW attachment
├── variables.tf         # Input parameters
├── outputs.tf          # Network resource outputs
├── data.tf             # Data sources and lookups
├── kms.tf              # KMS encryption keys
├── locals.tf           # Local value calculations
├── s3.tf               # S3 buckets for setup/software
├── secrets.tf          # Secrets Manager and SSM parameters
├── sg.tf               # Security group definitions
├── terragrunt.hcl      # Terragrunt configuration
└── ssm_inventory.tf.bak # SSM inventory (future use)
```

## 📤 Key Outputs

The network module provides these outputs for other modules:

### Network Information
- **vpc_id**: VPC identifier for resource placement
- **subnet_ids**: Subnet information for EC2 deployment
- **security_group_ids**: Security group references
- **route_table_ids**: Routing configuration

### Connectivity
- **vpc_endpoints**: AWS service endpoint information
- **tgw_attachment**: Transit Gateway attachment details

### Security
- **kms_key_arn**: Encryption key for other resources
- **security_groups**: Network security configurations

## 🔧 Configuration Variables

### Required Variables
- **ipv4_primary_cidr_block**: VPC CIDR block
- **tgw_id_backbone**: Transit Gateway ID for connectivity
- **intra_subnets**: Subnet configuration mapping
- **name**: Naming convention object (environment, service, identifier)

### Security Group Variables
- **standard_sg_rules_cidr_blocks**: Standard security rules
- **bastion_sg_rules_cidr_blocks**: Bastion access rules
- **sql_sg_rules_cidr_blocks**: Database connectivity rules

### Optional Variables
- **key_users**: KMS key user permissions
- **key_administrators**: KMS key admin permissions
- **domain_credentials**: Domain authentication (if provided)

## 🌐 VPC Endpoints

Private endpoints for AWS services to avoid internet traffic:

| Service | Purpose | Private DNS |
|---------|---------|-------------|
| S3 | Software/setup file access | Yes |
| SSM | Systems Manager operations | Yes |
| EC2 | Instance management | Yes |
| KMS | Encryption operations | Yes |
| Secrets Manager | Credential access | Yes |
| EC2 Messages | SSM communication | Yes |
| SSM Messages | SSM communication | Yes |

## 🔄 Post-Deployment

After network deployment is complete:

1. **Verify TGW Attachment**: Ensure attachment is in "available" state
2. **Test Connectivity**: Validate VPC endpoint accessibility
3. **Security Validation**: Review security group rules
4. **Deploy Addons**: Run network-addons module for TGW routes
5. **Deploy EC2**: Proceed with instance deployment

## 🐛 Troubleshooting

### Common Network Issues

**TGW Attachment Failed:**
- Verify TGW ID is correct
- Check cross-account permissions
- Ensure subnet has available IP addresses

**VPC Endpoint Issues:**
- Verify security group allows HTTPS (443)
- Check route table associations
- Validate endpoint policies

**DNS Resolution Problems:**
- Verify DHCP options are applied
- Check Route53 resolver configuration
- Ensure domain credentials are correct

**Security Group Connectivity:**
- Validate CIDR blocks are correct
- Check rule precedence and conflicts
- Verify source/destination configurations


## 🔒 Security Considerations

### Network Security
- All traffic remains within AWS backbone
- No internet gateway or NAT gateway for maximum security
- VPC endpoints prevent internet traversal for AWS services

### Encryption
- All resources encrypted with customer-managed KMS keys
- Secrets stored in AWS Secrets Manager with encryption
- Volume encryption enforced at infrastructure level

### Access Control
- Security groups implement least-privilege access
- Cross-account access properly configured
- Domain integration secured with encrypted credentials

## 🤝 Support

For network-related issues:
1. **AWS Console**: Check VPC, TGW, and endpoint status
2. **CloudTrail**: Review API calls for deployment issues
3. **VPC Flow Logs**: Analyze network traffic patterns
4. **GitHub Actions**: Review workflow logs for deployment errors

Contact the infrastructure team for network architecture questions or connectivity issues.