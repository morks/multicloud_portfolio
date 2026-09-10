# Grafana Loki Cheat Sheet

## Overview

**Grafana Loki** is a horizontally scalable log aggregation system designed to be cost-effective — it indexes only labels, not log content, making it "like Prometheus, but for logs".

| | |
|---|---|
| **Strengths** | Low storage cost (label index only) · tight Grafana integration · LogQL query language · works alongside existing Prometheus stack · Promtail/Alloy/Fluent Bit support |
| **Weaknesses** | Full-text search is expensive (bloom filters help) · not as mature as Elasticsearch for complex log analytics · label cardinality must be managed carefully |
| **Best for** | Kubernetes log aggregation, cost-effective logging alongside Prometheus/Grafana, LogQL-based log analysis, replacing EFK stack for simpler use cases |

---

## Installation

```bash
# Add Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install loki-stack (Loki + Promtail, simple single-binary)
helm install loki-stack grafana/loki-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.enabled=false

# Install Loki in scalable mode (production)
helm install loki grafana/loki \
  --namespace monitoring \
  --create-namespace \
  --values loki-values.yaml

# Install loki-distributed (microservices mode for large scale)
helm install loki grafana/loki-distributed \
  --namespace monitoring

# Docker Compose — local development
# docker-compose.yml snippet:
# loki:
#   image: grafana/loki:latest
#   ports: ["3100:3100"]
#   command: -config.file=/etc/loki/local-config.yaml

# Verify Loki pods are running
kubectl get pods -n monitoring -l app=loki

# Check Loki readiness
curl http://loki:3100/ready

# Check Loki metrics
curl http://loki:3100/metrics | grep loki_
```

---

## LogQL Basics

```bash
# --- Stream Selectors (required, always use labels) ---
{app="nginx"}                               # exact match
{namespace="production"}                    # filter by namespace
{app="nginx", env="prod"}                   # multiple labels (AND)
{app=~"nginx|apache"}                       # regex match
{app!="redis"}                              # not equal

# --- Line Filters ---
{app="nginx"} |= "error"                    # contains string
{app="nginx"} != "health"                   # does not contain
{app="nginx"} |~ "5[0-9]{2}"               # regex match
{app="nginx"} !~ "GET|HEAD"                # regex not match
{app="nginx"} |= "error" |= "timeout"      # chaining (AND)

# --- Log Parsers ---
{app="myapp"} | json                        # parse JSON logs
{app="myapp"} | logfmt                      # parse logfmt (key=value)
{app="myapp"} | pattern "<ip> - <user> [<ts>] \"<method> <path>\" <status>"
{app="nginx"} | regexp `(?P<status>\d{3})`  # extract named field

# --- Field Filters (after parsing) ---
{app="myapp"} | json | level="error"        # filter on extracted field
{app="myapp"} | json | status_code >= 500   # numeric comparison
{app="myapp"} | json | duration > 1s        # duration comparison

# --- Line Formatting ---
{app="myapp"} | json | line_format "{{.level}} {{.message}}"
{app="myapp"} | json | label_format status=status_code  # rename label
```

---

## LogQL Metrics

```bash
# rate() — logs per second over a range
rate({app="nginx"} |= "error" [5m])

# count_over_time() — total log lines in range
count_over_time({app="nginx"}[1h])

# bytes_rate() — bytes per second
bytes_rate({app="nginx"}[5m])

# bytes_over_time() — total bytes in range
bytes_over_time({app="nginx"}[1h])

# sum by label
sum by (namespace) (rate({job="kubernetes-pods"}[5m]))

# top N — highest error rate namespaces
topk(5, sum by (namespace) (rate({namespace=~".+"} |= "error" [5m])))

# 99th percentile response time (requires extracted field)
quantile_over_time(0.99, {app="api"} | json | unwrap duration [5m]) by (pod)

# Absent over time — alert when no logs for 5m
absent_over_time({app="critical-service"}[5m])

# First and last value
first_over_time({app="myapp"} | json | unwrap level [5m])
```

---

## Log Shipping

```bash
# --- Promtail (sidecar / DaemonSet) ---
# Helm install Promtail
helm install promtail grafana/promtail \
  --namespace monitoring \
  --set config.lokiAddress=http://loki:3100/loki/api/v1/push

# Promtail config snippet (promtail-config.yaml):
# server:
#   http_listen_port: 9080
# clients:
#   - url: http://loki:3100/loki/api/v1/push
# scrape_configs:
#   - job_name: kubernetes-pods
#     kubernetes_sd_configs:
#       - role: pod
#     pipeline_stages:
#       - docker: {}                    # parse Docker log format
#       - json:
#           expressions:
#             level: level
#             message: message
#       - labels:
#           level:

# --- Grafana Alloy (next-gen agent, replaces Promtail) ---
helm install alloy grafana/alloy \
  --namespace monitoring \
  --values alloy-values.yaml

# --- Fluent Bit ---
helm install fluent-bit fluent/fluent-bit \
  --set config.outputs="[OUTPUT]\n    Name loki\n    Host loki\n    Port 3100"

# --- Vector ---
# vector.toml sink:
# [sinks.loki]
# type = "loki"
# inputs = ["kubernetes_logs"]
# endpoint = "http://loki:3100"
# labels.app = "{{ kubernetes.pod_labels.app }}"
```

