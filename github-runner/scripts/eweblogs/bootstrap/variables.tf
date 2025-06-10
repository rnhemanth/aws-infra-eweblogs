variable "aws_region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS Region"
}

variable "environment" {
  type        = string
  description = "Name of the deployment environmnet. e.g. sbx, dev, stg, prd"
  validation {
    condition     = contains(["sbx", "dev", "stg", "prd"], var.environment)
    error_message = "environment value must be sbx, dev, stg or prd."
  }
}

variable "service" {
  type        = string
  description = "Name of the service"
}

variable "terraform_backend_config_file_name" {
  type        = string
  default     = "terraform.tf"
  description = "Name of terraform backend config file"
}

variable "terraform_backend_config_file_path" {
  type        = string
  default     = ""
  description = "Directory for the terraform backend config file, usually `.`. The default is to create no file."
}

variable "terraform_backend_config_template_file" {
  type        = string
  default     = ""
  description = "The path to the template used to generate the config file"
}

variable "terraform_state_file" {
  type        = string
  default     = "backend.tfstate"
  description = "The path to the state file inside the bucket"
}

variable "terraform_state_bucket" {
  type        = string
  description = "Remote backend terraform s3 bucket for state files"
}

variable "terraform_lock_table" {
  type        = string
  description = "Remote backend terraform dynamodb table for lock"

}
variable "github_repo" {
  type        = string
  description = "GitHub repository name to create trust relationship for github deployer role"
}

variable "identifier" {
  type        = string
  description = "Identifier for the base stack you are deploying with GitHub Workflows"
}
