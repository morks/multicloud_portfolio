# IBM Cloud CLI Cheat Sheet

## Overview

**IBM Cloud** is IBM's enterprise cloud platform focused on hybrid cloud (OpenShift), regulated industries, and Watson AI services.

| | |
|---|---|
| **Strengths** | Best-in-class managed OpenShift (ROKS) · financial services cloud certifications · Watson AI integrations · mainframe & on-prem connectivity · strong compliance posture |
| **Weaknesses** | Smaller ecosystem than hyperscalers · higher cost · less developer-friendly tooling · complex pricing model |
| **Best for** | Regulated industries (finance, healthcare, government), OpenShift workloads, Watson/watsonx AI, mainframe-to-cloud integration |

---

## Installation & Setup

```bash
# Install via curl (Linux/macOS)
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh    # Linux
curl -fsSL https://clis.cloud.ibm.com/install/osx | sh      # macOS

# Install via Homebrew (macOS)
brew install ibmcloud-cli

# Show version
ibmcloud version

# Interactive login (browser SSO)
ibmcloud login --sso

# Login with API key
ibmcloud login --apikey <API_KEY>

# Login with API key via env var
export IBMCLOUD_API_KEY="your-api-key"
ibmcloud login

# Target a resource group and region
ibmcloud target -g my-resource-group -r eu-de

# Target Cloud Foundry org and space (if used)
ibmcloud target --cf-api https://api.eu-de.cf.cloud.ibm.com
ibmcloud target -o my-org -s my-space

# Show current target
ibmcloud target

# Configure CLI settings
ibmcloud config --check-version=false
ibmcloud config --locale en_US

# Logout
ibmcloud logout
```

---

## Account & Resources

```bash
# List all accounts
ibmcloud account list

# Switch account
ibmcloud account switch <ACCOUNT_ID>

# List resource groups
ibmcloud resource group-list

# Create resource group
ibmcloud resource group-create my-rg

# List all service instances
ibmcloud resource service-instances

# List instances in a specific group
ibmcloud resource service-instances -g my-resource-group

# Search resources by name or tag
ibmcloud resource search "name:my-app"
ibmcloud resource search 'tags:"env:prod"'

# List all resource instances of a type
ibmcloud resource service-instances --service-name cloud-object-storage

# Show details of a service instance
ibmcloud resource service-instance my-cos-instance

# List available services in catalog
ibmcloud catalog service-marketplace

# List available plans for a service
ibmcloud catalog service cloud-object-storage

# List all regions
ibmcloud regions
```

---

## IKS – IBM Kubernetes Service

```bash
# Install kubernetes-service plugin
ibmcloud plugin install kubernetes-service

# List all clusters
ibmcloud ks cluster ls

# Create a standard cluster
ibmcloud ks cluster create classic \
  --name my-cluster \
  --zone fra02 \
  --flavor b3c.4x16 \
  --workers 3 \
  --public-vlan <VLAN_ID> \
  --private-vlan <VLAN_ID>

# Create VPC cluster
ibmcloud ks cluster create vpc-gen2 \
  --name my-vpc-cluster \
  --zone eu-de-1 \
  --flavor bx2.4x16 \
  --workers 3 \
  --vpc-id <VPC_ID> \
  --subnet-id <SUBNET_ID>

# Show cluster details
ibmcloud ks cluster get --cluster my-cluster

# Download kubeconfig
ibmcloud ks cluster config --cluster my-cluster
export KUBECONFIG=~/.bluemix/plugins/kubernetes-service/clusters/my-cluster/kube-config.yml

# List worker nodes
ibmcloud ks workers --cluster my-cluster

# List worker pools
ibmcloud ks worker-pool ls --cluster my-cluster

# Resize a worker pool
ibmcloud ks worker-pool resize \
  --cluster my-cluster \
  --worker-pool default \
  --size-per-zone 5

# List available Kubernetes versions
ibmcloud ks versions

# Update cluster master
ibmcloud ks cluster master update \
  --cluster my-cluster \
  --version 1.30

# List available zones for classic
ibmcloud ks zone ls --provider classic

# Delete cluster
ibmcloud ks cluster rm --cluster my-cluster
```

---

## ROKS – Red Hat OpenShift on IBM Cloud

```bash
# List OpenShift clusters
ibmcloud oc cluster ls

# Create ROKS cluster (VPC)
ibmcloud oc cluster create vpc-gen2 \
  --name my-roks \
  --version 4.14_openshift \
  --zone eu-de-1 \
  --flavor bx2.4x16 \
  --workers 3 \
  --vpc-id <VPC_ID> \
  --subnet-id <SUBNET_ID>

# Download kubeconfig / oc config
ibmcloud oc cluster config --cluster my-roks --admin

# List available OpenShift versions
ibmcloud oc versions

# List installed add-ons
ibmcloud oc addon ls --cluster my-roks

# Enable an add-on (e.g., OpenShift GitOps)
ibmcloud oc addon enable openshift-gitops --cluster my-roks

# Disable an add-on
ibmcloud oc addon disable openshift-gitops --cluster my-roks

# Get cluster ingress subdomain
ibmcloud oc cluster get --cluster my-roks | grep Ingress
```

