# Prometheus & Grafana Cheat Sheet

## Installation & Setup

```bash
# Install Prometheus (macOS)
brew install prometheus

# Install Grafana (macOS)
brew install grafana

# Check versions
prometheus --version
grafana-server -v
grafana-cli --version

# Start services (macOS via Homebrew)
brew services start prometheus
brew services start grafana

# Start manually
prometheus --config.file=/usr/local/etc/prometheus.yml
grafana-server --homepath /usr/local/share/grafana
```

```yaml
# docker-compose.yml – Prometheus + Grafana + Node Exporter quickstart
version: "3.8"
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.retention.time=30d"
      - "--web.enable-lifecycle"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - "--path.procfs=/host/proc"
      - "--path.sysfs=/host/sys"

volumes:
  prometheus_data:
  grafana_data:
```

```bash
# Run stack
docker compose up -d

# Prometheus UI: http://localhost:9090
# Grafana UI:    http://localhost:3000  (admin/admin)
# Node Exporter: http://localhost:9100/metrics
```

```bash
# Kubernetes – install kube-prometheus-stack via Helm
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=my-secret-password \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi

# Upgrade existing installation
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values.yaml
```

---

## Prometheus Configuration (prometheus.yml)

```yaml
# prometheus.yml – full example
global:
  scrape_interval: 15s          # How often to scrape targets
  evaluation_interval: 15s      # How often to evaluate rules
  external_labels:
    cluster: "prod-cluster"
    env: "production"

# Alerting – point to Alertmanager
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load alerting rules
rule_files:
  - "/etc/prometheus/rules/*.yml"

# Remote write for long-term storage (e.g. Thanos / Cortex / Mimir)
remote_write:
  - url: "https://mimir.example.com/api/v1/push"
    basic_auth:
      username: my-app
      password: my-secret-token
    queue_config:
      max_samples_per_send: 10000
      max_shards: 30

scrape_configs:
  # Static target example
  - job_name: "my-app"
    static_configs:
      - targets:
          - "my-app.production.svc:8080"
    metrics_path: /metrics
    scrape_interval: 30s

  # Node Exporter
  - job_name: "node-exporter"
    static_configs:
      - targets:
          - "node-exporter:9100"

  # Kubernetes API server
  - job_name: "kubernetes-apiservers"
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels:
          - __meta_kubernetes_namespace
          - __meta_kubernetes_service_name
          - __meta_kubernetes_endpoint_port_name
        action: keep
        regex: default;kubernetes;https

  # Kubernetes pods (auto-discovery)
  - job_name: "kubernetes-pods"
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # Keep only pods with annotation prometheus.io/scrape=true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: "true"
      # Use custom metrics path if annotated
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      # Use custom port if annotated
      - source_labels:
          - __address__
          - __meta_kubernetes_pod_annotation_prometheus_io_port
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      # Add pod label as Prometheus label
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      # Add namespace label
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      # Add pod name label
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name
```

```yaml
# Alerting rules – /etc/prometheus/rules/my-app.yml
groups:
  - name: my-app-alerts
    rules:
      - alert: MyAppHighErrorRate
        expr: |
          rate(http_requests_total{job="my-app", status=~"5.."}[5m])
          / rate(http_requests_total{job="my-app"}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
          team: backend
        annotations:
          summary: "High HTTP error rate on {{ $labels.instance }}"
          description: "Error rate is {{ printf \"%.2f\" $value | humanizePercentage }} (threshold: 5%)"

      - alert: MyAppDown
        expr: up{job="my-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "my-app instance {{ $labels.instance }} is down"

      # Recording rule (pre-computed metric)
      - record: job:http_requests_total:rate5m
        expr: rate(http_requests_total[5m])
```

---

## promtool – CLI

