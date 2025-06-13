# EWebLogs Infrastructure Deployment

This repository contains the complete Infrastructure as Code (IaC) solution for deploying EWebLogs SSIS and SSRS services in AWS using Terraform and Terragrunt with automated GitHub Actions workflows.

## 🏗️ **What This Repository Deploys**

### **Infrastructure Overview**
- **EWebLogs Platform**: SQL Server Integration Services (SSIS) and Reporting Services (SSRS)
- **Environment**: Development and Production-ready infrastructure
- **Architecture**: Secure, scalable, and compliant AWS infrastructure
- **Integration**: Cross-account connectivity to shared services for domain join

### **Key Components**
- **Network Infrastructure**: VPC, subnets, security groups, Transit Gateway connectivity
- **Compute Resources**: EC2 instances with automated domain join capability
- **Security**: KMS encryption, cross-account IAM roles, security agents
- **Monitoring**: CloudWatch integration, Dynatrace, vulnerability scanning
- **Automation**: Complete CI/CD pipeline with GitHub Actions

## 📁 **Repository Structure**

```
aws-infra-deploy-eweblogs/
├── README.md                           # This file
├── Makefile                           # Bootstrap commands
├── .github/workflows/                 # CI/CD automation
│   ├── dev-deploy-infrastructure.yml  # Infrastructure deployment
│   ├── dev-configure-ec2.yml         # Software configuration
│   ├── prd-deploy-infrastructure.yml  # Production deployment
│   └── manual-bootstrap.yml          # IAM role creation
├── eweblogs/                          # Main infrastructure code
│   ├── terraform/                     # Terraform modules
│   │   ├── network/                  # VPC, networking, security
│   │   ├── addons/                   # TGW routes, Route53
│   │   └── (root)/                   # EC2 instances, IAM, KMS
│   └── bootstrap/                    # GitHub deployer role setup
├── terragrunt/                       # Environment configurations
│   ├── common.terragrunt.hcl         # Shared settings
│   └── dev/environment.terragrunt.hcl # Dev-specific config
└── github-runner/                    # Submodule with deployment actions
```

## 🚀 **Quick Start**

### **Prerequisites**
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Terragrunt >= 0.54
- jq
- GitHub repository with secrets configured

### **1. Bootstrap (One-time setup)**
```bash
# Create GitHub deployer IAM role

# Using GitHub Actions (Recommended)
1. Go to GitHub Actions → "Manual Bootstrap - Create GitHub Deployer Role"
2. Run workflow with inputs:
   - Environment: dev
   - Service name: eweblogs
   - Service location: england
   - AWS region: eu-west-2
   - GitHub repository name: aws-infra-deploy-eweblogs
   - Stack identifier: eweblogs-platform
3. Copy the output DEPLOYER_ROLE_ARN to GitHub secrets

# Alternative: Local execution (if needed)
make bootstrap-dev

# Copy the output DEPLOYER_ROLE_ARN to GitHub secrets
```

### **2. Deploy Infrastructure**
```bash
# Using GitHub Actions (Recommended)
1. Go to GitHub Actions → "DEV - Deploy - Infrastructure"
2. Run workflow with input: "network"
3. Run workflow with input: "network-addons" 
4. Run workflow with input: "ec2"

```
### **3. Configure Software**
```bash
# Using GitHub Actions
Go to GitHub Actions → "DEV - Configure - EC2s"
Run workflow (installs security agents, SQL Server, monitoring)
```

## 🏛️ **Architecture**

### **Network Design**
```
┌─────────────────────────────────────────────────────────┐
│                EWebLogs VPC                             │
│              100.68.58.192/26                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │               Subnet ewl-2a                     │   │
│  │            100.68.58.192/27                     │   │
│  │                                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐             │   │
│  │  │   SIS001    │  │   SRS001    │             │   │
│  │  │  t3.large   │  │  t3.medium  │             │   │
│  │  │    SSIS     │  │    SSRS     │             │   │
│  │  └─────────────┘  └─────────────┘             │   │
│  └─────────────────────────────────────────────────┘   │
│                          │                              │
│                          │ TGW Routes                   │
│                          ▼                              │
└─────────────────────────────────────────────────────────┘
                           │
                           │ Transit Gateway
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Shared Services                            │
│         • Active Directory                              │
│         • DNS Resolution                                │
│         • WSUS Servers                                  │
└─────────────────────────────────────────────────────────┘
```

### **Security Model**
- **Encryption**: All data encrypted at rest with customer-managed KMS keys
- **Network**: Private subnets only, no internet access
- **Access**: Cross-account IAM roles, no long-term credentials
- **Monitoring**: Comprehensive logging and alerting
- **Compliance**: Security agents, vulnerability scanning, patch management

## 🛠️ **Available Workflows**

