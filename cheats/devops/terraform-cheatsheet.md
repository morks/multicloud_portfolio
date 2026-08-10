# Terraform / OpenTofu Cheat Sheet

## Installation & Setup

```bash
# Install Terraform (macOS via Homebrew)
brew install terraform

# Install OpenTofu (macOS via Homebrew)
brew install opentofu

# Check version
terraform version
tofu version

# Enable shell completion (zsh)
echo 'complete -C /usr/local/bin/terraform terraform' >> ~/.zshrc
echo 'source <(tofu completion zsh)' >> ~/.zshrc

# Install tfenv – Terraform version manager
brew install tfenv
tfenv list-remote              # list available versions
tfenv install 1.9.0            # install specific version
tfenv use 1.9.0                # switch to version
tfenv list                     # list locally installed versions

# Pin version per project
echo "1.9.0" > .terraform-version

# Useful environment variables
export TF_LOG=DEBUG                        # log level: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG_PATH=./terraform.log         # write logs to file
export TF_VAR_environment=production       # set input variable
export TF_VAR_db_password=secret123        # set sensitive variable
export TF_CLI_ARGS_plan="-compact-warnings"   # default flags for subcommand
export TF_CLI_ARGS_apply="-auto-approve"      # skip confirmation on apply
export TF_DATA_DIR=./.terraform-data       # override .terraform directory
export TF_WORKSPACE=my-workspace           # pre-select workspace
```

---

## Core Workflow

```bash
# Initialize working directory (download providers & modules)
terraform init
tofu init

# Initialize with upgrade for providers/modules
terraform init -upgrade

# Preview changes (plan)
terraform plan
terraform plan -out=my-plan.tfplan         # save plan to file

# Show plan as JSON (machine-readable)
terraform plan -out=my-plan.tfplan -json | jq

# Apply changes
terraform apply
terraform apply -auto-approve              # skip interactive confirmation
terraform apply my-plan.tfplan             # apply from saved plan file

# Target specific resource only
terraform plan -target=aws_instance.my-resource
terraform apply -target=module.my-module -auto-approve

# Destroy all resources
terraform destroy
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_s3_bucket.my-resource -auto-approve

# Refresh state without making changes
terraform apply -refresh-only
terraform plan -refresh-only

# Skip state refresh during plan
terraform plan -refresh=false

# Suppress verbose warnings
terraform plan -compact-warnings
terraform apply -compact-warnings

# Show current state in human-readable form
terraform show

# Validate configuration syntax and logic
terraform validate

# Format all .tf files recursively
terraform fmt -recursive

# Check format without writing (useful in CI)
terraform fmt -check -recursive
```

---

## State Management

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show aws_instance.my-resource
terraform state show 'module.my-module.aws_subnet.private[0]'

# Move resource to new address (rename/refactor)
terraform state mv aws_instance.old-name aws_instance.my-resource

# Move resource into a module
terraform state mv aws_instance.my-resource module.my-module.aws_instance.my-resource

# Remove resource from state (without destroying)
terraform state rm aws_instance.my-resource
terraform state rm 'module.my-module.aws_s3_bucket.my-resource'

# Pull remote state to stdout
terraform state pull

# Push local state to remote backend (use carefully)
terraform state push terraform.tfstate

# Create manual state backup before risky operations
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Unlock state after failed operation
terraform force-unlock LOCK_ID

# Show raw state file
terraform show -json | jq '.values.root_module.resources'

# Replace a specific resource (taint equivalent in 0.15.2+)
terraform apply -replace=aws_instance.my-resource
```

---

## Workspaces

```bash
# Create a new workspace
terraform workspace new my-workspace

# List all workspaces
terraform workspace list

# Switch to a workspace
terraform workspace select my-workspace

# Show current workspace name
terraform workspace show

# Delete a workspace (must be empty / not current)
terraform workspace delete my-workspace

# Use workspace name in configuration
# The current workspace is available as terraform.workspace
```

```hcl
# Use workspace to select environment-specific values
locals {
  env_config = {
    default    = { instance_type = "t3.micro",  min_size = 1 }
    staging    = { instance_type = "t3.small",  min_size = 1 }
    production = { instance_type = "t3.medium", min_size = 3 }
  }
  config = local.env_config[terraform.workspace]
}

resource "aws_autoscaling_group" "my-resource" {
  min_size          = local.config.min_size
  # Use workspace as part of the resource name
  name              = "my-asg-${terraform.workspace}"
}
```

---

## Modules

```hcl
# Local module
module "my-module" {
  source = "./modules/networking"

  vpc_cidr = "10.0.0.0/16"
  env      = var.environment
}

# Registry module (Terraform Registry)
module "my-module" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Git module (pinned to tag)
module "my-module" {
  source = "git::https://github.com/my-org/my-terraform-modules.git//vpc?ref=v1.2.0"
}

# Git module via SSH
module "my-module" {
  source = "git@github.com:my-org/my-terraform-modules.git//networking?ref=main"
}

# Pass provider to module explicitly
module "my-module" {
  source = "./modules/my-module"