```bash
# Validate prometheus.yml
promtool check config /etc/prometheus/prometheus.yml

# Validate alerting / recording rules
promtool check rules /etc/prometheus/rules/my-app.yml

# Instant query against running Prometheus
promtool query instant http://localhost:9090 \
  'up{job="my-app"}'

# Range query (last 1 hour, 1m resolution)
promtool query range \
  --start=$(date -v-1H +%s) \
  --end=$(date +%s) \
  --step=60 \
  http://localhost:9090 \
  'rate(http_requests_total[5m])'

# Analyze TSDB (storage statistics)
promtool tsdb analyze /var/lib/prometheus

# Debug: dump all series from TSDB
promtool debug all http://localhost:9090

# Show promtool version
promtool --version

# Unit-test alerting rules
promtool test rules /etc/prometheus/tests/my-app_test.yml
```

---

## PromQL – Querying

```promql
# --- Vector types ---

# Instant vector – current value of a metric
http_requests_total

# Range vector – values over a time window
http_requests_total[5m]

# Offset – look back in time
http_requests_total offset 1h

# --- Counters (always increasing) ---

# Per-second rate over 5 min window
rate(http_requests_total[5m])

# Instantaneous rate (sensitive to spikes)
irate(http_requests_total[5m])

# Total increase over a time window
increase(http_requests_total[1h])

# --- Gauges (can go up/down) ---

# Current memory usage in bytes
node_memory_MemFree_bytes

# Predict value in 4h based on last 1h trend
predict_linear(node_filesystem_free_bytes[1h], 4 * 3600)

# --- Aggregation ---

# Sum across all instances
sum(rate(http_requests_total[5m]))

# Sum grouped by job and status code
sum by (job, status) (rate(http_requests_total[5m]))

# Sum without specific labels
sum without (instance, pod) (rate(http_requests_total[5m]))

# Average CPU usage across all nodes
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m]))

# Top 5 pods by memory
topk(5, container_memory_usage_bytes{container!=""})

# Min / max / count
min(node_memory_MemAvailable_bytes)
max by (node) (node_load1)
count(up == 1)

# --- Histograms & quantiles ---

# 99th percentile of HTTP request duration
histogram_quantile(0.99,
  sum by (le) (
    rate(http_request_duration_seconds_bucket[5m])
  )
)

# --- Absence / missing metrics ---

# Alert if metric is missing
absent(up{job="my-app"})

# --- Useful one-liners ---

# CPU usage per node (%)
100 - (avg by (instance) (
  rate(node_cpu_seconds_total{mode="idle"}[5m])
) * 100)

# Memory usage (%)
100 * (1 - (
  node_memory_MemAvailable_bytes /
  node_memory_MemTotal_bytes
))

# HTTP 5xx error rate (%)
100 * sum(rate(http_requests_total{status=~"5.."}[5m]))
     / sum(rate(http_requests_total[5m]))

# Pod restarts in last 15 min
increase(kube_pod_container_status_restarts_total[15m]) > 0

# Disk usage (%)
100 * (1 - (
  node_filesystem_avail_bytes{mountpoint="/", fstype!="tmpfs"} /
  node_filesystem_size_bytes{mountpoint="/", fstype!="tmpfs"}
))

# Network receive bandwidth (MB/s)
rate(node_network_receive_bytes_total{device!="lo"}[5m]) / 1024 / 1024

# Kubernetes pod CPU throttling
sum by (pod, namespace) (
  rate(container_cpu_cfs_throttled_seconds_total[5m])
)
```

---

## Alertmanager

