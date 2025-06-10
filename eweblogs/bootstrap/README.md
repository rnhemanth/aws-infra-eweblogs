# Bootstrap IAM role for GitHub Deployer

## Prerequisites
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
* [jq](https://stedolan.github.io/jq/download/)

## Usage
To create an IAM role to use with GitHub workflows
1. Create a Makefile in your deploy GitHub repo root directory.
usage
```
make bootstrap-<service>-<env>:
<setup> bootstrap <env> <service> <service_lcoation> <region> <gitub_repo> <identifier> [destroy]
```
2. Setup or export your aws credentials
3. Run `make bootstrap-<service>-<env>`

### Example Makefile
Example makefile in aws-infra-deploy-emis-web-england-gp
```
bootstrap-england-dev:
	@echo "- Bootstrap England dev environment..."
  chmod +x ./aws-emis-web-cs-platform/bootstrap/setup
	./aws-emis-web-cs-platform/bootstrap/setup bootstrap dev ew england eu-west-2 aws-infra-deploy-emis-web-england-gp ew-platform
	@echo "✔ Done"

bootstrap-england-stg:
	@echo "- Bootstrap England stg environment..."
  chmod +x ./aws-emis-web-cs-platform/bootstrap/setup
	./aws-emis-web-cs-platform/bootstrap/setup bootstrap stg ew england eu-west-2 aws-infra-deploy-emis-web-england-gp ew-platform
	@echo "✔ Done"

bootstrap-england-prd:
	@echo "- Bootstrap england prd environment..."
  chmod +x ./aws-emis-web-cs-platform/bootstrap/setup
	./aws-emis-web-cs-platform/bootstrap/setup bootstrap prd ew england eu-west-2 aws-infra-deploy-emis-web-england-gp ew-platform
	@echo "✔ Done"

destory-role-england-dev:
	@echo "- Destroying github-deploy-ew-platform role in England dev environment..."
  chmod +x ./aws-emis-web-cs-platform/bootstrap/setup
	./aws-emis-web-cs-platform/bootstrap/setup bootstrap dev ew england eu-west-2 aws-infra-deploy-emis-web-england-gp ew-platform destroy
	@echo "✔ Done"

destory-role-england-stg:
	@echo "- Destroying github-deploy-ew-platform role in England stg environment..."
  chmod +x ./aws-emis-web-cs-platform/bootstrap/setup
	./aws-emis-web-cs-platform/bootstrap/setup bootstrap stg ew england eu-west-2 aws-infra-deploy-emis-web-england-gp ew-platform destroy
	@echo "✔ Done"

destory-role-england-prd:
	@echo "- Destroying github-deploy-ew-platform role in England prd environment..."
  chmod +x ./aws-emis-web-cs-platform/bootstrap/setup
	./aws-emis-web-cs-platform/bootstrap/setup bootstrap prd ew england eu-west-2 aws-infra-deploy-emis-web-england-gp ew-platform destroy
	@echo "✔ Done"
```

## Setup script arguments

| Parameter Name  | Argument | Default |
| ----------------|:--------:| -------:|
| command | $1 |  |
| env | $2 |  |
| service | $3 |  |
| service_location | $4 |
| region | $5 |  |
| github_repo | $6 |  |
| identifier | $7 |  |
| business_unit |  | primary-care |
| product |  | emis-web |
| programme_name |  | adelaide |
| project_name |  | brisbane |
| project_code |  | prj0011476 |

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.EC2GitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ELBGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.InfraGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.KmsGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ParameterStoreGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.RemoteStateGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.S3GitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.SSMGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.SecretsGitHubDeployerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.github_deployer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.EC2GitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ELBGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.InfraGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.KmsGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ParameterStoreGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.RemoteStateGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.S3GitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.SSMGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.SecretsGitHubDeployerPolicy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_dynamodb_table.ddb_table_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/dynamodb_table) | data source |
| [aws_s3_bucket.tf_state_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `string` | `"eu-west-2"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Name of the deployment environmnet. e.g. sbx, dev, stg, prd | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository name to create trust relationship for github deployer role | `string` | n/a | yes |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Identifier for the base stack you are deploying with GitHub Workflows | `string` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | Name of the service | `string` | n/a | yes |
| <a name="input_terraform_backend_config_file_name"></a> [terraform\_backend\_config\_file\_name](#input\_terraform\_backend\_config\_file\_name) | Name of terraform backend config file | `string` | `"terraform.tf"` | no |
| <a name="input_terraform_backend_config_file_path"></a> [terraform\_backend\_config\_file\_path](#input\_terraform\_backend\_config\_file\_path) | Directory for the terraform backend config file, usually `.`. The default is to create no file. | `string` | `""` | no |
| <a name="input_terraform_backend_config_template_file"></a> [terraform\_backend\_config\_template\_file](#input\_terraform\_backend\_config\_template\_file) | The path to the template used to generate the config file | `string` | `""` | no |
| <a name="input_terraform_lock_table"></a> [terraform\_lock\_table](#input\_terraform\_lock\_table) | Remote backend terraform dynamodb table for lock | `string` | n/a | yes |
| <a name="input_terraform_state_bucket"></a> [terraform\_state\_bucket](#input\_terraform\_state\_bucket) | Remote backend terraform s3 bucket for state files | `string` | n/a | yes |
| <a name="input_terraform_state_file"></a> [terraform\_state\_file](#input\_terraform\_state\_file) | The path to the state file inside the bucket | `string` | `"backend.tfstate"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployer_role_arn"></a> [deployer\_role\_arn](#output\_deployer\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
