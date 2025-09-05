# EWebLogs Infrastructure - Main Terraform Module

This is the main Terraform module that deploys the EWebLogs EC2 infrastructure for SSIS and SSRS services.

## 🏗️ What This Module Does

This module creates and configures:

### EC2 Instances
- **SSIS Server (SIS001)**: SQL Server Integration Services
- **SSRS Server (SRS001)**: SQL Server Reporting Services
- Automated domain join to shared services Active Directory
- Volume encryption with customer-managed KMS keys
- Proper tagging for monitoring and management

### IAM Infrastructure
- EC2 instance roles with least-privilege access
- KMS permissions for volume encryption
- Secrets Manager access for domain credentials
- S3 access for software installation
- SSM permissions for management and patching

### Security
- KMS customer-managed keys for encryption
- IAM policies following security best practices
- Integration with existing security groups from network module

### Monitoring & Management
- SSM parameter store for instance metadata
- Resource groups for operational management
- CloudWatch integration via instance roles

## 📋 Prerequisites

Before deploying this module, ensure:

1. **Network Module Deployed**: The network infrastructure must be deployed first
2. **Domain Credentials**: Shared services domain credentials must be configured
3. **GitHub Secrets**: All required secrets configured in GitHub repository
4. **Subnet Information**: Correct subnet IDs from network deployment

## 🚀 Deployment

### Step 1: Deploy Network Infrastructure
```bash
# Deploy network first
.github/workflows/dev-deploy-infrastructure.yml
# Choose: network
```

### Step 2: Deploy Network Addons (TGW Routes)
```bash
# Deploy network addons for domain connectivity
.github/workflows/dev-deploy-infrastructure.yml
# Choose: network-addons
```

### Step 3: Deploy EC2 Infrastructure
```bash
# Deploy this main module
.github/workflows/dev-deploy-infrastructure.yml
# Choose: ec2
```

## 📁 Module Structure

```
eweblogs/terraform/
├── main.tf                    # Main module configuration
├── variables.tf              # Input variables
├── outputs.tf               # Output values
├── data.tf                  # Data sources
├── ec2.tf                   # EC2 instance configuration
├── iam.tf                   # IAM roles and policies
├── kms.tf                   # KMS key configuration
├── locals.tf                # Local values
├── resouce-groups.tf        # Resource group definitions
├── output_parameter_store.tf # SSM parameter outputs
└── files/
    └── user_data.ps1        # Windows instance initialization
```

## 🔧 Configuration

### Server Specifications

| Server | Function | Instance Type | Storage | Description |
|--------|----------|---------------|---------|-------------|
| SIS001 | SSIS | t3.large | 50GB root + 100GB data | Integration Services |
| SRS001 | SSRS | t3.medium | 50GB root + 50GB data | Reporting Services |

### Environment Variables Required

Set these in your environment or GitHub secrets:

```bash
AWS_REGION=eu-west-2
AWS_ACCOUNT_ID=296062593024
ENVIRONMENT=dev
DOMAIN_CREDENTIALS=<secret-arn>
FULL_DOMAIN_NAME=<domain>
```

## 💾 Data Sources

This module references:
- **VPC**: Looks up VPC created by network module
- **Subnets**: Uses subnet information for instance placement
- **Security Groups**: References security groups from network module
- **Domain Credentials**: Accesses shared services domain secret
- **KMS Keys**: Uses encryption keys from network module

## 📤 Outputs

The module outputs:
- **Instance IDs**: For reference by other systems
- **Private IP Addresses**: For network configuration
- **Instance Names**: Standardized hostname format
- **KMS Key Information**: For encryption reference
- **IAM Role ARNs**: For cross-account access

## 🔐 Security Features

### Encryption
- All EBS volumes encrypted with customer-managed KMS keys
- Secrets Manager integration for domain credentials
- In-transit encryption for domain communication

### Access Control
- Least-privilege IAM policies
- Instance profiles with minimal required permissions
- Security group integration with network module

### Compliance
- Instance metadata service v2 required
- API termination protection enabled
- Proper resource tagging for governance

## 🖥️ Instance Configuration

### Automated Setup
Each instance automatically:
1. **Sets timezone** to GMT Standard Time
2. **Configures locale** to en-GB
3. **Initializes disks** with proper drive letters and labels
4. **Creates admin user** (emis-admin) managed by LAPS
5. **Joins domain** using shared services credentials
6. **Configures pagefile** for optimal performance
7. **Registers DNS** for name resolution

### Drive Configuration
- **C:** Operating System (50GB)
- **D:** Data/Application files (varies by server)
- **L:** Log files (SSIS only)
- **T:** Temp files (SSIS only)

## 🔧 Post-Deployment Steps

After successful deployment:

1. **Verify Domain Join**: Check instances are properly joined to domain
2. **Install Software**: Use configuration workflows to install SQL Server
3. **Configure Services**: Set up SSIS/SSRS specific configurations
4. **Security Patching**: Ensure WSUS configuration is working
5. **Monitoring**: Verify CloudWatch and monitoring integration


## 🤝 Support

For issues or questions:
1. Check GitHub Actions logs for deployment errors
2. Review AWS CloudWatch logs for instance issues
3. Contact infrastructure team for network-related problems
4. Reference Business Intelligence repository for working examples