  providers = {
    aws = aws.eu-central-1
  }
}

# Access module output
output "vpc_id" {
  value = module.my-module.vpc_id
}
```

```bash
# Download and update all modules
terraform get
terraform get -update

# Show module tree
terraform providers
```

---

## Variables & Outputs

```hcl
# Simple variable types with defaults
variable "environment" {
  type    = string
  default = "development"
}

variable "replica_count" {
  type    = number
  default = 2
}

variable "enable_monitoring" {
  type    = bool
  default = false
}

# List variable
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Map variable
variable "tags" {
  type = map(string)
  default = {
    owner   = "my-team"
    project = "my-resource"
  }
}

# Object variable with nested types
variable "database" {
  type = object({
    instance_class    = string
    allocated_storage = number
    multi_az          = bool
  })
  default = {
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    multi_az          = false
  }
}

# Variable with validation
variable "environment" {
  type = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# Sensitive variable (masked in plan/apply output)
variable "db_password" {
  type      = string
  sensitive = true
}

# Output block
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.my-resource.id
}

# Sensitive output
output "db_connection_string" {
  value     = "postgresql://${var.db_user}:${var.db_password}@${aws_db_instance.my-resource.endpoint}/mydb"
  sensitive = true
}
```

```bash
# Show all outputs of root module
terraform output

# Show specific output value (raw, no quotes)
terraform output -raw instance_id

# Show output as JSON
terraform output -json

# Pass variable via CLI flag
terraform plan -var="environment=staging" -var="replica_count=3"

# Load from .tfvars file
terraform apply -var-file="production.tfvars"

# terraform.tfvars is loaded automatically
# production.tfvars:
# environment   = "production"
# replica_count = 5
# enable_monitoring = true
```

---

## Import & Move

```bash
# Import existing resource into state (classic, pre-1.5)
terraform import aws_instance.my-resource i-0abc123def456789
terraform import 'module.my-module.aws_s3_bucket.my-resource' my-bucket-name

# Generate configuration from import (Terraform 1.5+ / OpenTofu 1.6+)
terraform plan -generate-config-out=generated.tf
```

```hcl
# moved block – rename/refactor without destroy & recreate (Terraform 1.1+)
moved {
  from = aws_instance.old-name
  to   = aws_instance.my-resource
}

# Move into a module
moved {
  from = aws_s3_bucket.my-resource
  to   = module.my-module.aws_s3_bucket.my-resource
}

# import block – declarative import (Terraform 1.5+ / OpenTofu 1.6+)
import {
  id = "i-0abc123def456789"
  to = aws_instance.my-resource
}

import {
  id = "my-bucket-name"
  to = module.my-module.aws_s3_bucket.my-resource
}
```

---

## Backend Configuration

```hcl
# S3 backend (AWS)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-terraform-locks"   # state locking
  }
}

# Azure Blob Storage backend
terraform {
  backend "azurerm" {
    resource_group_name  = "my-rg-terraform"
    storage_account_name = "myterraformstate"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}

# Google Cloud Storage backend
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "production/state"
  }
}

# Terraform Cloud / HCP Terraform remote backend
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "my-workspace"
    }
  }
}

# Partial configuration (secrets passed via CLI or env)
# terraform init -backend-config="token=$TF_CLOUD_TOKEN"
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
    # access_key and secret_key passed via env vars or -backend-config
  }
}
```

```bash
# Re-initialize with new backend config
terraform init -reconfigure

# Migrate state from old to new backend
terraform init -migrate-state

# Pass backend config at init time
terraform init \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="key=production/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

---

## Linting & Security

```bash
# Built-in formatting and validation
terraform fmt -recursive          # auto-format all .tf files
terraform validate                 # check syntax and internal consistency

# tflint – pluggable Terraform linter
brew install tflint
tflint --init                      # download provider-specific rules
tflint                             # lint current directory
tflint --recursive                 # lint all modules

# tfsec – static security analysis (now part of trivy)
brew install tfsec
tfsec .
tfsec --format json . | jq

# trivy – comprehensive security scanner
brew install trivy
trivy config .                     # scan IaC configuration
trivy config --severity HIGH,CRITICAL .

# checkov – policy-as-code for IaC
pip install checkov
checkov -d .                       # scan directory
checkov -d . --framework terraform
checkov -d . --check CKV_AWS_2     # run specific check
checkov -d . --skip-check CKV_AWS_7,CKV_AWS_8

# infracost – cloud cost estimation
brew install infracost
infracost auth login
infracost breakdown --path .       # estimate monthly cost
infracost diff --path . \
  --compare-to infracost-base.json # compare cost changes
```

---

## Multi-Cloud Provider Examples

