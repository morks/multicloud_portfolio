# Morpheus Data Cheat Sheet

## Overview

**Morpheus Data** is an enterprise hybrid cloud management platform for provisioning, managing, and governing resources across VMs, containers, and multiple clouds from a single pane of glass.

| | |
|---|---|
| **Strengths** | Full VM & container lifecycle management · broad cloud integrations (AWS, Azure, GCP, VMware, Nutanix…) · cost analytics · ServiceNow integration · on-prem deployable · built-in monitoring |
| **Weaknesses** | Complex initial setup · expensive enterprise licensing · steep learning curve · UI can be overwhelming · heavy resource footprint |
| **Best for** | Enterprise IT automation, multi-cloud VM provisioning, ITSM/ServiceNow integration, replacing vRA/vRealize, cost management across hybrid environments |

---

## Key Concepts

```bash
# Cloud Integration — connection to a cloud provider (AWS, Azure, GCP, VMware, OpenStack…)
# Instance        — a provisioned workload (VM, container, or app stack) managed by Morpheus
# App             — a multi-tier application composed of multiple instances
# Blueprint       — reusable template for provisioning apps (Terraform, ARM, CloudFormation, Helm…)
# Catalog         — self-service portal items that users can order (instances, apps, workflows)
# Policy          — governance rule applied at group, cloud, role, or tenant level
# Tenant          — isolated organizational unit with its own users, clouds, and catalog
# Role            — set of permissions assigned to users or service accounts
```

---

## Morpheus CLI — Installation & Auth

```bash
# Install on macOS via Homebrew
brew install morpheus-cli

# Install on Linux (RPM/DEB)
# https://docs.morpheusdata.com/en/latest/getting_started/morpheus_cli.html

# Add a remote appliance
morpheus remote add my-morpheus https://morpheus.example.com

# Use the remote (set as active)
morpheus remote use my-morpheus

# Login
morpheus login                          # interactive (prompts for username/password)
morpheus login --username admin         # specify user

# Show current user / appliance info
morpheus whoami
morpheus remote current

# Show CLI version and appliance version
morpheus version
```

---

## Instances & Apps

```bash
# List all instances
morpheus instances list

# Filter by status or cloud
morpheus instances list --status running
morpheus instances list --cloud "AWS - EU"

# Show instance details
morpheus instances get my-instance

# Provision a new instance (interactive)
morpheus instances add

# Start / stop / restart an instance
morpheus instances start my-instance
morpheus instances stop my-instance
morpheus instances restart my-instance

# Delete an instance
morpheus instances delete my-instance

# Tail instance logs
morpheus instances logs my-instance -f

# Execute a remote command on an instance
morpheus instances exec my-instance --command "uptime"

# List apps
morpheus apps list

# Show app details
morpheus apps get my-app

# Deploy an app from a blueprint
morpheus apps add

# Delete an app
morpheus apps delete my-app
```

---

## Clouds & Infrastructure

```bash
# List all cloud integrations
morpheus clouds list

# Show cloud details
morpheus clouds get "AWS - EU"

# Add a cloud integration (interactive)
morpheus clouds add

# Sync a cloud (refresh inventory)
morpheus clouds refresh "AWS - EU"

# Remove a cloud integration
morpheus clouds remove "AWS - EU"

# List hosts / VMs in a cloud
morpheus hosts list
morpheus hosts list --cloud "AWS - EU"

# Show host details
morpheus hosts get my-host

# List networks
morpheus networks list

# List resource pools / clusters
morpheus resource-pools list
```

---

## Blueprints & Catalog

```bash
# List available instance types in the library
morpheus library instance-types list

# Show details of an instance type
morpheus library instance-types get "Ubuntu 22.04"

# List layouts for an instance type
morpheus library layouts list --instance-type "Ubuntu 22.04"

# List blueprints
morpheus library blueprints list

# Show blueprint details
morpheus library blueprints get my-blueprint

# List catalog items (self-service)
morpheus catalog list

# Add a catalog item
morpheus catalog add

# Order a catalog item
morpheus catalog order my-item
```

---

## Policies & Governance

```bash
# List all policies
morpheus policies list

# Show policy details
morpheus policies get my-policy

# Add a policy (interactive)
morpheus policies add

# Policy types include:
# - Max Instances      (limit instance count per user/group)
# - Instance Quota     (resource limits: CPU, RAM, storage)
# - Expiration         (auto-expire instances after N days)
# - Naming Convention  (enforce naming patterns)
# - Approval          (require approval before provisioning)
# - Budget            (spending limits per cloud/tenant)

# Delete a policy
morpheus policies delete my-policy

# Apply a policy to a tenant
morpheus tenants update my-tenant --policies my-policy
```

---

## Users, Roles & Tenants

```bash
# List users
morpheus users list

# Show user details
morpheus users get admin

# Add a user
morpheus users add \
  --username john.doe \
  --email john.doe@example.com \
  --role "Standard User"

# Delete a user
morpheus users delete john.doe

# List roles
morpheus roles list

# Show role permissions
morpheus roles get "Standard User"

# Add a role
morpheus roles add --name "DevOps Engineer"

# List tenants (sub-tenants / accounts)
morpheus tenants list

# Add a tenant
morpheus tenants add --name "Project Alpha" --subdomain alpha

# Delete a tenant
morpheus tenants delete "Project Alpha"
```

---

## API & Automation

```bash
# Generate an API access token
morpheus api-token

# Or use username/password to get a token via REST
TOKEN=$(curl -s -X POST https://morpheus.example.com/oauth/token \
  -d "grant_type=password&scope=write&client_id=morph-api" \
  -d "username=admin&password=secret" | jq -r '.access_token')

# List instances via REST API
curl -s https://morpheus.example.com/api/instances \
  -H "Authorization: Bearer $TOKEN" | jq '.instances[].name'

# Provision an instance via REST API
curl -s -X POST https://morpheus.example.com/api/instances \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "instance": {
      "name": "my-vm",
      "instanceType": {"code": "ubuntu"},
      "layout": {"id": 105},
      "plan": {"id": 76}
    },
    "config": {"resourcePoolId": 1}
  }' | jq '.instance.id'

# Delete an instance via REST API
curl -s -X DELETE https://morpheus.example.com/api/instances/42 \
  -H "Authorization: Bearer $TOKEN"

# Ansible Tower / AWX integration
# Configure in Morpheus: Admin → Integrations → Ansible Tower
# Then use in provisioning workflows as a task type
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [docs.morpheusdata.com](https://docs.morpheusdata.com/) | Morpheus Data documentation — provisioning, cloud integrations, policies, automation, and API reference. |
| **Morpheus CLI GitHub** | [github.com/gomorpheus/morpheus-cli](https://github.com/gomorpheus/morpheus-cli) | Open-source Morpheus CLI source code, releases, and usage examples. |
| **Terraform Provider (Morpheus)** | [registry.terraform.io/gomorpheus/morpheus](https://registry.terraform.io/providers/gomorpheus/morpheus/latest/docs) | Official Morpheus Terraform provider — manages instances, clouds, groups, policies, library items, and users as code. |
| **OpenTofu Provider (Morpheus)** | [search.opentofu.org/gomorpheus/morpheus](https://search.opentofu.org/provider/gomorpheus/morpheus/latest) | Morpheus provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
