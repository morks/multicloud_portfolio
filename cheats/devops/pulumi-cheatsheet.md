# Pulumi Cheat Sheet

## Installation & Setup

```bash
# Install Pulumi CLI (macOS via Homebrew)
brew install pulumi/tap/pulumi

# Verify installation
pulumi version

# Login to Pulumi Cloud (managed state backend)
pulumi login

# Login with local state (no cloud account needed)
pulumi login --local

# Login with S3 backend
pulumi login s3://my-state-bucket/pulumi

# Login with Azure Blob backend
pulumi login azblob://my-state-container

# Login with GCS backend
pulumi login gs://my-state-bucket/pulumi

# Show current user / backend
pulumi whoami
pulumi about

# Install language runtime (e.g. Python)
pip install pulumi
```

---

## New Project

```bash
# List available templates
pulumi new --list-templates

# Create new project from template (interactive)
pulumi new aws-python
pulumi new azure-typescript
pulumi new gcp-go
pulumi new kubernetes-yaml
pulumi new python           # generic Python project

# Create with flags (non-interactive)
pulumi new aws-python \
  --name my-infra \
  --description "My AWS infrastructure" \
  --stack dev \
  --yes

# Project structure (Python example)
# my-infra/
# ├── Pulumi.yaml         # project metadata
# ├── Pulumi.dev.yaml     # stack config (stack-specific)
# ├── __main__.py         # infrastructure code
# └── requirements.txt    # Python dependencies

# Install project dependencies (Python)
pip install -r requirements.txt

# Install project dependencies (Node.js/TypeScript)
npm install
```

---

## Stack Management

```bash
# Create a new stack
pulumi stack init prod
pulumi stack init staging

# List all stacks
pulumi stack ls

# Select / switch to a stack
pulumi stack select prod

# Show current stack details
pulumi stack

# Remove a stack (must be destroyed first)
pulumi stack rm staging

# Export stack state to JSON
pulumi stack export --file stack-backup.json

# Import stack state from JSON
pulumi stack import --file stack-backup.json

# --- Config ---

# Set a config value
pulumi config set aws:region eu-central-1
pulumi config set instanceType t3.micro

# Set a secret (encrypted in state)
pulumi config set --secret dbPassword SuperSecret123

# Get a config value
pulumi config get aws:region

# List all config values
pulumi config

# Remove a config value
pulumi config rm instanceType

# Copy config from one stack to another
pulumi config cp --dest prod
```

---

## Core Workflow

```bash
# Preview changes (dry run, no changes applied)
pulumi preview

# Preview with detailed diff output
pulumi preview --diff

# Deploy changes
pulumi up

# Deploy without interactive prompt
pulumi up --yes

# Show diff during deploy
pulumi up --diff

# Target a specific resource only
pulumi up --target urn:pulumi:dev::my-infra::aws:s3/bucket:Bucket::my-bucket

# Replace a specific resource
pulumi up --replace urn:pulumi:dev::my-infra::aws:s3/bucket:Bucket::my-bucket

# Refresh state from real infrastructure (detect drift)
pulumi refresh

# Refresh without prompt
pulumi refresh --yes

# Destroy all resources in the stack
pulumi destroy

# Destroy without prompt
pulumi destroy --yes

# Destroy a specific resource only
pulumi destroy --target urn:pulumi:dev::my-infra::aws:s3/bucket:Bucket::my-bucket

# Show outputs of the current stack
pulumi stack output
pulumi stack output bucketName

# Watch for file changes and auto-preview (dev mode)
pulumi watch
```

---

## State Management

```bash
# List all resources in the current stack state
pulumi state

# Show details of a specific resource (by URN)
pulumi state show urn:pulumi:dev::my-infra::aws:s3/bucket:Bucket::my-bucket

# Delete a resource from state (without destroying the real resource)
pulumi state delete urn:pulumi:dev::my-infra::aws:s3/bucket:Bucket::my-bucket

# Rename / move a resource in state
pulumi state rename \
  urn:pulumi:dev::my-infra::aws:s3/bucket:Bucket::old-name \
  new-name

# Export full stack state
pulumi stack export > stack-state.json

# Import modified state (after manual edits)
pulumi stack import < stack-state.json

# Move resources between stacks (Pulumi Cloud)
pulumi state move \
  --source urn:pulumi:dev::... \
  --dest prod
```