```hcl
# Required providers block
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# AWS provider
provider "aws" {
  region  = "us-east-1"
  profile = "my-aws-profile"        # use named AWS CLI profile
}

# AWS resource example
resource "aws_s3_bucket" "my-resource" {
  bucket = "my-app-assets-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = "my-resource"
  }
}

# Azure provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Azure resource example
resource "azurerm_resource_group" "my-resource" {
  name     = "my-rg-${var.environment}"
  location = "West Europe"
}

# GCP provider
provider "google" {
  project = var.gcp_project_id
  region  = "europe-west1"
}

# GCP resource example
resource "google_storage_bucket" "my-resource" {
  name          = "my-app-assets-${var.environment}"
  location      = "EU"
  force_destroy = false
  versioning {
    enabled = true
  }
}

# Multiple provider aliases (multi-region)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"
}

resource "aws_instance" "my-resource" {
  provider      = aws.eu-central-1
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
}
```

---

## Terraform Cloud / Enterprise

```bash
# Authenticate with Terraform Cloud / HCP Terraform
terraform login
terraform login app.terraform.io   # Terraform Enterprise

# Log out
terraform logout

# Trigger remote run via CLI
terraform plan                     # streams plan output from TFC
terraform apply                    # triggers run, waits for approval
```

```hcl
# Workspace with remote execution
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "my-workspace"         # single workspace
    }
  }
}

# Tag-based workspace selection (multiple workspaces)
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      tags = ["my-app", "production"]
    }
  }
}
```

```bash
# Set workspace variable via Terraform Cloud API
curl -s \
  --header "Authorization: Bearer $TF_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{
    "data": {
      "type": "vars",
      "attributes": {
        "key":       "db_password",
        "value":     "my-secret",
        "sensitive": true,
        "category":  "terraform"
      }
    }
  }' \
  https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/vars

# API-driven run (no local code needed)
curl -s \
  --header "Authorization: Bearer $TF_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{"data":{"type":"runs","relationships":{"workspace":{"data":{"type":"workspaces","id":"'$WORKSPACE_ID'"}}}}}' \
  https://app.terraform.io/api/v2/runs
```

---

## OpenTofu Specifics

```bash
# OpenTofu is the open-source fork of Terraform (MPL 2.0 → BUSL 1.1 split)
# OpenTofu is licensed under Apache 2.0 (SPDX: Apache-2.0)
# Project home: https://opentofu.org

# Drop-in replacement – use tofu instead of terraform
tofu init
tofu plan
tofu apply
tofu destroy

# Install via Homebrew
brew install opentofu

# Install specific version via tofuenv
brew install tofuenv
tofuenv install 1.8.0
tofuenv use 1.8.0

# State encryption at rest (OpenTofu 1.7+)
```

```hcl
# State encryption – AES-256-GCM with passphrase (OpenTofu 1.7+)
terraform {
  encryption {
    key_provider "pbkdf2" "my-key" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "my-method" {
      keys = key_provider.pbkdf2.my-key
    }

    state {
      method = method.aes_gcm.my-method
    }

    plan {
      method = method.aes_gcm.my-method
    }
  }
}

# Provider-defined functions (OpenTofu 1.8+)
# Providers can expose custom functions callable in HCL
output "parsed_arn" {
  value = provider::aws::arn_parse("arn:aws:s3:::my-bucket")
}

# tofu test – built-in testing framework
# tests/my_module.tftest.hcl
run "creates_bucket_with_correct_name" {
  command = plan

  variables {
    bucket_name = "my-test-bucket"
    environment = "test"
  }

  assert {
    condition     = aws_s3_bucket.my-resource.bucket == "my-test-bucket-test"
    error_message = "Bucket name does not match expected value"
  }
}
```

```bash
# Run OpenTofu tests
tofu test                         # run all tests in tests/ directory
tofu test -filter=tests/my_module.tftest.hcl
tofu test -verbose                # show all assertion results
```

---

## Tips & Tricks

```bash
# Increase parallelism for faster applies (default: 10)
terraform apply -parallelism=20

# Reduce parallelism to avoid API rate limits
terraform apply -parallelism=3

# Enable debug logging to trace provider issues
TF_LOG=DEBUG terraform apply 2>&1 | tee debug.log

# Interactive console for testing expressions and functions
terraform console
# > cidrsubnets("10.0.0.0/16", 4, 4, 4)
# > formatdate("YYYY-MM-DD", timestamp())
# > length(var.availability_zones)

# Generate dependency graph (requires graphviz)
brew install graphviz
terraform graph | dot -Tpng -o graph.png
terraform graph -type=plan | dot -Tsvg -o plan-graph.svg

# Useful shell aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tff='terraform fmt -recursive'
alias tfv='terraform validate'
alias tfs='terraform state list'
alias tfw='terraform workspace'

# .terraformignore – exclude files from TFC remote uploads
# (like .gitignore, lives in root module directory)
# .terraformignore:
# .git
# .github
# tests/
# *.png
# docs/
# **/*.md

# Lock provider versions (commit .terraform.lock.hcl)
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64

# Show providers required by current config
terraform providers

# Detect drift between state and real infrastructure
terraform plan -detailed-exitcode
# Exit code 0 = no changes, 1 = error, 2 = changes present

# Use JSON output for automation
terraform show -json | jq '.values.root_module.resources[].address'
terraform state list | xargs -I{} terraform state show {}

# Quick resource count per type
terraform state list | sed 's/\[.*//' | cut -d. -f1-2 | sort | uniq -c | sort -rn
```
