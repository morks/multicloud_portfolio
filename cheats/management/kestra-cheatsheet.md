# Kestra Cheat Sheet

## Overview

**Kestra** is an open-source, cloud-native workflow orchestration platform that lets you build, schedule, and monitor pipelines and automation workflows using declarative YAML.

| | |
|---|---|
| **Strengths** | 400+ plugins (dbt, Spark, S3, Slack, HTTP…) · real-time UI with live logs · Git-native flows · self-hosted or Kestra Cloud · event-driven triggers · no code required |
| **Weaknesses** | Young ecosystem · UI can be slow on very large deployments · limited RBAC in OSS version · community smaller than Airflow/Prefect |
| **Best for** | Data pipelines & ETL, cross-service workflow automation, CI/CD orchestration, scheduled tasks, replacing cron + custom scripts |

---

## Installation & Setup

```bash
# ── Docker Compose quickstart ─────────────────────────────────────────────────
curl -o docker-compose.yml \
  https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
docker compose up -d

# Open UI
open http://localhost:8080

# ── Helm (Kubernetes) ─────────────────────────────────────────────────────────
helm repo add kestra https://helm.kestra.io/
helm repo update

helm install kestra kestra/kestra \
  --namespace kestra --create-namespace \
  --set configuration.kestra.url=http://kestra.example.com

# Verify pods
kubectl get pods -n kestra

# ── Standalone JAR ────────────────────────────────────────────────────────────
# Download from https://github.com/kestra-io/kestra/releases
java -jar kestra-*.jar server standalone \
  --worker-thread=128 \
  --flow-path=./flows

# ── Kestra CLI install ────────────────────────────────────────────────────────
# macOS via Homebrew
brew install kestra-io/tap/kestra

# or binary download
curl -sSL https://kestra.io/install.sh | bash

kestra --version
kestra --help
```

---

## Core Concepts

```bash
# Flow        — YAML definition of a workflow (id + namespace + tasks)
# Task        — Single unit of work inside a flow (plugin call)
# Trigger     — What starts a flow (schedule, webhook, event, another flow)
# Execution   — A single run of a flow (has state, logs, outputs)
# Namespace   — Hierarchical grouping for flows (e.g. company.team.project)
# Plugin      — Typed task implementation (HTTP, dbt, Spark, S3, Slack, …)
# Input       — Runtime parameter passed to a flow at execution time
# Output      — Value produced by a task, consumable by later tasks
# Variable    — Pebble template expression: {{ outputs.myTask.value }}
```

---

## CLI — Flows & Executions

```bash
# ── Flows ─────────────────────────────────────────────────────────────────────

# Validate a local flow YAML before uploading
kestra flow validate ./flows/my-flow.yml

# List all flows in a namespace
kestra flow list --namespace company.team

# Push a flow to the server
kestra flow push ./flows/my-flow.yml

# Delete a flow
kestra flow delete --namespace company.team --id my-flow

# ── Executions ───────────────────────────────────────────────────────────────

# Trigger an execution
kestra execution create \
  --namespace company.team \
  --id my-flow

# Trigger with inputs
kestra execution create \
  --namespace company.team \
  --id my-flow \
  --input name=hello \
  --input env=production

# List executions for a flow
kestra execution list \
  --namespace company.team \
  --flow-id my-flow

# Get execution details
kestra execution get \
  --namespace company.team \
  --flow-id my-flow \
  --execution-id <execution-id>

# ── Namespace & Plugins ───────────────────────────────────────────────────────

# List namespaces
kestra namespace list

# List installed plugins
kestra plugins list

# Install a plugin (server must be stopped)
kestra plugins install io.kestra.plugin.scripts

# ── Server ────────────────────────────────────────────────────────────────────

# Start standalone server (embedded worker + scheduler + API)
kestra server standalone

# Start only the API server (for distributed mode)
kestra server webserver

# Start only the worker
kestra server worker --thread=64
```

---

## Flow Anatomy (YAML)

