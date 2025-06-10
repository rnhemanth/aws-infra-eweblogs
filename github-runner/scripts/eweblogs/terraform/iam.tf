resource "aws_iam_role" "ec2_role" {
  name = "${lower(var.environment)}-${lower(var.service)}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    "QSConfigId-${var.wsus_qsconfig_id_ring1}"    = "${var.wsus_qsconfig_id_ring1}"
    # "QSConfigId-${var.wsus_qsconfig_id_ring2}"    = "${var.wsus_qsconfig_id_ring2}"
    # "QSConfigId-${var.wsus_qsconfig_id_ring3}"    = "${var.wsus_qsconfig_id_ring3}"
    # "QSConfigId-${var.wsus_qsconfig_id_ring4}"    = "${var.wsus_qsconfig_id_ring4}"
    "QSConfigId-${var.wsus_qsconfig_id_ringscan}" = "${var.wsus_qsconfig_id_ringscan}"
  }
}

resource "aws_iam_role_policy_attachment" "ssm-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "directory-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-${var.service}-sec-rol-ec2profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy" "KMSInstanceRolePolicy" {
  name = "KMSInstanceRolePolicy"
  role = aws_iam_role.ec2_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Effect = "Allow"
        Resource = [
          module.kms.key_arn
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy" "SecretsInstanceRolePolicy" {
  name = "SecretsInstanceRolePolicy"
  role = aws_iam_role.ec2_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${data.aws_region.current.name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "Ec2InstanceRolePolicy" {
  name = "Ec2InstanceRolePolicy"
  role = aws_iam_role.ec2_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          "StringEquals" = {
            "aws:RequestedRegion" = "${data.aws_region.current.name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "InstallerS3AccessRolePolicy" {
  name = "InstallerS3AccessRolePolicy"
  role = aws_iam_role.ec2_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:Get*",
          "s3:List*"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.environment}-dynatrace-s3-bucket-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.environment}-dynatrace-s3-bucket-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:s3:::${var.environment}-${var.name.service}-${var.name.identifier}-plat-s3-setup-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.environment}-${var.name.service}-${var.name.identifier}-plat-s3-setup-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:s3:::${var.environment}-${var.name.service}-${var.name.identifier}-software-setup-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.environment}-${var.name.service}-${var.name.identifier}-software-setup-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:s3:::${var.environment}-ibi-sftp-plat-s3-sftp",
          "arn:aws:s3:::${var.environment}-ibi-sftp-plat-s3-sftp/*"


        ]
      }
    ]
  })
}