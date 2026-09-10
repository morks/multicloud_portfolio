# Spacelift Cheat Sheet

## Overview

**Spacelift** is an enterprise IaC management platform supporting Terraform, OpenTofu, Pulumi, Ansible, and CloudFormation with OPA-based policy enforcement.

| | |
|---|---|
| **Strengths** | OPA policy engine (plan/trigger/access policies) · self-hosted private worker pools · module registry · multi-tool support · audit logs · fine-grained RBAC |
| **Weaknesses** | SaaS-first (self-hosted worker setup is complex) · cost scales with usage · OPA/Rego learning curve · smaller community than Terraform Cloud |
| **Best for** | Enterprise IaC governance across multiple teams, replacing Terraform Cloud/Enterprise, enforcing OPA policies on infra changes, multi-tool IaC environments |

---

## Key Concepts

```bash
# Stack      — a unit of IaC work (Terraform/OpenTofu/Pulumi/Ansible repo + config)
# Run        — a plan or apply execution triggered manually, by push, or by schedule
# Context    — reusable set of env vars / mounted files attached to one or more stacks
# Policy     — OPA (Rego) rules controlling plan output, access, triggers, notifications
# Module     — reusable Terraform module published to the Spacelift module registry
# Worker Pool— group of self-hosted agents that run jobs instead of Spacelift's cloud runners
```

---

## spacectl CLI — Installation & Auth

```bash
# Install via Homebrew (macOS/Linux)
brew install spacelift-io/spacelift/spacectl

# Or download binary directly
# https://github.com/spacelift-io/spacectl/releases

# Log in (opens browser for SSO)
spacectl profile login my-org            # my-org.app.spacelift.io

# List configured profiles
spacectl profile list

# Show current identity
spacectl whoami

# Switch profile
spacectl profile select my-org

# Export API token for scripting
export SPACELIFT_API_KEY_ID=<id>
export SPACELIFT_API_KEY_SECRET=<secret>
export SPACELIFT_API_KEY_ENDPOINT=https://my-org.app.spacelift.io
```

---

## Stacks

```bash
# List all stacks
spacectl stack list

# Show stack details
spacectl stack show --id my-stack

# Create a stack (interactive)
spacectl stack create

# Trigger a run (plan + apply)
spacectl run trigger --id my-stack

# List runs for a stack
spacectl run list --id my-stack

# Show run logs
spacectl run logs --id my-stack --run-id <run-id>

# Confirm a run waiting for approval
spacectl run confirm --id my-stack --run-id <run-id>

# Discard a pending run
spacectl run discard --id my-stack --run-id <run-id>

# Deploy (trigger + auto-confirm if policies pass)
spacectl stack deploy --id my-stack

# Delete a stack
spacectl stack delete --id my-stack
```

---

## Contexts & Variables

```bash
# List contexts
spacectl context list

# Create a context
spacectl context create --name my-context

# Attach context to a stack
spacectl context attach --id my-context --stack my-stack

# Set an environment variable in a context
spacectl var set --context my-context \
  --name AWS_REGION \
  --value eu-central-1

# Set a secret variable (masked in logs)
spacectl var set --context my-context \
  --name AWS_SECRET_ACCESS_KEY \
  --value "supersecret" \
  --secret

# List variables in a context
spacectl var list --context my-context

# Delete a variable
spacectl var delete --context my-context --name AWS_REGION

# Mount a file into a context (e.g. kubeconfig, .npmrc)
spacectl context mount-file --id my-context \
  --path /root/.kube/config \
  --content "$(cat ~/.kube/config)"
```

---

## Policies (OPA / Rego)

```bash
# Policy types:
# plan        — approve/reject based on planned changes
# trigger     — decide whether to auto-trigger a run on push
# push        — filter which git pushes start a run
# access      — control who can interact with a stack
# task        — control which ad-hoc tasks are allowed
# notification — route notifications to Slack/webhooks

# List policies
spacectl policy list

# Create a policy from a file
spacectl policy create --name my-plan-policy \
  --type plan \
  --body "$(cat plan-policy.rego)"

# Attach policy to a stack
spacectl policy attach --id my-plan-policy --stack my-stack

# Sample plan policy (plan-policy.rego):
# package spacelift
# deny["No resource deletions allowed"] {
#   spacelift.run.changes[_].action == "delete"
# }
# warn["Cost increase > 20%"] {
#   spacelift.run.cost_increase > 20
# }
```

---

## Module Registry

```bash
# List modules in the registry
spacectl module list

# Create a new module (link a repo)
spacectl module create

# List versions of a module
spacectl module version list --id my-module

# Tag a new version
spacectl module version create --id my-module --version 1.2.0

# Consuming a module in a Terraform stack:
# module "vpc" {
#   source  = "my-org.app.spacelift.io/my-module"
#   version = "~> 1.2"
# }
```

---

## Worker Pools (Self-Hosted)

```bash
# Create a worker pool in Spacelift UI or via API, then download the config.

# Run a private worker with Docker
docker run --rm -it \
  -e SPACELIFT_TOKEN="<worker-pool-token>" \
  -e SPACELIFT_POOL_ID="<pool-id>" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  public.ecr.aws/spacelift/launcher:latest

# Run multiple workers (scale horizontally with same pool)
docker run -d --name worker-1 \
  -e SPACELIFT_TOKEN="<token>" \
  -e SPACELIFT_POOL_ID="<pool-id>" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  public.ecr.aws/spacelift/launcher:latest

# Kubernetes deployment (use the official Helm chart)
helm repo add spacelift https://downloads.spacelift.io/helm
helm install spacelift-worker spacelift/spacelift-worker-pool \
  --set "workerPool.token=<token>" \
  --set "workerPool.poolId=<pool-id>"
```

---

## API & Webhooks

```bash
# Generate an API key (for CI/CD)
spacectl api-key create --name ci-key --admin

# GraphQL API — list stacks
curl -s -X POST https://my-org.app.spacelift.io/graphql \
  -H "Authorization: Bearer $SPACELIFT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ stacks { id name state } }"}' | jq '.data.stacks'

# GraphQL API — trigger a run
curl -s -X POST https://my-org.app.spacelift.io/graphql \
  -H "Authorization: Bearer $SPACELIFT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { runTrigger(stack: \"my-stack\") { id state } }"}' | jq '.'

# Webhook: configure in Stack → Settings → Webhooks
# Events: run:started, run:completed, run:failed, drift_detected

# Health check endpoint
curl https://my-org.app.spacelift.io/health
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [docs.spacelift.io](https://docs.spacelift.io/) | Spacelift documentation — stacks, contexts, policies, worker pools, VCS integrations, and self-hosting. |
| **Spacelift GitHub** | [github.com/spacelift-io](https://github.com/spacelift-io) | spacectl CLI, launcher, Terraform provider, and other open-source Spacelift tooling. |
| **Terraform Provider (Spacelift)** | [registry.terraform.io/spacelift-io/spacelift](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs) | Official Spacelift Terraform provider — manages stacks, contexts, policies, worker pools, and module registries as code. |
| **OpenTofu Provider (Spacelift)** | [search.opentofu.org/spacelift-io/spacelift](https://search.opentofu.org/provider/spacelift-io/spacelift/latest) | Spacelift provider in the OpenTofu registry — same capabilities as the Terraform provider. |
