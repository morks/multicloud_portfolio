# OpenTelemetry (OTel) Cheat Sheet

## Overview

**OpenTelemetry (OTel)** is the CNCF standard for observability instrumentation — a vendor-neutral API/SDK/Collector for traces, metrics, and logs across any language and backend.

| | |
|---|---|
| **Strengths** | Vendor-neutral (no lock-in) · unified API for traces, metrics & logs · supports all major languages · W3C Trace Context standard · eliminates per-vendor agent sprawl · CNCF project |
| **Weaknesses** | Configuration complexity (Collector pipelines) · SDK maturity varies by language · operational overhead for Collector fleet · migration from existing agents takes effort |
| **Best for** | Standardizing observability across polyglot microservices, distributed tracing, replacing vendor-specific agents, sending telemetry to any backend (Jaeger, Tempo, Prometheus, Datadog) |

---

## Core Concepts

```bash
# Trace     — end-to-end journey of a request across services
# Span      — single unit of work within a trace (has start/end time, attributes, events)
# Context   — carries trace/span IDs across process/network boundaries (W3C TraceContext)
# Propagation — injecting/extracting context via HTTP headers (traceparent, tracestate)
# Metric    — numerical measurement over time (counter, gauge, histogram)
# Log       — timestamped event record; OTel correlates logs with traces via TraceID
# Resource  — describes the entity producing telemetry (service.name, k8s.pod.name, etc.)
# Sampler   — controls what fraction of traces is recorded (always_on, traceidratio, parentbased)
# Exporter  — sends telemetry to a backend (Jaeger, Tempo, Prometheus, OTLP endpoint)
# Collector — vendor-agnostic proxy that receives, processes, and exports telemetry
```

---

## OTel Collector — Installation

```bash
# Add OpenTelemetry Helm repo
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Install OTel Collector (DaemonSet mode — one per node)
helm install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --create-namespace \
  --set mode=daemonset \
  --values otel-collector-values.yaml

# Install in Deployment mode (single collector)
helm install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --set mode=deployment

# Docker — run collector locally for testing
docker run --rm \
  -p 4317:4317 \    # OTLP gRPC
  -p 4318:4318 \    # OTLP HTTP
  -p 8888:8888 \    # Collector metrics
  -v $(pwd)/otel-config.yaml:/etc/otelcol/config.yaml \
  otel/opentelemetry-collector-contrib:latest

# Download binary (Linux)
curl -LO https://github.com/open-telemetry/opentelemetry-collector-releases/releases/latest/download/otelcol-contrib_linux_amd64.tar.gz
tar -xzf otelcol-contrib_linux_amd64.tar.gz

# Verify collector is running
curl http://localhost:8888/metrics | grep otelcol_

# Validate collector config
otelcol validate --config=otel-config.yaml
```

---

## Collector Configuration

```bash
# otel-config.yaml — complete pipeline example

receivers:
  otlp:                                  # receive from apps via gRPC/HTTP
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  prometheus:                            # scrape Prometheus metrics
    config:
      scrape_configs:
        - job_name: otel-collector
          scrape_interval: 15s
          static_configs:
            - targets: [localhost:8888]
  filelog:                               # tail log files
    include: [/var/log/pods/*/*/*.log]
    start_at: beginning

processors:
  batch:                                 # buffer spans before export (reduces requests)
    timeout: 5s
    send_batch_size: 1024
  memory_limiter:                        # prevent OOM
    check_interval: 1s
    limit_mib: 512
  filter/errors:                         # drop non-error spans
    traces:
      span:
        - 'status.code != STATUS_CODE_ERROR'
  resource:                              # add/override resource attributes
    attributes:
      - action: insert
        key: deployment.environment
        value: production

exporters:
  otlp:                                  # forward to another collector or Tempo
    endpoint: tempo:4317
    tls:
      insecure: true
  prometheus:                            # expose metrics for Prometheus scraping
    endpoint: 0.0.0.0:8889
  loki:                                  # send logs to Loki
    endpoint: http://loki:3100/loki/api/v1/push
  debug:                                 # print to stdout (dev/debug)
    verbosity: detailed
  otlphttp/jaeger:
    endpoint: http://jaeger:4318

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp]
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
    logs:
      receivers: [otlp, filelog]
      processors: [batch]
      exporters: [loki]
```

---

## otelcli

```bash
# Install otelcli
brew install equinix-labs/otel-cli/otel-cli
# or: go install github.com/equinix-labs/otel-cli@latest

# Set endpoint (OTLP gRPC by default)
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_SERVICE_NAME=my-script

# Wrap a shell command in a span — sends trace on completion
otelcli exec --name "run-migration" -- ./migrate.sh

# Create a span manually
otelcli span create \
  --name "manual-span" \
  --attrs "db.system=postgresql,db.name=mydb"

# Create a span with a background carrier process
otelcli span background --name "deploy-step" &
BGPID=$!
# ... do work ...
otelcli span end
wait $BGPID

# Check OTLP endpoint connectivity
otelcli status

# Send a test span (no background needed)
otelcli exec --name "test" --fail-fast -- echo "hello otel"
```

---

## SDK Quick Start

