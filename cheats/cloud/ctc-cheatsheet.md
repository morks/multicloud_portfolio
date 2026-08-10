# CTC Cheat Sheet (Telekom Cloud / Open Telekom Cloud)

> The Open Telekom Cloud (OTC) is based on OpenStack. CLI tools: `otc` (proprietary client) as well as the standard OpenStack CLIs `openstack`, `swift`, `nova`, `neutron`, etc.

## Installation & Setup

```bash
# Install otc-cli (Go binary)
brew install iits-consulting/tap/otc-cli

# Alternative via GitHub releases
curl -Lo otc https://github.com/iits-consulting/otc-cli/releases/latest/download/otc-linux-amd64
chmod +x otc && sudo mv otc /usr/local/bin/

# OpenStack client (standard tools)
pip install python-openstackclient

# Check version
otc --version
openstack --version

# Configuration wizard (interactive)
otc configure

# Show configuration
otc configure show

# Source openstack rc file (downloaded from OTC console)
source ~/Downloads/MyProject-openrc.sh

# Set environment variables directly
export OS_AUTH_URL=https://iam.eu-de.otc.t-systems.com/v3
export OS_PROJECT_NAME=eu-de_<projektname>
export OS_USER_DOMAIN_NAME=OTC-EU-DE-<domainid>
export OS_USERNAME=<username>
export OS_PASSWORD=<password>
export OS_REGION_NAME=eu-de
```

---

## Authentication & Projects

```bash
# Request token (verify auth works)
openstack token issue

# Show current project
openstack project show $OS_PROJECT_NAME

# List all projects
openstack project list

# List domains
openstack domain list

# List users (admin rights required)
openstack user list

# Check own roles
openstack role assignment list --user $OS_USERNAME --names

# Token expiry and details
openstack token issue -f json | jq '.expires'
```

---

## Compute – ECS (Elastic Cloud Server)

```bash
# List instances
openstack server list
otc ecs list

# Show instance details
openstack server show <server-name-or-id>

# Create instance
openstack server create \
  --image "Standard_Debian_12_latest" \
  --flavor s3.medium.4 \
  --network <network-name> \
  --key-name my-keypair \
  --security-group default \
  my-server

# Start / stop / restart instance
openstack server start <server-id>
openstack server stop <server-id>
openstack server reboot <server-id>

# Delete instance
openstack server delete <server-id>

# Create SSH key
openstack keypair create my-keypair > my-keypair.pem
chmod 400 my-keypair.pem

# Import SSH key
openstack keypair create --public-key ~/.ssh/id_rsa.pub my-keypair

# List keypairs
openstack keypair list

# Available flavors (VM types)
openstack flavor list --public

# Available images
openstack image list --status active
```

---

## Network – VPC & Neutron

```bash
# List VPCs / networks
openstack network list
otc vpc list

# Create VPC
otc vpc create --name my-vpc --cidr 10.0.0.0/16

# List subnets
openstack subnet list

# Create subnet
openstack subnet create \
  --network <network-name> \
  --subnet-range 10.0.1.0/24 \
  --gateway 10.0.1.1 \
  --dns-nameserver 100.125.4.25 \
  my-subnet

# Assign floating IP
openstack floating ip create admin_external_net
openstack server add floating ip <server-id> <floating-ip>

# List floating IPs
openstack floating ip list

# List security groups
openstack security group list

# Create security group
openstack security group create my-sg --description "HTTP+SSH"

# Add rule (SSH)
openstack security group rule create \
  --protocol tcp --dst-port 22 \
  --remote-ip 0.0.0.0/0 my-sg

# Add rule (HTTP)
openstack security group rule create \
  --protocol tcp --dst-port 80 \
  --remote-ip 0.0.0.0/0 my-sg

# List / create router
openstack router list
openstack router create my-router
openstack router set --external-gateway admin_external_net my-router
openstack router add subnet my-router my-subnet

# List ELB (load balancers)
otc elb list
```

---

## Object Storage – OBS (OpenStack Swift)

