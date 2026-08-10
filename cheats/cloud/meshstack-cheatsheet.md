# MeshStack Cheat Sheet (meshcloud)

## Installation & Setup

```bash
# Install meshStack CLI via npm
npm install -g @meshcloud/meshstack-cli

# Alternatively: download binary directly (Linux/macOS)
curl -Lo meshstack https://downloads.meshcloud.io/meshstack-cli/latest/meshstack-linux-amd64
chmod +x meshstack && sudo mv meshstack /usr/local/bin/

# Check installed version
meshstack --version

# Login to your meshStack instance (opens browser)
meshstack login --url https://my-meshstack.example.com

# Login with a personal API key (non-interactive)
meshstack login \
  --url https://my-meshstack.example.com \
  --client-id my-client-id \
  --client-secret my-client-secret

# Configure the default API endpoint persistently
meshstack config set endpoint https://my-meshstack.example.com

# Show current configuration
meshstack config get

# Use a named profile for different environments
meshstack config set endpoint https://my-meshstack-prod.example.com --profile prod
meshstack config set endpoint https://my-meshstack-dev.example.com --profile dev
meshstack login --profile prod

# List available commands
meshstack --help
```

---

## Workspaces

```bash
# List all workspaces
meshstack workspace list

# Get details of a specific workspace
meshstack workspace get my-workspace

# Create a new workspace
meshstack workspace create my-workspace \
  --display-name "My Workspace" \
  --tags env=production,team=platform

# Delete a workspace
meshstack workspace delete my-workspace

# List members of a workspace
meshstack workspace member list --workspace my-workspace

# Add a member to a workspace
meshstack workspace member add \
  --workspace my-workspace \
  --user user@example.com \
  --role admin

# Remove a member from a workspace
meshstack workspace member remove \
  --workspace my-workspace \
  --user user@example.com

# Show workspace tags
meshstack workspace get my-workspace --format json | jq '.tags'

# Update workspace tags via API
curl -X PATCH \
  -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tags": {"env": "production", "costcenter": "1234"}}' \
  https://my-meshstack.example.com/api/meshobjects/meshworkspaces/my-workspace

# List workspace quota assignments
meshstack workspace quota list --workspace my-workspace

# Assign a payment method to a workspace
meshstack workspace payment-method assign \
  --workspace my-workspace \
  --payment-method-id my-payment-method
```

---

## Projects & Landing Zones

```bash
# List all projects (across all workspaces)
meshstack project list

# List projects in a specific workspace
meshstack project list --workspace my-workspace

# Get details of a project
meshstack project get my-project --workspace my-workspace

# Create a new project
meshstack project create my-project \
  --workspace my-workspace \
  --display-name "My Project" \
  --tags env=dev,app=my-app

# Delete a project
meshstack project delete my-project --workspace my-workspace

# Assign a landing zone to a project
meshstack project landing-zone assign \
  --project my-project \
  --workspace my-workspace \
  --platform my-platform \
  --landing-zone my-landing-zone

# List landing zones available for a platform
meshstack landing-zone list --platform my-platform

# Get replication status of a project
meshstack project replication-status \
  --project my-project \
  --workspace my-workspace

# Show project bindings (user role assignments)
meshstack project binding list \
  --project my-project \
  --workspace my-workspace

# Add a project binding (assign user role)
meshstack project binding create \
  --project my-project \
  --workspace my-workspace \
  --user user@example.com \
  --role projectUser

# Remove a project binding
meshstack project binding delete \
  --project my-project \
  --workspace my-workspace \
  --user user@example.com

# Set project-level quota
meshstack project quota set \
  --project my-project \
  --workspace my-workspace \
  --platform my-platform \
  --quota-key vCPU \
  --quota-value 16
```

---

## Platforms & Locations

```bash
# List all registered platforms
meshstack platform list

# Get details of a specific platform
meshstack platform get my-platform

# List available locations / regions for a platform
meshstack location list --platform my-platform

# Show platform access status for a workspace
meshstack platform access list --workspace my-workspace

# Request access to a platform for a workspace
meshstack platform access request \
  --workspace my-workspace \
  --platform my-platform \
  --location my-location

# List all tenants for a specific platform
meshstack tenant list --platform my-platform

# Show platform configuration details via API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  https://my-meshstack.example.com/api/meshobjects/meshplatforms/my-platform

# List available landing zones per platform
meshstack landing-zone list --platform my-platform

# Show the full platform inventory (all locations + platforms)
meshstack platform list --format table
meshstack location list --format table
```

---

## Tenants

