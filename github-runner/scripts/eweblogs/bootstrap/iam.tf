locals {
  project_name    = "${var.environment}-${var.service}"
  iam_role_name   = "${local.project_name}-sec-rol-github-deploy-${var.identifier}"
  tf_state_bucket = "${local.project_name}-plat-s3-terraform-state-${data.aws_caller_identity.current.account_id}"
  ddb_table_name  = "${local.project_name}-plat-s3-terraform-locks-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "tf_state_bucket" {
  bucket = local.tf_state_bucket
}

data "aws_dynamodb_table" "ddb_table_name" {
  name = local.ddb_table_name
}

# IAM Role for GitHub Deployer
resource "aws_iam_role" "github_deployer" {
  name = local.iam_role_name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:emisgroup/${var.github_repo}*:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "S3GitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}S3GitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:CreateBucket",
          "s3:List*",
          "s3:Get*",
          "s3:Describe*",
          "s3:PutObject",
          "s3:PutBucketPolicy",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutBucketTagging",
          "s3:PutObjectTagging",
          "s3:PutBucketAcl",
          "s3:PutObjectAcl",
          "s3:PutBucketLifecycle*",
          "s3:DeleteBucket",
          "s3:DeleteObjects",
          "s3:DeleteBucketLifecycle*",
          "s3:DeleteObjectTagging",
          "s3:DeleteBucketTagging",
          "s3:DeleteBucketPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "SecretsGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}SecretsGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:RestoreSecret",
          "secretsmanager:RotateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:UpdateSecret",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:ValidateResourcePolicy",
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "R53GitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}Route53GitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:Get*",
          "route53:List*",
          "route53:ChangeResourceRecordSets*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ParameterStoreGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}-ParamaterStoreGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:PutParameter",
          "ssm:LabelParameterVersion",
          "ssm:DeleteParameter",
          "ssm:UnlabelParameterVersion",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DeleteParameters"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/tf/output/*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetCommandInvocation"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "ssm:SendCommand"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ssm:${var.aws_region}::document/*",
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/*",
          "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "InfraGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}InfraGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:ListTagsLogGroup",
          "logs:CreateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:DeleteLogStream",
          "logs:GetLogDelivery",
          "logs:GetLogEvents",
          "logs:TagLogGroup",
          "logs:UntagLogGroup",
          "logs:UpdateLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:AssociateKmsKey",
          "logs:ListTagsForResource",
          "logs:UntagResource",
          "logs:TagResource",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DeleteResourcePolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "events:PutRule",
          "events:DescribeRule",
          "events:ListRules",
          "events:DeleteRule",
          "events:ListTagsForResource",
          "events:PutTargets",
          "events:ListTargetsByRule",
          "events:RemoveTargets"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:PassRole",
          "iam:TagRole",
          "iam:List*",
          "iam:Get*",
          "iam:CreateServiceLinkedRole",
          "iam:TagInstanceProfile",
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:TagPolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
          "iam:SetDefaultPolicyVersion",
          "iam:DeleteServiceLinkedRole",
          "iam:UntagRole",
          "iam:UntagInstanceProfile",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:UntagPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:ListTagsForResource",
          "sns:TagResource",
          "sns:UntagResource",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:AddPermission",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:Publish",
          "sns:GetSubscriptionAttributes",
          "sns:ConfirmSubscription",
          "sns:ListSubscriptions",
          "sns:ListSubscriptionsByTopic",
          "sns:SetSubscriptionAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:EnableAlarmActions",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricStream",
          "cloudwatch:ListMetricStreams",
          "cloudwatch:ListMetrics",
          "cloudwatch:ListTagsForResource",
          "cloudwatch:PutCompositeAlarm",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:SetAlarmState",
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "KmsGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}KmsGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:List*",
          "kms:GetKeyRotationStatus",
          "kms:CreateAlias",
          "kms:CreateKey",
          "kms:TagResource",
          "kms:EnableKeyRotation",
          "kms:PutKeyPolicy",
          "kms:UpdateKeyDescription",
          "kms:UntagResource",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyPair",
          "kms:Decrypt",
          "kms:UpdateAlias",
          "kms:DeleteAlias",
          "kms:ScheduleKeyDeletion",
          "kms:CreateGrant",
          "kms:RevokeGrant",
          "kms:RetireGrant"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "EC2GitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}EC2GitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:Create*",
          "ec2:AttachNetworkInterface",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:ModifySecurityGroupRules",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:ReplaceRoute",
          "ec2:ReplaceRouteTableAssociation",
          "ec2:AssociateSubnetCidrBlock",
          "ec2:DisassociateSubnetCidrBlock",
          "ec2:ModifySubnetAttribute",
          "ec2:AssociateVpcCidrBlock",
          "ec2:DisassociateVpcCidrBlock",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:ModifyVpcTenancy",
          "ec2:AllocateAddress",
          "ec2:RunInstances",
          "ec2:AssociateIamInstanceProfile",
          "ec2:ReplaceIamInstanceProfileAssociation",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ModifyAddressAttribute",
          "ec2:MoveAddressToVpc",
          "ec2:ReleaseAddress",
          "ec2:ResetAddressAttribute",
          "ec2:RestoreAddressToClassic",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:ResetNetworkInterfaceAttribute",
          "ec2:DeleteSecurityGroup",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteTags",
          "ec2:DeleteEgressOnlyInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteVpc",
          "ec2:DeleteFlowLogs",
          "ec2:DeleteSubnet",
          "ec2:DeleteNatGateway",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:DeleteLaunchTemplate",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DisassociateIamInstanceProfile",
          "ec2:DeleteVpcEndpoints",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcEndpointServices",
          "ec2:ModifyVpcEndpoint",
          "ec2:ModifyVpcEndpointServicePermissions",
          "ec2:MonitorInstances",
          "ec2:UnmonitorInstances",
          "ec2:AssociateDhcpOptions",
          "ec2:CreateDhcpOptions",
          "ec2:DeleteDhcpOptions",
          "ec2:ImportKeyPair",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DeleteKeyPair",
          "ec2:DeleteNetworkAclEntry",
          "ec2:AttachVolume",
          "ec2:ModifyVolume",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:ModifyInstanceMetadataOptions"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "resource-groups:CreateGroup",
          "resource-groups:Tag",
          "resource-groups:GetGroup",
          "resource-groups:GetGroupQuery",
          "resource-groups:GetTags",
          "resource-groups:DeleteGroup",
          "resource-groups:ListGroupResources",
          "resource-groups:UpdateGroupQuery",
          "tag:GetResources"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "ds:Describe*",
          "ds:List*",
          "ds:Get*"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "route53:Get*",
          "route53:List*",
          "route53:Describe*"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "fsx:Describe*",
          "fsx:List*",
          "fsx:TagResource",
          "fsx:UntagResource",
          "fsx:Create*",
          "fsx:Delete*",
          "fsx:Associate*",
          "fsx:Disassociate*",
          "fsx:Update*",
          "fsx:ReleaseFileSystemNfsV3Locks",
          "fsx:ManageBackupPrincipalAssociations"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ELBGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}ELBGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:Create*",
          "elasticloadbalancing:Delete*",
          "elasticloadbalancing:Set*",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:ConfigureHealthCheck",
          "elasticloadbalancing:AttachLoadBalancerToSubnets",
          "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DetachLoadBalancerFromSubnets",
          "elasticloadbalancing:DisableAvailabilityZonesForLoadBalancer",
          "elasticloadbalancing:EnableAvailabilityZonesForLoadBalancer",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:ModifyTargetGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "RemoteStateGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}RemoteStateGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = data.aws_s3_bucket.tf_state_bucket.arn
      },
      {
        Action = [
          "s3:*Object"
        ]
        Effect   = "Allow"
        Resource = data.aws_s3_bucket.tf_state_bucket.arn
      },
      {
        Action = [
          "dynamodb:*"
        ]
        Effect   = "Allow"
        Resource = data.aws_dynamodb_table.ddb_table_name.arn
      }
    ]
  })
}

resource "aws_iam_policy" "SSMGitHubDeployerPolicy" {
  name = "${local.project_name}-sec-pol-${var.identifier}SSMGitHubDeployerPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:Describe*",
          "ssm:List*",
          "ssm:DeleteDocument",
          "ssm:CreateDocument",
          "ssm:DescribeDocument",
          "ssm:DeleteAssociation",
          "ssm:DescribeAssociation",
          "ssm:CreateAssociation",
          "ssm:DescribeDocumentPermission",
          "ssm:GetDocument",
          "ssm:AddTagsToResource",
          "ssm:ListTagsForResource",
          "ssm:RemoveTagsFromResource",
          "ssm:UpdateDocument",
          "ssm:UpdateAssociation",
          "ssm:UpdateDocumentDefaultVersion",
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DeleteParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetCommandInvocation"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      },
      {
        Action = [
          "ssm:SendCommand"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ssm:${var.aws_region}::document/*",
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/*",
          "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
      },
      {
        Action = [
          "backup:TagResource",
          "backup:UntagResource",
          "backup:UpdateRegionSettings",
          "backup:CreateBackupVault",
          "backup:DeleteBackupVault",
          "backup:DeleteBackupVaultAccessPolicy",
          "backup:DeleteBackupVaultLockConfiguration",
          "backup:DescribeBackupVault",
          "backup:DescribeRegionSettings",
          "backup:GetBackupVaultAccessPolicy",
          "backup:GetBackupVaultNotifications",
          "backup:ListBackupVaults",
          "backup:ListTags",
          "backup:PutBackupVaultAccessPolicy",
          "backup:PutBackupVaultLockConfiguration",
          "backup:PutBackupVaultNotifications",
          "backup:TagResource",
          "backup:UntagResource",
          "backup:UpdateRegionSettings",
          "backup-storage:MountCapsule"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${var.aws_region}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "S3GitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.S3GitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "SecretsGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.SecretsGitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "InfraGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.InfraGitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "R53GitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.R53GitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "KmsGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.KmsGitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "EC2GitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.EC2GitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "ELBGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.ELBGitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "RemoteStateGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.RemoteStateGitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "SSMGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.SSMGitHubDeployerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "ParameterStoreGitHubDeployerPolicy-attach" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.ParameterStoreGitHubDeployerPolicy.arn
}