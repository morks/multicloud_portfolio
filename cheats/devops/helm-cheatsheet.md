# Helm Cheat Sheet

## Installation & Setup

```bash
# Install (macOS)
brew install helm

# Check version
helm version

# Set up shell completion
echo 'source <(helm completion zsh)' >> ~/.zshrc

# Helm plugin directory
helm plugin list
helm env
```

---

## Repositories

```bash
# List repos
helm repo list

# Add repo
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add cert-manager https://charts.jetstack.io
helm repo add argo https://argoproj.github.io/argo-helm

# Update repos (reload package list)
helm repo update

# Remove repo
helm repo remove stable

# Search charts in a repo
helm search repo bitnami
helm search repo bitnami/nginx

# Search charts on ArtifactHub
helm search hub wordpress
```

---

## Installing Charts

```bash
# Install chart (auto-generated release name)
helm install bitnami/nginx --generate-name

# Install chart with name
helm install my-nginx bitnami/nginx

# Install into specific namespace
helm install my-nginx bitnami/nginx \
  --namespace production \
  --create-namespace

# Override values (--set)
helm install my-nginx bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=LoadBalancer

# With values.yaml file
helm install my-nginx bitnami/nginx \
  -f my-values.yaml

# Multiple values files (overriding left to right)
helm install my-nginx bitnami/nginx \
  -f base-values.yaml \
  -f prod-values.yaml

# Install specific chart version
helm install my-nginx bitnami/nginx \
  --version 15.3.0

# Dry-run (render only, do not install)
helm install my-nginx bitnami/nginx \
  --dry-run --debug

# Atomic (automatic rollback on error)
helm install my-nginx bitnami/nginx \
  --atomic --timeout 5m
```

---

## Managing Releases

```bash
# List all releases
helm list
helm ls -A                  # all namespaces
helm ls -n production       # in specific namespace

# Show release status
helm status my-nginx

# Release details / generated manifests
helm get all my-nginx
helm get manifest my-nginx
helm get values my-nginx
helm get notes my-nginx

# Upgrade release
helm upgrade my-nginx bitnami/nginx \
  --set replicaCount=5

# Upgrade or install (combined)
helm upgrade --install my-nginx bitnami/nginx \
  -f values.yaml \
  --namespace production \
  --create-namespace

# Rollback to previous version
helm rollback my-nginx

# Rollback to specific revision
helm rollback my-nginx 2

# Show release history
helm history my-nginx

# Uninstall release
helm uninstall my-nginx
helm uninstall my-nginx -n production

# Uninstall release (keep history)
helm uninstall my-nginx --keep-history
```

---

## Creating Charts

```bash
# Create new chart scaffold
helm create my-chart

# Chart structure
# my-chart/
# ├── Chart.yaml          # Metadata
# ├── values.yaml         # Default values
# ├── charts/             # Dependencies
# └── templates/          # Kubernetes manifests
#     ├── deployment.yaml
#     ├── service.yaml
#     ├── ingress.yaml
#     ├── _helpers.tpl    # Helper macros
#     └── NOTES.txt       # Post-install notes

# Validate chart (linting)
helm lint my-chart

# Render chart (without installing)
helm template my-release my-chart
helm template my-release my-chart -f values.yaml

# Package chart
helm package my-chart

# Test chart in local registry
helm install test-release ./my-chart --dry-run
```

---

## Dependencies

```bash
# Chart.yaml with dependencies
cat << 'EOF' > Chart.yaml
apiVersion: v2
name: my-app
version: 1.0.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
EOF

# Download dependencies
helm dependency update my-chart

# List dependencies
helm dependency list my-chart

# Rebuild dependencies (from charts/ dir)
helm dependency build my-chart
```

---

## OCI Registries (from Helm 3.8)

```bash
# OCI registry login
helm registry login registry.beispiel.de \
  --username my-user \
  --password my-token

# Push chart to OCI registry
helm push my-chart-1.0.0.tgz oci://registry.beispiel.de/charts

# Install chart from OCI registry
helm install my-release \
  oci://registry.beispiel.de/charts/my-chart \
  --version 1.0.0

# OCI logout
helm registry logout registry.beispiel.de
```

---

## Plugins

```bash
# Install useful plugins
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/jkroepke/helm-secrets
helm plugin install https://github.com/quintush/helm-unittest

# Diff between installed release and new upgrade
helm diff upgrade my-nginx bitnami/nginx -f values.yaml

# Encrypt secrets with vals/sops
helm secrets install my-release ./my-chart \
  -f secrets.yaml

# Run unit tests
helm unittest my-chart

# List all plugins
helm plugin list
```

---

## Templating – Go Templates

```yaml
# values.yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

```yaml
# templates/deployment.yaml – Example
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
```

```bash
# Common template functions
{{ .Values.key }}                        # Value from values.yaml
{{ .Release.Name }}                      # Release name
{{ .Release.Namespace }}                 # Namespace
{{ .Chart.Name }}                        # Chart name
{{ .Chart.Version }}                     # Chart version
{{ default "fallback" .Values.key }}     # Default value
{{ required "Pflichtfeld!" .Values.key }}# Required field
{{ toYaml .Values.obj | nindent 4 }}    # Indent YAML output
{{ include "helper.name" . }}           # Include helper macro
{{- if .Values.ingress.enabled }}       # Condition
{{- range .Values.list }}               # Iteration
{{ . }}
{{- end }}
```

---

## Tips & Best Practices

```bash
# Check currently used chart version
helm show chart bitnami/nginx | grep version

# Show all versions of a chart
helm search repo bitnami/nginx --versions

# Show chart documentation
helm show readme bitnami/nginx
helm show values bitnami/nginx           # Default values

# Default values as base for own values.yaml
helm show values bitnami/nginx > my-values.yaml

# Export release manifest as backup
helm get manifest my-nginx > my-nginx-backup.yaml

# Output namespaces for all releases
helm ls -A -o json | jq '.[] | {name, namespace, status}'

# Find outdated charts
helm list -A -o json | \
  jq '.[] | select(.status != "deployed") | {name, status}'
```