### **Infrastructure Deployment Workflows**

#### **`dev-deploy-infrastructure.yml`**
Deploys infrastructure components with choice of:
- **`network`**: VPC, subnets, security groups, TGW attachment
- **`network-addons`**: TGW routes, Route53 resolver associations  
- **`ec2`**: SSIS/SSRS instances with domain join capability

#### **`dev-configure-ec2.yml`**
Automated software configuration including:
- **Security Agents**: Nessus, CrowdStrike, Dynatrace
- **Software Distribution**: SQL Server installers, SSMS
- **System Configuration**: WSUS, Active Directory integration
- **Monitoring Setup**: Performance and security monitoring

### **Management Workflows**

#### **`manual-bootstrap.yml`**
Creates GitHub deployer IAM role with required permissions

#### **`dev-destroy-network-only.yml`**
Safely destroys network infrastructure when needed

## 📊 **Current Deployment Status**

| Component | Status | Description |
|-----------|---------|-------------|
| 🌐 **Network Infrastructure** | ✅ Complete | VPC, subnets, security groups, TGW |
| 🔧 **GitHub Actions** | ✅ Working | All workflows functional |
| 🛣️ **Network Addons** | ✅ Complete | TGW routes, Route53 associations |
| 💻 **EC2 Instances** | ✅ Deployed | SIS001, SRS001 with user data |
| 🔗 **TGW Attachment** | ⚠️ Pending | Manual acceptance required |
| 🏢 **Domain Join** | ⚠️ Pending | Awaiting TGW acceptance |
| 📦 **Software Config** | 📋 Ready | 6/8 jobs ready, 2 need domain |

## 🔧 **Environment Configuration**

### **Development Environment**
- **CIDR**: `100.68.58.192/26`
- **Servers**: SIS001 (t3.large), SRS001 (t3.medium)
- **Branch**: `develop`
- **Domain**: `dev.shared-services.emis-web.com`

### **Production Environment**  
- **CIDR**: `100.88.24.128/26`
- **Servers**: SIS001 (production sizing), SRS001 (production sizing)
- **Branch**: `main`
- **Domain**: `shared-services.emis-web.com`

## 🔐 **Security & Compliance**

### **Encryption**
- **EBS Volumes**: KMS customer-managed keys
- **S3 Buckets**: Server-side encryption with KMS
- **Secrets**: AWS Secrets Manager with KMS encryption
- **Transit**: TLS encryption for all communications

### **Access Control**
- **Cross-Account**: IAM roles for shared services access
- **Instance Access**: SSM Session Manager, no SSH keys
- **Deployment**: GitHub OIDC, no long-term credentials
- **Monitoring**: CloudTrail, VPC Flow Logs, CloudWatch

### **Compliance**
- **Patch Management**: WSUS integration
- **Vulnerability Scanning**: Nessus agent deployment
- **Endpoint Protection**: CrowdStrike EDR
- **Performance Monitoring**: Dynatrace APM

## 🚨 **Current Priority Actions**

### **1. Accept TGW Attachment (Manual)**
```bash
AWS Console → VPC → Transit Gateway → Attachments
Find: "dev-core-net-tgw-attach-eweb-ibi-vpc-[vpc-id]"
Status: "pending-acceptance" → Accept
```

### **2. Complete Domain Join**
```bash
# After TGW acceptance, restart instances or use SSM
# Verify domain connectivity and DNS resolution
```

### **3. Run Software Configuration**
```bash
# Execute full software configuration workflow
GitHub Actions → "DEV - Configure - EC2s" → Run workflow
```


## 🤝 **Support & Contacts**

- **Infrastructure Team**: Repository maintenance and deployment issues
- **Brandon (Platform Team)**: Infrastructure deployment support for IBI
- **Scott Ashmore (Network Team)**: TGW connectivity, routing, and network architecture
- **Security Team**: Compliance, security agents, and access controls


## ⚠️ **Architecture Limitations**

### **High Availability Considerations**
- **Single AZ Design**: All resources in `eu-west-2c` - no cross-AZ redundancy
- **No Load Balancing**: Direct instance access - no failover capability  
- **Development Focus**: Current architecture optimized for cost over availability
- **Production Readiness**: Would require HA redesign for production workloads

## 📈 **Next Steps**

1. **Complete Infrastructure**: Accept TGW attachment and finish domain join
2. **Software Installation**: SQL Server SSIS/SSRS configuration
3. **Production Deployment**: Replicate successful dev setup to production
4. **Operational Readiness**: Backup, disaster recovery, and runbooks

---

**Project Status**: 90% Complete - Infrastructure deployed, awaiting final connectivity setup

This repository provides enterprise-grade infrastructure automation following AWS and EMIS best practices for security, compliance, and operational excellence.