```yaml
# alertmanager.yml – full routing + receiver example
global:
  smtp_smarthost: "smtp.example.com:587"
  smtp_from: "alertmanager@example.com"
  smtp_auth_username: "alertmanager@example.com"
  smtp_auth_password: "my-smtp-password"
  slack_api_url: "https://hooks.slack.com/services/T000/B000/xxxx"

route:
  receiver: "default-receiver"
  group_by: ["alertname", "cluster", "namespace"]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    # Critical alerts go to PagerDuty
    - match:
        severity: critical
      receiver: pagerduty-critical
      continue: true

    # Backend team gets Slack notifications
    - match:
        team: backend
      receiver: slack-backend

    # Low-severity goes to email only
    - match:
        severity: warning
      receiver: email-ops

receivers:
  - name: "default-receiver"
    slack_configs:
      - channel: "#alerts-general"
        title: "[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"
        send_resolved: true

  - name: "slack-backend"
    slack_configs:
      - channel: "#alerts-backend"
        title: "{{ .CommonLabels.alertname }}"
        text: "{{ .CommonAnnotations.summary }}"
        send_resolved: true

  - name: "email-ops"
    email_configs:
      - to: "ops-team@example.com"
        send_resolved: true

  - name: "pagerduty-critical"
    pagerduty_configs:
      - routing_key: "my-pagerduty-integration-key"
        description: "{{ .CommonAnnotations.summary }}"
        severity: "critical"

# Inhibit rules – suppress child alerts when parent fires
inhibit_rules:
  # Suppress warning if critical is already firing for same alertname+instance
  - source_match:
      severity: "critical"
    target_match:
      severity: "warning"
    equal:
      - alertname
      - instance

  # Suppress all alerts when the whole cluster is down
  - source_match:
      alertname: "ClusterDown"
    target_match_re:
      severity: "critical|warning"
    equal:
      - cluster
```

```bash
# amtool – Alertmanager CLI

# Set Alertmanager URL (or export ALERTMANAGER_URL)
export ALERTMANAGER_URL=http://localhost:9093

# List active alerts
amtool alert list
amtool alert list --alertname=MyAppHighErrorRate

# Add silence (suppress all alerts for my-app for 2 hours)
amtool silence add \
  alertname="MyAppHighErrorRate" \
  job="my-app" \
  --comment="Maintenance window" \
  --duration=2h

# List all silences
amtool silence list

# Expire (remove) a silence
amtool silence expire <silence-id>

# Query routing tree for a given set of labels
amtool config routes test \
  alertname=MyAppHighErrorRate \
  severity=critical \
  team=backend

# Validate alertmanager config
amtool check-config /etc/alertmanager/alertmanager.yml
```

---

## Grafana CLI (grafana-cli)

```bash
# Install a plugin
grafana-cli plugins install grafana-piechart-panel
grafana-cli plugins install grafana-worldmap-panel
grafana-cli plugins install grafana-clock-panel

# List installed plugins
grafana-cli plugins list-remote
grafana-cli plugins ls              # locally installed

# Update a specific plugin
grafana-cli plugins update grafana-piechart-panel

# Update all plugins
grafana-cli plugins update-all

# Remove a plugin
grafana-cli plugins remove grafana-piechart-panel

# Reset admin password (when Grafana is stopped)
grafana-cli admin reset-admin-password new-password

# Export dashboard via Grafana HTTP API
curl -s \
  -H "Authorization: Bearer my-api-token" \
  "http://localhost:3000/api/dashboards/uid/my-dashboard" \
  | jq '.dashboard' > my-dashboard.json

# Import dashboard via Grafana HTTP API
curl -s -X POST \
  -H "Authorization: Bearer my-api-token" \
  -H "Content-Type: application/json" \
  -d @my-dashboard.json \
  "http://localhost:3000/api/dashboards/db"

# Import dashboard from grafana.com (dashboard ID 1860 = Node Exporter Full)
curl -s -X POST \
  -H "Authorization: Bearer my-api-token" \
  -H "Content-Type: application/json" \
  -d '{"dashboard": {"id": null}, "folderId": 0, "overwrite": true}' \
  "http://localhost:3000/api/dashboards/import"
```

---

## Grafana API