```bash
# List containers (buckets)
openstack container list
swift list

# Create container
openstack container create my-container

# Upload objects
openstack object create my-container lokale-datei.txt
swift upload my-container lokale-datei.txt

# List objects
openstack object list my-container

# Download object
openstack object save my-container datei.txt
swift download my-container datei.txt

# Delete object
openstack object delete my-container datei.txt

# Delete container (must be empty)
openstack container delete my-container

# Make container publicly accessible
swift post -r '.r:*' my-container

# Show statistics
swift stat
swift stat my-container
```

---

## Block Storage – EVS (Cinder)

```bash
# List volumes
openstack volume list
otc evs list

# Create volume (50 GB SSD)
openstack volume create \
  --size 50 \
  --type SSD \
  --availability-zone eu-de-01 \
  my-volume

# Attach volume to server
openstack server add volume <server-id> <volume-id>

# Detach volume
openstack server remove volume <server-id> <volume-id>

# Create snapshot
openstack volume snapshot create \
  --volume <volume-id> \
  --name my-snapshot

# Restore volume from snapshot
openstack volume create \
  --snapshot <snapshot-id> \
  --size 50 restored-volume

# Delete volume
openstack volume delete <volume-id>
```

---

## CCE – Cloud Container Engine (Kubernetes)

```bash
# List clusters
otc cce cluster list

# Create cluster
otc cce cluster create \
  --name my-cce-cluster \
  --flavor cce.s2.small \
  --vpc-id <vpc-id> \
  --subnet-id <subnet-id>

# Show cluster details
otc cce cluster show <cluster-id>

# Download kubeconfig
otc cce cluster get-credentials <cluster-id> > ~/.kube/config
# or
otc cce cluster get-credentials <cluster-id> --kubeconfig ~/.kube/otc-config.yaml

# List node pools
otc cce nodepool list --cluster-id <cluster-id>

# List nodes
otc cce node list --cluster-id <cluster-id>
```

---

## DNS & Domain

```bash
# List zones
openstack zone list
otc dns zone list

# Create zone (public)
openstack zone create \
  --type public \
  --email admin@meinedomain.de \
  meinedomain.de.

# Create DNS record (A record)
openstack recordset create \
  --type A \
  --records "1.2.3.4" \
  meinedomain.de. www.meinedomain.de.

# List records of a zone
openstack recordset list meinedomain.de.

# Delete zone
openstack zone delete meinedomain.de.
```

---

## IAM – Identity Access Management

```bash
# Create user
openstack user create \
  --domain <domain-id> \
  --password "SecurePass123" \
  new-user

# Assign user to a group
openstack group add user <group-id> <user-id>

# Create group
openstack group create my-group

# Assign role
openstack role add \
  --project <project-id> \
  --user <user-id> \
  <role-name>

# Create credentials (AK/SK) – for programmatic access
# In the OTC console: IAM → My Credentials → Access Keys

# Set environment variables for AK/SK
export AWS_ACCESS_KEY_ID=<ak>
export AWS_SECRET_ACCESS_KEY=<sk>
# OBS can then be used via S3-compatible API
```

---

## Monitoring & CES (Cloud Eye)

```bash
# List metrics (via REST API, as there is no direct CLI command)
# Base URL: https://ces.eu-de.otc.t-systems.com/v1.0/<project-id>/metrics

# Show OTC quota
otc quota list

# Tag resources
openstack server set --tag Environment=Production <server-id>
openstack server show <server-id> -f json | jq '.tags'
```

---

## Terraform with OTC

```bash
# Provider in main.tf
cat << 'EOF' > provider.tf
terraform {
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.36"
    }
  }
}

provider "opentelekomcloud" {
  auth_url    = "https://iam.eu-de.otc.t-systems.com/v3"
  tenant_name = var.project_name
  domain_name = var.domain_name
  user_name   = var.username
  password    = var.password
  region      = "eu-de"
}
EOF

terraform init
terraform plan
terraform apply
```

---

## Tips & Tricks

```bash
# JSON output for scripting
openstack server list -f json | jq '.[].Name'

# Customize table output
openstack server list -c Name -c Status -c Networks

# Find all resources of a project (quota overview)
openstack quota show

# Check region in RC file
env | grep OS_

# Retrieve OTC-specific API endpoints
openstack catalog list

# Debug error messages
openstack --debug server list 2>&1 | head -50

# OTC documentation
# https://docs.otc.t-systems.com/
# https://github.com/opentelekomcloud/python-otcextensions
```