---

## Grafana Integration

```bash
# Add Loki as a data source in Grafana (UI: Configuration → Data Sources → Add)
# URL: http://loki:3100

# Provision via ConfigMap (datasources.yaml):
# apiVersion: 1
# datasources:
#   - name: Loki
#     type: loki
#     url: http://loki:3100
#     access: proxy
#     isDefault: false
#     jsonData:
#       derivedFields:
#         - name: TraceID
#           matcherRegex: "traceId=(\\w+)"
#           url: "$${__value.raw}"    # link to Tempo trace

# Explore mode — query logs interactively
# Grafana → Explore → select Loki datasource → LogQL editor

# Correlate Logs and Metrics
# In a Prometheus panel → click data point → "Logs" button (requires label matching)

# Log panel in dashboard
# Visualization: "Logs"
# Query: {namespace="production", app="my-app"}

# Alert on log pattern (Grafana Alerting)
# Query: count_over_time({app="myapp"} |= "FATAL" [5m]) > 0
```

---

## Label Best Practices

```bash
# GOOD labels — low cardinality, stable values
# app, namespace, env, cluster, job, level, region

# BAD labels — high cardinality, avoid!
# pod (changes on restart), request_id, user_id, timestamp, IP

# Structured metadata (Loki 2.9+) — high-cardinality values go here
# Push with metadata in HTTP API:
# curl -X POST http://loki:3100/loki/api/v1/push \
#   -H 'Content-Type: application/json' \
#   -d '{
#     "streams": [{
#       "stream": {"app": "myapp", "env": "prod"},
#       "values": [
#         ["1700000000000000000", "message text", {"trace_id": "abc123"}]
#       ]
#     }]
#   }'

# Query structured metadata
{app="myapp"} | trace_id="abc123"

# Chunk cardinality check (Loki metrics)
curl http://loki:3100/metrics | grep loki_ingester_streams_created_total
```

---

## Useful Queries

```bash
# --- Top error sources ---
topk(10, sum by (app) (rate({namespace="production"} |= "error" [5m])))

# --- HTTP 5xx errors (nginx access log) ---
{app="nginx"} | pattern `<_> "<method> <path> <_>" <status> <_>` | status >= 500

# --- Slow requests (> 1s) ---
{app="api"} | json | duration > 1s | line_format "{{.method}} {{.path}} {{.duration}}"

# --- Pod restart logs ---
{namespace="production"} |= "OOMKilled"
{namespace="production"} |= "Back-off restarting failed container"

# --- Multi-line stack traces (Java) ---
{app="java-service"} | multiline firstline="^\d{4}-\d{2}-\d{2}"

# --- Count unique log levels ---
sum by (level) (count_over_time({app="myapp"} | json [1h]))

# --- Logs in the last 15m matching multiple conditions ---
{app="myapp"} |= "error" != "connection reset" | json | component="database"

# --- Rate of specific HTTP status ---
sum(rate({app="nginx"} | pattern `<_> <status> <_>` | status="500" [5m]))
```

---

## logcli

```bash
# Install logcli
brew install logcli
# or binary: https://github.com/grafana/loki/releases

# Set Loki address
export LOKI_ADDR=http://loki:3100

# Query logs (tail-like)
logcli query '{app="nginx"}' --tail --output=raw

# Query with time range
logcli query '{app="nginx"}' \
  --from="2024-01-01T00:00:00Z" \
  --to="2024-01-01T01:00:00Z"

# Instant query (metric)
logcli instant-query 'rate({app="nginx"}[5m])'

# List all label names
logcli labels

# List values for a label
logcli labels app

# List series matching a selector
logcli series '{app="nginx"}'

# Output formats: default, raw, jsonl
logcli query '{app="nginx"}' --output=jsonl | jq '.line'

# Limit results
logcli query '{app="nginx"}' --limit=100

# Follow logs live
logcli query '{app="nginx"}' --tail --no-labels
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [grafana.com/docs/loki/latest](https://grafana.com/docs/loki/latest/) | Grafana Loki documentation — installation, configuration, LogQL, and operations guides. |
| **LogQL Reference** | [grafana.com/docs/loki/latest/query](https://grafana.com/docs/loki/latest/query/) | Complete LogQL query language reference — stream selectors, line filters, parsers, and metric queries. |
| **Loki GitHub** | [github.com/grafana/loki](https://github.com/grafana/loki) | Loki source code, releases, issue tracker, and community discussions. |
| **Terraform Provider (Grafana)** | [registry.terraform.io/grafana/grafana](https://registry.terraform.io/providers/grafana/grafana/latest/docs) | Official Grafana Terraform provider — manages Loki datasources, dashboards, and alert rules as code. |
| **OpenTofu Provider (Grafana)** | [search.opentofu.org/grafana/grafana](https://search.opentofu.org/provider/grafana/grafana/latest) | Grafana provider in the OpenTofu registry — same resource coverage as the Terraform provider. |