```bash
# Base URL and token
GRAFANA_URL="http://localhost:3000"
TOKEN="Bearer my-api-token"

# --- Datasources ---

# List all datasources
curl -s -H "Authorization: $TOKEN" \
  "$GRAFANA_URL/api/datasources" | jq '.[].name'

# Create Prometheus datasource
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }' \
  "$GRAFANA_URL/api/datasources"

# Delete datasource by name
curl -s -X DELETE \
  -H "Authorization: $TOKEN" \
  "$GRAFANA_URL/api/datasources/name/Prometheus"

# --- Dashboards ---

# List all dashboards
curl -s -H "Authorization: $TOKEN" \
  "$GRAFANA_URL/api/search?type=dash-db" | jq '.[].title'

# Export dashboard by UID
curl -s -H "Authorization: $TOKEN" \
  "$GRAFANA_URL/api/dashboards/uid/my-dashboard" \
  | jq '.dashboard' > my-dashboard.json

# Import / update dashboard from JSON file
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"dashboard\": $(cat my-dashboard.json), \"overwrite\": true, \"folderId\": 0}" \
  "$GRAFANA_URL/api/dashboards/db"

# Delete dashboard by UID
curl -s -X DELETE \
  -H "Authorization: $TOKEN" \
  "$GRAFANA_URL/api/dashboards/uid/my-dashboard"

# --- Service Account Token (Grafana 9+) ---

# Create service account
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "ci-service-account", "role": "Editor"}' \
  "$GRAFANA_URL/api/serviceaccounts"

# Create token for service account (replace <id> with returned id)
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "ci-token"}' \
  "$GRAFANA_URL/api/serviceaccounts/<id>/tokens"

# --- Folders ---

# List folders
curl -s -H "Authorization: $TOKEN" \
  "$GRAFANA_URL/api/folders" | jq '.[].title'

# Create folder
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "my-dashboard"}' \
  "$GRAFANA_URL/api/folders"

# --- Annotations ---

# Create annotation (mark a deployment)
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Deployed my-app v1.2.3",
    "tags": ["deployment", "my-app"],
    "time": '"$(date +%s000)"'
  }' \
  "$GRAFANA_URL/api/annotations"
```

---

## Kubernetes – kube-prometheus-stack

```bash
# Full install with custom values
helm install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=my-secret-password \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.retentionSize=45GB \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=standard \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=10Gi

# Port-forward to Prometheus
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-prometheus 9090:9090

# Port-forward to Grafana (default creds: admin/my-secret-password)
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-grafana 3000:80

# Port-forward to Alertmanager
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-alertmanager 9093:9093

# Get Grafana admin password from secret
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

```yaml
# ServiceMonitor – tell Prometheus to scrape my-app
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app-monitor
  namespace: monitoring
  labels:
    release: kube-prometheus-stack    # must match Prometheus selector
spec:
  namespaceSelector:
    matchNames:
      - production
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: http-metrics               # named port in Service spec
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
```

```yaml
# PodMonitor – scrape pods directly (no Service needed)
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: my-app-pod-monitor
  namespace: monitoring
  labels:
    release: kube-prometheus-stack
spec:
  namespaceSelector:
    matchNames:
      - production
  selector:
    matchLabels:
      app: my-app
  podMetricsEndpoints:
    - port: metrics
      path: /metrics
      interval: 30s
```

```yaml
# PrometheusRule – define alerts as a CRD
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: my-app-rules
  namespace: monitoring
  labels:
    release: kube-prometheus-stack    # must match Prometheus ruleSelector
spec:
  groups:
    - name: my-app.rules
      rules:
        - alert: MyAppPodCrashLooping
          expr: |
            rate(kube_pod_container_status_restarts_total{
              namespace="production",
              pod=~"my-app-.*"
            }[15m]) * 60 * 15 > 3
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Pod {{ $labels.pod }} is crash-looping"
            description: "{{ $labels.pod }} restarted {{ $value }} times in 15 min"

        - record: namespace_pod:container_cpu_usage:rate5m
          expr: |
            sum by (namespace, pod) (
              rate(container_cpu_usage_seconds_total{container!=""}[5m])
            )
```

---

## Loki & Log Querying (LogQL)

```bash
# Install Loki + Promtail via Helm (Grafana Labs chart)
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=20Gi
```

```promql
# --- LogQL – label selectors (always required) ---

