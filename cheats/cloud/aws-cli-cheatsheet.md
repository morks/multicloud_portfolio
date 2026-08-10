# AWS CLI Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install awscli

# Configure (Access Key, Secret, Region, output format)
aws configure

# Set default output format permanently to table (~/.aws/config)
aws configure set output table

# For a specific profile only
aws configure set output table --profile mein-profil

# Alternative: session-wide via environment variable
export AWS_DEFAULT_OUTPUT=table

# Configure with named profile
aws configure --profile mein-profil

# Show current profile
aws configure list

# SSO Login (for Accenture Landing Zone)
aws sso login --profile mein-profil

# Check current identity
aws sts get-caller-identity
```

---

## IAM – Identity & Access Management

```bash
# List all IAM users
aws iam list-users

# Create IAM user
aws iam create-user --user-name max-mustermann

# Create access key for user
aws iam create-access-key --user-name max-mustermann

# Show groups for a user
aws iam list-groups-for-user --user-name max-mustermann

# Check policies attached to own account
aws iam list-attached-user-policies --user-name max-mustermann

# Assume a role (AssumeRole)
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/MeineRolle \
  --role-session-name meine-session
```

---

## EC2 – Virtual Machines

```bash
# List all instances (with Name tag and status)
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],State.Name,InstanceId]' \
  --output table

# Start instance
aws ec2 start-instances --instance-ids i-0abc123def456

# Stop instance
aws ec2 stop-instances --instance-ids i-0abc123def456

# Terminate instance
aws ec2 terminate-instances --instance-ids i-0abc123def456

# Launch new instance
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name mein-key \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678

# Connect to instance via EC2 Instance Connect
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-0abc123def456 \
  --instance-os-user ec2-user \
  --ssh-public-key file://~/.ssh/id_rsa.pub

# List security groups
aws ec2 describe-security-groups --output table

# List key pairs
aws ec2 describe-key-pairs
```

---

## S3 – Object Storage

```bash
# List all buckets
aws s3 ls

# Show bucket contents
aws s3 ls s3://mein-bucket/

# Upload file
aws s3 cp meine-datei.txt s3://mein-bucket/pfad/

# Download file
aws s3 cp s3://mein-bucket/pfad/meine-datei.txt ./

# Sync folder (local → S3)
aws s3 sync ./lokaler-ordner s3://mein-bucket/ziel/

# Delete file/folder
aws s3 rm s3://mein-bucket/pfad/meine-datei.txt

# Create bucket
aws s3 mb s3://neuer-bucket --region eu-central-1

# Show bucket size
aws s3 ls s3://mein-bucket --recursive --human-readable --summarize
```

---

## VPC – Network

```bash
# List all VPCs
aws ec2 describe-vpcs --output table

# List subnets for a VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-12345678" \
  --output table

# Show security group rules
aws ec2 describe-security-groups \
  --group-ids sg-12345678

# List internet gateways
aws ec2 describe-internet-gateways
```

---

## RDS – Managed Databases

```bash
# List all DB instances
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]' \
  --output table

# Start / stop DB instance
aws rds start-db-instance --db-instance-identifier meine-db
aws rds stop-db-instance --db-instance-identifier meine-db

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier meine-db \
  --db-snapshot-identifier mein-snapshot
```

---

## EKS – Kubernetes

```bash
# List clusters
aws eks list-clusters

# Set kubeconfig for cluster
aws eks update-kubeconfig \
  --name mein-cluster \
  --region eu-central-1

# List node groups for a cluster
aws eks list-nodegroups --cluster-name mein-cluster
```

---

## CloudFormation / Terraform

```bash
# List stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Stack events (error diagnosis)
aws cloudformation describe-stack-events \
  --stack-name mein-stack

# Delete stack
aws cloudformation delete-stack --stack-name mein-stack
```

---

## Useful General Options

```bash
# Output as JSON (default)
aws ec2 describe-instances --output json

# Output as table
aws ec2 describe-instances --output table

# Output as text (for scripts)
aws ec2 describe-instances --output text

# JMESPath query – specific fields only
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId'

# Run with specific profile
aws s3 ls --profile mein-profil

# Run with specific region
aws ec2 describe-instances --region us-east-1

# Dry run – test command without executing
aws ec2 run-instances --dry-run ...

# Enable debug output
aws ec2 describe-instances --debug
```

---

## Common Filter Patterns

```bash
# Filter instances by tag
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production"

# Running instances only
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running"

# Find resources by Name tag
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mein-server*"
```