```bash
# List all tenants (cloud accounts/subscriptions/projects)
meshstack tenant list

# List tenants for a specific workspace
meshstack tenant list --workspace my-workspace

# List tenants for a specific project
meshstack tenant list \
  --workspace my-workspace \
  --project my-project

# Get details of a specific tenant
meshstack tenant get \
  --workspace my-workspace \
  --project my-project \
  --platform my-platform \
  --location my-location

# Check tenant replication status
meshstack tenant replication-status \
  --workspace my-workspace \
  --project my-project \
  --platform my-platform

# Force replication of a tenant (re-apply landing zone)
meshstack tenant replicate \
  --workspace my-workspace \
  --project my-project \
  --platform my-platform \
  --location my-location

# List tenant tags
meshstack tenant get \
  --workspace my-workspace \
  --project my-project \
  --platform my-platform \
  --format json | jq '.tags'

# Update tenant quota via API
curl -X PATCH \
  -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"quotas": [{"key": "vCPU", "value": 32}]}' \
  "https://my-meshstack.example.com/api/meshobjects/meshtenants/my-workspace.my-project.my-platform"

# Access tenant resources (e.g. get GCP project ID)
meshstack tenant get \
  --workspace my-workspace \
  --project my-project \
  --platform gcp-platform \
  --format json | jq '.platformTenantId'
```

---

## Policies & Compliance

```bash
# List all workspace policies
meshstack policy list --scope workspace

# List all project policies
meshstack policy list --scope project

# Apply a policy to a workspace
meshstack policy apply my-policy --workspace my-workspace

# Show compliance status for a workspace
meshstack workspace get my-workspace --format json | jq '.complianceStatus'

# List all tag schemas
meshstack tag-schema list

# Get details of a tag schema
meshstack tag-schema get my-tag-schema

# Create a tag schema via API
curl -X POST \
  -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "apiVersion": "v1",
    "kind": "meshTagDefinition",
    "metadata": {"name": "costcenter"},
    "spec": {
      "displayName": "Cost Center",
      "scope": ["meshWorkspace", "meshProject"],
      "valueType": "string",
      "mandatory": true
    }
  }' \
  https://my-meshstack.example.com/api/meshobjects/meshtagdefinitions

# List pending approval requests
meshstack approval list --status pending

# Approve a pending request
meshstack approval approve my-approval-id

# Reject a pending request with a reason
meshstack approval reject my-approval-id --reason "Missing cost center tag"

# Manage lifecycle policies (e.g. auto-delete after N days)
meshstack lifecycle-policy list

# Apply lifecycle policy to a workspace
meshstack lifecycle-policy apply my-lifecycle-policy \
  --workspace my-workspace
```

---

## Metering & Cost Management

```bash
# List chargeback statements for a workspace
meshstack chargeback list --workspace my-workspace

# Get a specific chargeback statement
meshstack chargeback get my-statement-id --workspace my-workspace

# Export chargeback data as CSV
meshstack chargeback list \
  --workspace my-workspace \
  --format csv > chargeback-export.csv

# Show usage reports for a project
meshstack usage-report list \
  --workspace my-workspace \
  --project my-project

# Get cost allocation per workspace via API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "https://my-meshstack.example.com/api/meshobjects/meshchargebacks?workspaceIdentifier=my-workspace"

# Get cost allocation per platform
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "https://my-meshstack.example.com/api/meshobjects/meshchargebacks?platformIdentifier=my-platform"

# Set a budget alert for a workspace
meshstack budget-alert create \
  --workspace my-workspace \
  --threshold 5000 \
  --currency EUR \
  --notify user@example.com

# List active budget alerts
meshstack budget-alert list --workspace my-workspace

# Show cost breakdown by tag (e.g. by team)
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "https://my-meshstack.example.com/api/meshobjects/meshchargebacks?tag.team=platform" \
  | jq '.[] | {workspace: .workspaceIdentifier, amount: .netAmount}'
```

---

## Building Blocks & Service Catalog