# All logs from my-app in production namespace
{namespace="production", app="my-app"}

# Logs from any pod matching a regex
{pod=~"my-app-.*", namespace="production"}

# --- Log filter expressions ---

# Lines containing "error" (case-sensitive)
{app="my-app"} |= "error"

# Lines NOT containing "health"
{app="my-app"} != "/healthz"

# Regex match
{app="my-app"} |~ "ERR.*timeout"

# --- Parsers ---

# Parse JSON log lines and filter by field
{app="my-app"} | json | level="error"

# Parse logfmt (key=value)
{app="my-app"} | logfmt | status_code >= 500

# Extract fields with pattern parser
{app="my-app"} | pattern `<ip> - - [<ts>] "<method> <path> <_>" <status> <_>`

# --- Metric queries (LogQL) ---

# Log rate per minute (last 5m)
rate({app="my-app"}[5m])

# Error log rate grouped by pod
sum by (pod) (
  rate({app="my-app"} |= "error" [5m])
)

# Count of log lines with "timeout" per 1m window
count_over_time({app="my-app"} |= "timeout" [1m])

# Bytes received per second
bytes_rate({app="my-app"}[5m])
```

---

## Tips & Tricks

```bash
# --- Prometheus storage & retention ---

# Set retention time at startup
prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.retention.time=90d \
  --storage.tsdb.retention.size=100GB \
  --storage.tsdb.path=/var/lib/prometheus

# --- Debug / health endpoints ---

# Metrics endpoint (self-monitoring)
curl http://localhost:9090/metrics

# Health check
curl http://localhost:9090/-/healthy

# Ready check
curl http://localhost:9090/-/ready

# Hot-reload config (requires --web.enable-lifecycle)
curl -X POST http://localhost:9090/-/reload

# List all active targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].labels'

# List all metric names
curl http://localhost:9090/api/v1/label/__name__/values | jq '.data[]'

# --- Recording rules for expensive queries ---
# Pre-compute expensive aggregations to speed up dashboards
# Add to a PrometheusRule or rule file:
#
# - record: job:http_requests_total:rate5m
#   expr: sum by (job) (rate(http_requests_total[5m]))
#
# - record: instance:node_cpu_utilisation:rate5m
#   expr: 1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))

# --- Prometheus Federation ---
# Scrape aggregated metrics from another Prometheus
# Add to prometheus.yml scrape_configs:
#
# - job_name: "federated-prometheus"
#   honor_labels: true
#   metrics_path: /federate
#   params:
#     match[]:
#       - '{job="my-app"}'
#       - 'up'
#   static_configs:
#     - targets:
#         - "remote-prometheus:9090"

# --- Useful public Grafana dashboard IDs (grafana.com/grafana/dashboards) ---
# 1860  – Node Exporter Full
# 315   – Kubernetes cluster monitoring (via Prometheus)
# 6417  – Kubernetes Pods
# 8588  – Kubernetes Deployment Statefulset Daemonset
# 13659 – Loki & Promtail
# 3662  – Prometheus 2.0 Stats
# 11074 – Node Exporter for Prometheus Dashboard EN 20201010
# 7249  – Kubernetes Cluster

# Import a community dashboard by ID
curl -s -X POST \
  -H "Authorization: Bearer my-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": [{"name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus"}],
    "overwrite": true,
    "pluginId": "-- Grafana --",
    "path": "db/1860"
  }' \
  "http://localhost:3000/api/dashboards/import"

# --- Grafana dashboard variables ---
# In Dashboard Settings > Variables:
# Type: Query
# Query: label_values(kube_pod_info{namespace="$namespace"}, pod)
# Use in panels: rate(http_requests_total{pod="$pod"}[5m])

# --- Check Alertmanager config ---
amtool check-config /etc/alertmanager/alertmanager.yml

# --- Silence all alerts during maintenance (1 hour) ---
amtool silence add \
  --comment="Scheduled maintenance" \
  --duration=1h \
  severity=~".*"
```
