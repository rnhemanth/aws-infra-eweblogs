data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_roles" "AWSAdministratorAccess" {
  name_regex  = "AWSReservedSSO_AdministratorAccess.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_default_tags" "default" {}

data "aws_vpc" "vpc" {
  cidr_block = var.ipv4_primary_cidr_block

  tags = {
    Name = "${var.name.environment}-${var.name.servive}-${var.name.identifier}-vpc"
  }
}

data "aws_secretsmanager_secret" "defaultadsecret" {
  name = "${var.name.environment}-${var.name.service}-sec-sm-default-ad"
}

data "aws_security_group" "standard" {
  tags = {
    Name = "${var.name.environment}-core-net-sg-${var.name.service}-${var.name.identifier}-standard-ports"
  }
}

data "aws_security_group" "bastion" {
  tags = {
    Name = "${var.name.environment}-core-net-sg-${var.name.service}-bastion"
  }
}

data "aws_security_group" "sql" {
  tags = {
    Name = "${var.name.environment}-core-net-sg-${var.name.service}-sql"
  }
}

data "aws_kms_key" "ad_secret" {
  key_id = "alias/${var.name.environment}-eweblogs-sec-kk-infra"
}