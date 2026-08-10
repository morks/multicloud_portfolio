# STACKIT CLI Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS via Homebrew)
brew install stackitcloud/tap/stackit

# Alternative: download binary directly
# https://github.com/stackitcloud/stackit-cli/releases

# Login (opens browser for SSO)
stackit auth login

# Login via Service Account Key (CI/CD)
stackit auth activate-service-account

# Show current configuration
stackit config list

# Set active project
stackit config set --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Set active organization
stackit config set --organization-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Show CLI version
stackit --version

# Help
stackit --help
stackit <command> --help
```

---

## Projects & Organizations

```bash
# List all projects
stackit project list

# Create project
stackit project create \
  --name "My Project" \
  --parent-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Show project details
stackit project describe --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Update project (rename)
stackit project update \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --name "New Name"

# Delete project
stackit project delete --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# List members of a project
stackit project member list \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## SKE – STACKIT Kubernetes Engine

```bash
# List clusters
stackit ske cluster list

# Available Kubernetes versions
stackit ske options kubernetes-versions

# Create cluster (interactive)
stackit ske cluster create \
  --name my-cluster \
  --kubernetes-version 1.30

# Show cluster details
stackit ske cluster describe --name my-cluster

# Retrieve kubeconfig
stackit ske kubeconfig create \
  --cluster-name my-cluster \
  --filepath ~/.kube/config

# Update cluster (e.g. K8s version)
stackit ske cluster update \
  --name my-cluster \
  --kubernetes-version 1.31

# Delete cluster
stackit ske cluster delete --name my-cluster
```

---

## Server Backup Manager

```bash
# List backup jobs
stackit server-backup backup-job list

# List backup jobs for a server
stackit server-backup backup-job list \
  --server-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# List backups
stackit server-backup backup list \
  --server-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Create backup
stackit server-backup backup create \
  --server-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --backup-job-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Object Storage

```bash
# List all buckets
stackit object-storage bucket list

# Create bucket
stackit object-storage bucket create --bucket-name my-bucket

# Show bucket details
stackit object-storage bucket describe --bucket-name my-bucket

# Delete bucket
stackit object-storage bucket delete --bucket-name my-bucket

# Create credentials (access key) for object storage
stackit object-storage credentials-group create \
  --credentials-group-name my-credentials

# List credentials
stackit object-storage credentials-group list

# Create access key
stackit object-storage access-key create \
  --credentials-group-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

> Note: STACKIT Object Storage is S3-compatible — the `aws s3` CLI with
> `--endpoint-url https://object.storage.eu01.onstackit.cloud` works as well.

---

## DNS

```bash
# List DNS zones
stackit dns zone list

# Create DNS zone
stackit dns zone create \
  --name "my-domain.de" \
  --dns-name "my-domain.de."

# Describe DNS zone
stackit dns zone describe --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# List DNS records
stackit dns record-set list \
  --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Create A record
stackit dns record-set create \
  --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --name "www" \
  --type A \
  --records "1.2.3.4" \
  --ttl 300

# Delete record
stackit dns record-set delete \
  --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --record-set-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Load Balancer

```bash
# List load balancers
stackit load-balancer list

# Create load balancer (via payload file)
stackit load-balancer create --payload @payload.json

# Describe load balancer
stackit load-balancer describe --name my-lb

# Delete load balancer
stackit load-balancer delete --name my-lb

# Available options/plans
stackit load-balancer options
```

---

## PostgreSQL Flex (Managed DB)

```bash
# List instances
stackit postgresflex instance list

# Create instance
stackit postgresflex instance create \
  --name my-db \
  --flavor-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --version 15

# Describe instance
stackit postgresflex instance describe \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Create database in an instance
stackit postgresflex database create \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --name my-schema

# Create user
stackit postgresflex user create \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --username db-user

# Delete instance
stackit postgresflex instance delete \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Show available flavors (sizes)
stackit postgresflex options flavors
```

---

## MariaDB Flex

```bash
# List instances
stackit mariadb instance list

# Create instance
stackit mariadb instance create \
  --name my-mariadb \
  --flavor-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --version 10.11

# Describe instance
stackit mariadb instance describe \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Delete instance
stackit mariadb instance delete \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Secrets Manager

```bash
# List instances
stackit secrets-manager instance list

# Create instance
stackit secrets-manager instance create --name my-vault

# Create user for Secrets Manager
stackit secrets-manager user create \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --description "my service user"

# List users
stackit secrets-manager user list \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Service Accounts & IAM

```bash
# List service accounts
stackit service-account list

# Create service account
stackit service-account create --email my-sa@my-project.iam.stackit.cloud

# Create service account key
stackit service-account key create \
  --service-account-email my-sa@my-project.iam.stackit.cloud

# List keys
stackit service-account key list \
  --service-account-email my-sa@my-project.iam.stackit.cloud

# Add project member
stackit project member add \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --subject my-sa@my-project.iam.stackit.cloud \
  --role editor
```

---

## Useful General Options

```bash
# Output format: pretty (default), json, yaml
stackit ske cluster list --output-format json
stackit project list --output-format yaml

# Override project ID globally for a session
stackit ske cluster list --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Async operations (do not wait for completion)
stackit ske cluster create --name my-cluster --async

# Show configuration file
cat ~/.stackit/config.json

# Reset configuration
stackit config unset --project-id
stackit config unset --organization-id

# Install autocomplete (bash/zsh)
stackit completion bash >> ~/.bashrc
stackit completion zsh >> ~/.zshrc
```