```yaml
# my-flow.yml — annotated example
id: my-flow                         # unique within namespace
namespace: company.team.project     # hierarchical grouping
description: "Example Kestra flow"

# Runtime inputs (passed at execution time)
inputs:
  - id: environment
    type: STRING
    defaults: production
  - id: threshold
    type: INT
    defaults: 100

# Tasks run sequentially by default
tasks:
  - id: clone_repo
    type: io.kestra.plugin.git.Clone
    url: https://github.com/org/repo.git
    branch: main

  - id: run_script
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - echo "Environment: {{ inputs.environment }}"
      - python scripts/process.py --threshold {{ inputs.threshold }}

  - id: http_check
    type: io.kestra.plugin.core.http.Request
    uri: https://api.example.com/health
    method: GET
    headers:
      Authorization: "Bearer {{ secret('API_TOKEN') }}"

  - id: notify
    type: io.kestra.plugin.notifications.slack.SlackIncomingWebhook
    url: "{{ secret('SLACK_WEBHOOK') }}"
    payload: |
      {"text": "Flow {{ flow.id }} finished successfully"}

# Flow-level outputs (aggregated from task outputs)
outputs:
  - id: script_output
    value: "{{ outputs.run_script.vars.OUTPUT }}"

# Triggers
triggers:
  - id: daily_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 6 * * *"             # every day at 06:00

  - id: webhook_trigger
    type: io.kestra.plugin.core.trigger.Webhook
    key: "{{ secret('WEBHOOK_KEY') }}"
```

---

## Common Plugins

```yaml
# ── HTTP Request ──────────────────────────────────────────────────────────────
- id: fetch_data
  type: io.kestra.plugin.core.http.Request
  uri: https://api.example.com/data
  method: GET
  headers:
    Accept: application/json

# ── Python script ─────────────────────────────────────────────────────────────
- id: run_python
  type: io.kestra.plugin.scripts.python.Commands
  docker:
    image: python:3.12-slim
  commands:
    - pip install -q pandas
    - python -c "import pandas; print(pandas.__version__)"

# ── dbt ───────────────────────────────────────────────────────────────────────
- id: dbt_run
  type: io.kestra.plugin.dbt.cli.DbtCLI
  docker:
    image: ghcr.io/dbt-labs/dbt-bigquery:1.8.0
  commands:
    - dbt deps
    - dbt run --select +my_model
    - dbt test

# ── Git clone ─────────────────────────────────────────────────────────────────
- id: git_clone
  type: io.kestra.plugin.git.Clone
  url: https://github.com/org/repo.git
  branch: main
  username: "{{ secret('GH_USER') }}"
  password: "{{ secret('GH_TOKEN') }}"

# ── S3 upload ─────────────────────────────────────────────────────────────────
- id: upload_to_s3
  type: io.kestra.plugin.aws.s3.Upload
  accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
  secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
  region: eu-central-1
  bucket: my-bucket
  key: data/output.csv
  from: "{{ outputs.run_python.outputFiles['result.csv'] }}"

# ── Slack notification ────────────────────────────────────────────────────────
- id: slack_alert
  type: io.kestra.plugin.notifications.slack.SlackIncomingWebhook
  url: "{{ secret('SLACK_WEBHOOK_URL') }}"
  payload: |
    {
      "text": ":white_check_mark: Flow *{{ flow.id }}* completed\nExecution: {{ execution.id }}"
    }
```

---

## Triggers

```yaml
# ── Schedule (cron) ───────────────────────────────────────────────────────────
triggers:
  - id: every_morning
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "30 7 * * 1-5"          # Mon–Fri at 07:30
    timezone: Europe/Berlin

# ── Webhook ───────────────────────────────────────────────────────────────────
triggers:
  - id: http_webhook
    type: io.kestra.plugin.core.trigger.Webhook
    key: "{{ secret('WEBHOOK_KEY') }}"
# Call with: POST /api/v1/executions/webhook/{namespace}/{flowId}/{key}

# ── Flow trigger (react to another flow finishing) ────────────────────────────
triggers:
  - id: after_ingestion
    type: io.kestra.plugin.core.trigger.Flow
    conditions:
      - type: io.kestra.plugin.core.condition.ExecutionFlowCondition
        namespace: company.team
        flowId: ingestion-flow
      - type: io.kestra.plugin.core.condition.ExecutionStatusCondition
        in:
          - SUCCESS

# ── File detection (poll a storage location) ──────────────────────────────────
triggers:
  - id: new_file
    type: io.kestra.plugin.aws.s3.Trigger
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
    region: eu-central-1
    bucket: my-input-bucket
    prefix: incoming/
    interval: PT1M                 # check every minute
```

---

## Namespace & Secrets