---

## Import Existing Resources

```bash
# Import an existing AWS S3 bucket into Pulumi state
pulumi import aws:s3/bucket:Bucket my-bucket my-existing-bucket-name

# Import an existing Azure Resource Group
pulumi import azure-native:resources:ResourceGroup myRG \
  /subscriptions/<sub-id>/resourceGroups/my-rg

# Import an existing GCP Storage Bucket
pulumi import gcp:storage/bucket:Bucket myBucket my-gcp-bucket-name

# Import generates code snippet — paste into your program file
# Run pulumi up after importing to align state with code

# Bulk import from JSON file
# import.json format:
# {
#   "resources": [
#     { "type": "aws:s3/bucket:Bucket", "name": "my-bucket", "id": "my-bucket-name" }
#   ]
# }
pulumi import --file import.json
```

---

## Automation API

```python
# Python: programmatic stack management with Automation API
import pulumi
from pulumi import automation as auto

stack = auto.create_or_select_stack(
    stack_name="dev",
    project_name="my-infra",
    program=lambda: None,  # reference your actual program
    opts=auto.LocalWorkspaceOptions(
        work_dir="./my-infra"
    )
)

# Set config
stack.set_config("aws:region", auto.ConfigValue("eu-central-1"))

# Preview
preview = stack.preview(on_output=print)

# Deploy
up_result = stack.up(on_output=print)
print(f"Stack outputs: {up_result.outputs}")
```

```typescript
// TypeScript: Automation API
import { LocalWorkspace } from "@pulumi/pulumi/automation";

const stack = await LocalWorkspace.createOrSelectStack({
  stackName: "dev",
  workDir: "./my-infra",
});

await stack.setConfig("aws:region", { value: "eu-central-1" });

const upResult = await stack.up({ onOutput: console.log });
console.log(upResult.outputs);
```

---

## Useful Commands

```bash
# List installed plugins (providers)
pulumi plugin ls

# Install a specific provider plugin
pulumi plugin install resource aws v6.0.0

# Remove a plugin
pulumi plugin rm resource aws v5.0.0

# Show Pulumi environment info (runtime, CLI, backend)
pulumi about

# View activity log / history for a stack
pulumi stack history

# Show recent update details
pulumi stack history --json | jq '.[0]'

# Cancel a running update
pulumi cancel

# View logs (for resources that emit logs, e.g. Lambda)
pulumi logs
pulumi logs --follow
pulumi logs --resource urn:pulumi:dev::...

# Lint / format (Python example)
mypy __main__.py
black __main__.py

# Generate Pulumi program from existing Terraform state
pulumi convert --from terraform --language python

# Convert CloudFormation template to Pulumi
pulumi convert --from cloudformation --language typescript \
  --out ./pulumi-cf template.yaml
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [pulumi.com/docs](https://www.pulumi.com/docs/) | Pulumi documentation — getting started, concepts, providers, stacks, Automation API, and CI/CD integration. |
| **Pulumi Registry** | [pulumi.com/registry](https://www.pulumi.com/registry/) | Provider registry for all major clouds (AWS, Azure, GCP, Kubernetes, 130+ providers) with API reference. |
| **Pulumi AI** | [pulumi.com/ai](https://www.pulumi.com/ai/) | AI assistant that generates Pulumi infrastructure code from natural language descriptions. |
| **Pulumi GitHub** | [github.com/pulumi/pulumi](https://github.com/pulumi/pulumi) | Pulumi CLI source code, releases, issue tracker, and community discussions. |
| **Pulumi Examples** | [github.com/pulumi/examples](https://github.com/pulumi/examples) | Official example programs across all supported languages and cloud providers. |