```bash
# --- Python — Auto-instrumentation ---
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap --action=install         # auto-install instrumentors

# Run app with auto-instrumentation
OTEL_SERVICE_NAME=my-python-app \
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
OTEL_TRACES_SAMPLER=parentbased_traceidratio \
OTEL_TRACES_SAMPLER_ARG=0.1 \
opentelemetry-instrument python app.py

# --- Python — Manual span ---
# from opentelemetry import trace
# tracer = trace.get_tracer("my-module")
# with tracer.start_as_current_span("my-operation") as span:
#     span.set_attribute("db.statement", "SELECT * FROM users")
#     span.add_event("Query executed")

# --- Go — Manual span ---
# import "go.opentelemetry.io/otel"
# tracer := otel.Tracer("my-service")
# ctx, span := tracer.Start(ctx, "my-operation")
# span.SetAttributes(attribute.String("key", "value"))
# defer span.End()

# --- Node.js — Auto-instrumentation ---
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
# OTEL_SERVICE_NAME=my-app node -r ./tracing.js app.js

# --- Key environment variables ---
export OTEL_SERVICE_NAME=my-service
export OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc              # or http/protobuf
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer token"
export OTEL_TRACES_SAMPLER=parentbased_traceidratio
export OTEL_TRACES_SAMPLER_ARG=0.1                   # sample 10% of traces
export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=prod,team=platform"
export OTEL_LOG_LEVEL=info                            # debug|info|warn|error
```

---

## Kubernetes Operator

```bash
# Add OTel Operator Helm chart
helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace monitoring \
  --set admissionWebhooks.certManager.enabled=true    # requires cert-manager

# OpenTelemetryCollector CR — deploy a collector via operator
kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: my-collector
  namespace: monitoring
spec:
  mode: deployment    # deployment | daemonset | statefulset | sidecar
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
    exporters:
      debug: {}
    service:
      pipelines:
        traces:
          receivers: [otlp]
          exporters: [debug]
EOF

# Instrumentation CR — auto-inject SDK into pods
kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: my-instrumentation
  namespace: default
spec:
  exporter:
    endpoint: http://my-collector-collector:4317
  python:
    env:
      - name: OTEL_LOG_LEVEL
        value: debug
  nodejs: {}
  java: {}
  dotnet: {}
EOF

# Annotate a pod/deployment to auto-inject instrumentation
kubectl patch deployment my-app -n default -p \
  '{"spec":{"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/inject-python":"true"}}}}}'

# Check injected sidecars / init containers
kubectl describe pod my-app-pod | grep -A5 "Init Containers\|opentelemetry"
```

---

## Backends & Exporters

```bash
# OTLP → Grafana Tempo (traces)
# exporter in collector config:
# otlp:
#   endpoint: http://tempo:4317
#   tls:
#     insecure: true

# OTLP → Jaeger
# exporter:
# jaeger:
#   endpoint: http://jaeger:14250
#   tls:
#     insecure: true
# (Jaeger 1.35+ also accepts OTLP directly on port 4317)

# OTLP → Zipkin
# zipkin:
#   endpoint: http://zipkin:9411/api/v2/spans

# OTLP → Datadog
# datadog:
#   api:
#     key: ${DD_API_KEY}
#     site: datadoghq.eu

# Metrics → Prometheus
# prometheus:
#   endpoint: 0.0.0.0:8889    # Prometheus scrapes this endpoint

# Logs → Loki
# loki:
#   endpoint: http://loki:3100/loki/api/v1/push
#   labels:
#     attributes:
#       service.name: "service_name"

# Test connectivity to an OTLP backend
grpcurl -plaintext localhost:4317 list
```

---

## Useful Env Vars

```bash
# Service identity
OTEL_SERVICE_NAME=my-service                           # required — identifies your service
OTEL_SERVICE_VERSION=1.2.3
OTEL_RESOURCE_ATTRIBUTES="k8s.namespace.name=prod,team=platform"

# Exporter
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317  # gRPC (default) or HTTP
OTEL_EXPORTER_OTLP_PROTOCOL=grpc                        # grpc | http/protobuf | http/json
OTEL_EXPORTER_OTLP_HEADERS="x-api-key=secret"
OTEL_EXPORTER_OTLP_TIMEOUT=10000                        # milliseconds
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://tempo:4317    # override per signal
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://prometheus:4317
OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://loki:4317

# Sampling
OTEL_TRACES_SAMPLER=parentbased_traceidratio            # parentbased_always_on | always_off | traceidratio
OTEL_TRACES_SAMPLER_ARG=0.05                            # 5% sampling rate

# Propagation
OTEL_PROPAGATORS=tracecontext,baggage                   # W3C TraceContext + Baggage (default)

# SDK behavior
OTEL_LOG_LEVEL=warn                                     # debug | info | warn | error
OTEL_SDK_DISABLED=false                                 # set to true to disable OTel entirely
OTEL_METRICS_EXEMPLAR_FILTER=trace_based               # link metrics to traces
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [opentelemetry.io/docs](https://opentelemetry.io/docs/) | OpenTelemetry documentation — concepts, language SDKs, collector, and instrumentation guides. |
| **OTel Collector Contrib** | [github.com/open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) | Extended collector with 100+ receivers, processors, and exporters for all major backends. |
| **OTel Demo App** | [opentelemetry.io/docs/demo](https://opentelemetry.io/docs/demo/) | Reference microservices app with full OTel instrumentation across multiple languages. |
| **Semantic Conventions** | [opentelemetry.io/docs/specs/semconv](https://opentelemetry.io/docs/specs/semconv/) | Standard attribute names for HTTP, databases, messaging, cloud resources, and more. |