---

## Cloud Object Storage (COS)

```bash
# Install COS plugin
ibmcloud plugin install cloud-object-storage

# Target a COS instance
ibmcloud cos config crn --crn <COS_CRN>
ibmcloud cos config endpoint-url --url https://s3.eu-de.cloud-object-storage.appdomain.cloud

# List buckets
ibmcloud cos bucket-list

# Create bucket
ibmcloud cos bucket-create \
  --bucket my-bucket \
  --ibm-service-instance-id <INSTANCE_ID> \
  --region eu-de

# Delete bucket
ibmcloud cos bucket-delete --bucket my-bucket --force

# Upload object
ibmcloud cos object-put \
  --bucket my-bucket \
  --key my-file.txt \
  --body /local/path/my-file.txt

# Download object
ibmcloud cos object-get \
  --bucket my-bucket \
  --key my-file.txt \
  my-file-local.txt

# List objects in bucket
ibmcloud cos objects --bucket my-bucket

# Delete object
ibmcloud cos object-delete --bucket my-bucket --key my-file.txt --force

# Create HMAC credentials
ibmcloud resource service-key-create my-hmac-key Writer \
  --instance-name my-cos-instance \
  --parameters '{"HMAC": true}'
```

---

## IAM & Service Keys

```bash
# List service IDs
ibmcloud iam service-ids

# Create a service ID
ibmcloud iam service-id-create my-service-id \
  --description "CI/CD service account"

# Create an API key for a service ID
ibmcloud iam service-api-key-create my-api-key my-service-id \
  --description "Deployment key"

# Create a user API key
ibmcloud iam api-key-create my-user-key \
  --description "My API key" \
  --file my-key.json

# List API keys
ibmcloud iam api-keys

# Delete API key
ibmcloud iam api-key-delete my-user-key

# List access groups
ibmcloud iam access-groups

# Create access group
ibmcloud iam access-group-create my-group \
  --description "Platform engineers"

# Add user to access group
ibmcloud iam access-group-user-add my-group user@example.com

# Create IAM policy for service ID
ibmcloud iam service-policy-create my-service-id \
  --roles Viewer \
  --service-name cloud-object-storage

# List policies for a service ID
ibmcloud iam service-policies my-service-id
```

---

## Container Registry (ICR)

```bash
# Install container-registry plugin
ibmcloud plugin install container-registry

# Login to IBM Container Registry
ibmcloud cr login

# List namespaces
ibmcloud cr namespace-list

# Create namespace
ibmcloud cr namespace-add my-namespace

# Delete namespace
ibmcloud cr namespace-rm my-namespace --force

# List images
ibmcloud cr image-list

# List images in a namespace
ibmcloud cr image-list --restrict my-namespace

# Delete image
ibmcloud cr image-rm de.icr.io/my-namespace/my-image:tag

# Show image vulnerabilities
ibmcloud cr va de.icr.io/my-namespace/my-image:tag

# Check quota
ibmcloud cr quota

# Tag and push image
docker tag my-app:latest de.icr.io/my-namespace/my-app:latest
docker push de.icr.io/my-namespace/my-app:latest
```

---

## Useful Plugins

```bash
# List installed plugins
ibmcloud plugin list

# Update all plugins
ibmcloud plugin update --all

# Install key plugins
ibmcloud plugin install kubernetes-service       # IKS + ROKS (ibmcloud ks / oc)
ibmcloud plugin install container-registry       # ICR (ibmcloud cr)
ibmcloud plugin install cloud-object-storage     # COS (ibmcloud cos)
ibmcloud plugin install schematics               # Terraform-as-a-Service
ibmcloud plugin install observe-service          # Activity Tracker, LogDNA, Sysdig
ibmcloud plugin install vpc-infrastructure       # VPC resources (ibmcloud is)
ibmcloud plugin install key-protect              # IBM Key Protect (ibmcloud kp)

# Use IBM Schematics (managed Terraform)
ibmcloud schematics workspace list
ibmcloud schematics workspace new --file workspace.json
ibmcloud schematics plan --id <WORKSPACE_ID>
ibmcloud schematics apply --id <WORKSPACE_ID>

# VPC infrastructure
ibmcloud is vpcs
ibmcloud is instances
ibmcloud is subnets

# Show plugin details
ibmcloud plugin show kubernetes-service
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [cloud.ibm.com/docs](https://cloud.ibm.com/docs) | IBM Cloud documentation — all services, APIs, tutorials, and architecture guides. |
| **IBM Cloud CLI Reference** | [cloud.ibm.com/docs/cli](https://cloud.ibm.com/docs/cli?topic=cli-ibmcloud_cli) | Complete `ibmcloud` CLI command reference with all plugins and parameters. |
| **Terraform Provider (IBM Cloud)** | [registry.terraform.io/IBM-Cloud/ibm](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs) | Official IBM Cloud Terraform provider — manages IKS, VPC, COS, IAM, and all IBM Cloud services. |
| **OpenTofu Provider (IBM Cloud)** | [search.opentofu.org/IBM-Cloud/ibm](https://search.opentofu.org/provider/IBM-Cloud/ibm/latest) | IBM Cloud provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