```bash
# List all available building blocks
meshstack building-block list

# Get details of a specific building block
meshstack building-block get my-building-block

# Assign a building block to a project/tenant
meshstack building-block assign my-building-block \
  --workspace my-workspace \
  --project my-project \
  --platform my-platform

# List building block assignments for a project
meshstack building-block assignment list \
  --workspace my-workspace \
  --project my-project

# Delete a building block assignment
meshstack building-block assignment delete my-assignment-id \
  --workspace my-workspace \
  --project my-project

# List marketplace services
meshstack marketplace list

# Get details of a marketplace service
meshstack marketplace get my-service

# Create a service instance from the marketplace
meshstack service-instance create \
  --service my-service \
  --plan standard \
  --workspace my-workspace \
  --project my-project \
  --parameters '{"region": "europe-west3", "tier": "basic"}'

# List service instances
meshstack service-instance list \
  --workspace my-workspace \
  --project my-project

# Delete a service instance
meshstack service-instance delete my-instance-id \
  --workspace my-workspace \
  --project my-project

# View building block dependency graph via API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "https://my-meshstack.example.com/api/meshobjects/meshbuildingblocks/my-building-block/dependencies"
```

---

## API Access & Automation

```bash
# Generate a personal API key in the meshStack portal
# Navigate: User Settings → API Keys → Create Key

# Export the token for use in scripts
export MESHSTACK_TOKEN="my-api-token"
export MESHSTACK_URL="https://my-meshstack.example.com"

# Authenticate with client credentials (service account)
TOKEN=$(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=my-client-id&client_secret=my-client-secret" \
  "${MESHSTACK_URL}/api/login" | jq -r '.access_token')

# List all workspaces via REST API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshworkspaces" | jq '.'

# List all projects via REST API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshprojects" | jq '.'

# Get a single workspace via REST API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshworkspaces/my-workspace" | jq '.'

# Paginate large result sets
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshworkspaces?page=0&size=25" | jq '.'

# Iterate all pages in a shell loop
PAGE=0; SIZE=25
while true; do
  RESULT=$(curl -s -H "Authorization: Bearer $MESHSTACK_TOKEN" \
    "${MESHSTACK_URL}/api/meshobjects/meshworkspaces?page=${PAGE}&size=${SIZE}")
  echo "$RESULT" | jq '.[]'
  TOTAL=$(echo "$RESULT" | jq 'length')
  [ "$TOTAL" -lt "$SIZE" ] && break
  PAGE=$((PAGE + 1))
done

# Create a workspace via REST API
curl -X POST \
  -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "apiVersion": "v1",
    "kind": "meshWorkspace",
    "metadata": {"name": "my-new-workspace"},
    "spec": {
      "displayName": "My New Workspace",
      "tags": {"env": "dev", "team": "platform"}
    }
  }' \
  "${MESHSTACK_URL}/api/meshobjects/meshworkspaces"

# Delete a workspace via REST API
curl -X DELETE \
  -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshworkspaces/my-workspace"
```

---

## Tips & Tricks

```bash
# Bulk export all workspaces to JSON
meshstack workspace list --format json > all-workspaces.json

# Filter workspaces by tag using jq
meshstack workspace list --format json \
  | jq '.[] | select(.tags.env == "production")'

# Filter tenants by replication state via API
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshtenants?replicationStatus=FAILED" \
  | jq '.[].metadata.name'

# CI/CD integration pattern (e.g. GitHub Actions)
# Store MESHSTACK_TOKEN and MESHSTACK_URL as repository secrets
# Then use meshstack CLI in your pipeline:
# - name: Create project
#   run: |
#     meshstack login --client-id ${{ secrets.MS_CLIENT_ID }} \
#       --client-secret ${{ secrets.MS_CLIENT_SECRET }} \
#       --url ${{ secrets.MS_URL }}
#     meshstack project create my-project --workspace my-workspace

# List all service accounts (API keys) for automation
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshserviceaccounts" | jq '.'

# Grant minimal service account permissions (read-only)
# Assign role: meshWorkspaceReader or meshProjectReader

# Register a webhook for event notifications (tenant created, etc.)
curl -X POST \
  -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://my-webhook.example.com/hook",
    "events": ["meshTenant.created", "meshWorkspace.created"],
    "secret": "my-webhook-secret"
  }' \
  "${MESHSTACK_URL}/api/meshobjects/meshwebhooks"

# List registered webhooks
curl -H "Authorization: Bearer $MESHSTACK_TOKEN" \
  "${MESHSTACK_URL}/api/meshobjects/meshwebhooks" | jq '.'

# Bulk tag update via API (update all projects with a missing tag)
for WS in $(meshstack workspace list --format json | jq -r '.[].metadata.name'); do
  curl -X PATCH \
    -H "Authorization: Bearer $MESHSTACK_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"tags": {"managed-by": "platform-team"}}' \
    "${MESHSTACK_URL}/api/meshobjects/meshworkspaces/${WS}"
done

# Show full API documentation (Swagger UI)
open "${MESHSTACK_URL}/api/swagger-ui.html"
```