```bash
# ── Namespace file storage ────────────────────────────────────────────────────

# Upload a file to a namespace (available to all flows in that namespace)
kestra namespace file update \
  --namespace company.team \
  --path /scripts/my_script.py \
  ./local/my_script.py

# List namespace files
kestra namespace file list --namespace company.team

# Reference in a flow task:
# - id: run
#   type: io.kestra.plugin.scripts.python.Commands
#   namespaceFiles:
#     enabled: true               # mounts all namespace files
#   commands:
#     - python scripts/my_script.py

# ── Secrets ───────────────────────────────────────────────────────────────────

# Environment-based secrets (set in server config or K8s secret)
# In docker-compose.yml:
#   environment:
#     SECRET_MY_API_KEY: "my-secret-value"  # prefix: SECRET_
# Use in flows: {{ secret('MY_API_KEY') }}

# Vault backend (application.yml)
# kestra:
#   secret:
#     type: vault
#     vault:
#       address: http://vault:8200
#       token: my-token
#       path: secret/kestra

# AWS SSM backend
# kestra:
#   secret:
#     type: aws-ssm
#     aws-ssm:
#       region: eu-central-1
#       prefix: /kestra/secrets/
```

---

## API & Automation

```bash
KESTRA_URL="http://localhost:8080"
NAMESPACE="company.team"
FLOW_ID="my-flow"

# ── Health check ──────────────────────────────────────────────────────────────
curl -s "${KESTRA_URL}/api/v1/health" | jq '.'

# ── List flows ────────────────────────────────────────────────────────────────
curl -s "${KESTRA_URL}/api/v1/flows/${NAMESPACE}" | jq '.[].id'

# ── Trigger an execution ──────────────────────────────────────────────────────
curl -s -X POST \
  "${KESTRA_URL}/api/v1/executions/${NAMESPACE}/${FLOW_ID}" \
  -H "Content-Type: multipart/form-data" \
  -F "environment=production" | jq '.id'

# ── Trigger execution with JSON inputs ───────────────────────────────────────
curl -s -X POST \
  "${KESTRA_URL}/api/v1/executions/${NAMESPACE}/${FLOW_ID}" \
  -H "Content-Type: application/json" \
  -d '{"environment": "production", "threshold": 200}' | jq '.'

# ── Get execution status ──────────────────────────────────────────────────────
EXEC_ID="your-execution-id"
curl -s "${KESTRA_URL}/api/v1/executions/${EXEC_ID}" | jq '.state.current'

# ── Download execution logs ───────────────────────────────────────────────────
curl -s "${KESTRA_URL}/api/v1/logs/${EXEC_ID}/download" -o execution.log

# ── List running executions ───────────────────────────────────────────────────
curl -s "${KESTRA_URL}/api/v1/executions?state=RUNNING" | jq '.results[].id'

# ── Kill a running execution ──────────────────────────────────────────────────
curl -s -X DELETE "${KESTRA_URL}/api/v1/executions/${EXEC_ID}/kill"

# ── Upload a flow via API ─────────────────────────────────────────────────────
curl -s -X PUT \
  "${KESTRA_URL}/api/v1/flows" \
  -H "Content-Type: application/x-yaml" \
  --data-binary @my-flow.yml | jq '.id'

# ── Authentication (Enterprise / Cloud) ──────────────────────────────────────
# Use Basic Auth or API token
curl -s -u "user:password" "${KESTRA_URL}/api/v1/flows/${NAMESPACE}"
curl -s -H "Authorization: Bearer ${KESTRA_API_TOKEN}" \
  "${KESTRA_URL}/api/v1/flows/${NAMESPACE}"
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [kestra.io/docs](https://kestra.io/docs/) | Kestra documentation — flows, plugins, deployment, enterprise features, and API reference. |
| **Plugin Index** | [kestra.io/plugins](https://kestra.io/plugins/) | Full catalog of Kestra plugins — AWS, GCP, Azure, dbt, Spark, HTTP, notifications, scripting, and more. |
| **Kestra GitHub** | [github.com/kestra-io/kestra](https://github.com/kestra-io/kestra) | Kestra source code, releases, issue tracker, and community discussions. |
| **Terraform Provider** | [registry.terraform.io/kestra-io/kestra](https://registry.terraform.io/providers/kestra-io/kestra/latest/docs) | Official Kestra Terraform provider — manage flows, namespaces, service accounts, and secrets as code. |
| **OpenTofu Provider** | [search.opentofu.org/kestra-io/kestra](https://search.opentofu.org/provider/kestra-io/kestra/latest) | Kestra provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
