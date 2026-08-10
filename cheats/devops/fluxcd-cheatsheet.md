# FluxCD Cheat Sheet

## Installation & Setup

```bash
# Install Flux CLI (macOS)
brew install fluxcd/tap/flux

# Check version
flux version

# Enable shell completion (bash)
source <(flux completion bash)
# Enable shell completion (zsh)
source <(flux completion zsh)

# Check prerequisites (cluster connectivity, permissions, etc.)
flux check --pre

# Export GitHub token for bootstrap
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

# Export GitLab token for bootstrap
export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
```

---

## Bootstrap

```bash
# Bootstrap with GitHub (creates repo if missing)
flux bootstrap github \
  --owner=my-org \
  --repository=my-fleet-repo \
  --branch=main \
  --path=clusters/my-cluster \
  --personal

# Bootstrap with GitLab
flux bootstrap gitlab \
  --owner=my-group \
  --repository=my-fleet-repo \
  --branch=main \
  --path=clusters/my-cluster

# Bootstrap with Bitbucket Server
flux bootstrap bitbucketserver \
  --username=my-user \
  --password=$BB_TOKEN \
  --hostname=bitbucket.example.com \
  --owner=my-project \
  --repository=my-fleet-repo \
  --path=clusters/my-cluster

# Bootstrap with a generic Git server (SSH)
flux bootstrap git \
  --url=ssh://git@gitlab.example.com/my-org/my-fleet-repo.git \
  --branch=main \
  --path=clusters/my-cluster

# Bootstrap with existing repo at custom path
flux bootstrap github \
  --owner=my-org \
  --repository=my-fleet-repo \
  --path=clusters/production \
  --branch=main

# Force reconcile bootstrap components
flux reconcile source git flux-system
flux reconcile kustomization flux-system

# Uninstall Flux (keeps CRDs by default)
flux uninstall

# Uninstall Flux including CRDs
flux uninstall --crds
```

---

## Sources

```bash
# Create a GitRepository source
flux create source git my-app \
  --url=https://github.com/my-org/my-app.git \
  --branch=main \
  --interval=1m

# Create a GitRepository source with SSH key
flux create source git my-app \
  --url=ssh://git@github.com/my-org/my-app.git \
  --branch=main \
  --secret-ref=my-ssh-credentials

# Create a HelmRepository source
flux create source helm bitnami \
  --url=https://charts.bitnami.com/bitnami \
  --interval=10m

# Create an OCI HelmRepository source
flux create source helm my-oci-charts \
  --url=oci://registry.example.com/helm-charts \
  --interval=10m

# Create an OCIRepository source
flux create source oci my-app-manifests \
  --url=oci://registry.example.com/my-org/my-app-manifests \
  --tag=latest \
  --interval=5m

# Create a Bucket source (S3-compatible)
flux create source bucket my-bucket \
  --bucket-name=my-manifests \
  --endpoint=s3.amazonaws.com \
  --provider=aws \
  --region=eu-central-1 \
  --interval=5m

# List all sources
flux get sources all

# List GitRepository sources
flux get sources git
flux get sources git --all-namespaces

# List HelmRepository sources
flux get sources helm

# Delete a source
flux delete source git my-app
flux delete source helm bitnami

# Suspend a source (stop reconciliation)
flux suspend source git my-app

# Resume a source
flux resume source git my-app

# Trigger immediate reconciliation of a GitRepository
flux reconcile source git my-app

# Export source as YAML
flux export source git my-app
```

---

## Kustomizations

```bash
# Create a Kustomization
flux create kustomization my-app \
  --source=GitRepository/my-app \
  --path=./deploy \
  --prune=true \
  --interval=5m

# Create a Kustomization targeting a specific namespace
flux create kustomization my-app \
  --source=GitRepository/my-app \
  --path=./deploy/production \
  --prune=true \
  --interval=5m \
  --target-namespace=production

# Kustomization with health checks
flux create kustomization my-app \
  --source=GitRepository/my-app \
  --path=./deploy \
  --prune=true \
  --interval=5m \
  --health-check="Deployment/my-app.production" \
  --health-check-timeout=2m

# Kustomization with dependency (wait for infra first)
flux create kustomization my-app \
  --source=GitRepository/my-app \
  --path=./deploy \
  --prune=true \
  --interval=5m \
  --depends-on=flux-system/infrastructure

# List all Kustomizations
flux get kustomizations
flux get kustomizations --all-namespaces

# Trigger immediate reconciliation
flux reconcile kustomization my-app

# Force reconciliation (ignores cache)
flux reconcile kustomization my-app --force

# Suspend / resume Kustomization
flux suspend kustomization my-app
flux resume kustomization my-app

# Delete Kustomization
flux delete kustomization my-app

# Show diff between cluster state and source
flux diff kustomization my-app

# Export Kustomization as YAML
flux export kustomization my-app
```

---

## HelmReleases

```bash
# Create a HelmRelease from a HelmRepository
flux create helmrelease my-app \
  --source=HelmRepository/bitnami \
  --chart=nginx \
  --chart-version=">=1.0.0" \
  --interval=10m \
  --target-namespace=production

# Create a HelmRelease with custom values
flux create helmrelease my-app \
  --source=HelmRepository/my-charts \
  --chart=my-app \
  --chart-version=1.2.0 \
  --interval=10m \
  --target-namespace=production \
  --values=./values-prod.yaml

# HelmRelease with valuesFrom (ConfigMap)
kubectl apply -f - <<EOF
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
  namespace: production
spec:
  interval: 10m
  chart:
    spec:
      chart: my-app
      version: ">=1.0.0"
      sourceRef:
        kind: HelmRepository
        name: my-charts
        namespace: flux-system
  valuesFrom:
    - kind: ConfigMap
      name: my-app-values
      valuesKey: values.yaml
    - kind: Secret
      name: my-app-secrets
      valuesKey: secret-values.yaml
  upgrade:
    remediation:
      remediateLastFailure: true
      retries: 3
      strategy: rollback
  rollback:
    cleanupOnFail: true
EOF

# List all HelmReleases
flux get helmreleases
flux get helmreleases --all-namespaces

# Trigger immediate reconciliation
flux reconcile helmrelease my-app --with-source

# Suspend / resume HelmRelease
flux suspend helmrelease my-app
flux resume helmrelease my-app

# Delete HelmRelease
flux delete helmrelease my-app

# Export HelmRelease as YAML
flux export helmrelease my-app
```

---

## Image Automation

```bash
# Create an ImageRepository (scan container registry)
flux create image repository my-app \
  --image=registry.example.com/my-org/my-app \
  --interval=1m \
  --secret-ref=registry-credentials

# Create an ImagePolicy (latest semver)
flux create image policy my-app \
  --image-ref=my-app \
  --select-semver=">=1.0.0"

# Create an ImagePolicy (latest matching regex)
flux create image policy my-app \
  --image-ref=my-app \
  --select-numeric=asc \
  --filter-regex="^main-[a-f0-9]+-([0-9]+)$" \
  --filter-extract="$1"

# Create an ImageUpdateAutomation
flux create image update my-automation \
  --git-repo-ref=my-app \
  --git-repo-namespace=flux-system \
  --git-branch=main \
  --author-name="Flux Bot" \
  --author-email=fluxbot@example.com \
  --commit-template="chore: update image to {{range .Updated.Images}}{{.}}{{end}}"

# List all image resources
flux get image all
flux get image repositories
flux get image policies

# Trigger image scan
flux reconcile image repository my-app

# Mark image tag in deployment for automated updates
# (add marker comment to the deployment manifest)
# image: registry.example.com/my-org/my-app:1.0.0 # {"$imagepolicy": "flux-system:my-app"}

# Suspend / resume image automation
flux suspend image update my-automation
flux resume image update my-automation
```

---

## Notifications & Alerts

```bash
# Create a Slack alert provider
flux create alert-provider slack \
  --type=slack \
  --channel=my-deployments \
  --secret-ref=slack-url

# Create a GitHub commit status provider
flux create alert-provider github \
  --type=github \
  --address=https://github.com/my-org/my-app \
  --secret-ref=github-token

# Create a Microsoft Teams provider
flux create alert-provider teams \
  --type=msteams \
  --address=https://outlook.office.com/webhook/xxxx

# Create a PagerDuty provider
flux create alert-provider pagerduty \
  --type=pagerduty \
  --address=https://events.pagerduty.com/v2/enqueue \
  --secret-ref=pagerduty-token

# Create a GitLab commit status provider
flux create alert-provider gitlab \
  --type=gitlab \
  --address=https://gitlab.example.com/my-org/my-app \
  --secret-ref=gitlab-token

# Create an Alert (send events to a provider)
flux create alert my-app-alert \
  --provider-ref=slack \
  --event-severity=info \
  --event-source=GitRepository/my-app \
  --event-source=Kustomization/my-app

# Alert only on errors
flux create alert my-app-errors \
  --provider-ref=slack \
  --event-severity=error \
  --event-source=HelmRelease/my-app

# List alert providers
flux get alert-providers
flux get alerts

# Delete an alert
flux delete alert my-app-alert

# Export alert configuration
flux export alert my-app-alert
```

---

## Multi-Tenancy

```bash
# Create a tenant namespace with RBAC
flux create tenant my-tenant \
  --with-namespace=my-tenant \
  --label=environment=production

# Kustomization with tenant service account (restricts permissions)
kubectl apply -f - <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-tenant-app
  namespace: my-tenant
spec:
  interval: 5m
  path: ./deploy
  prune: true
  serviceAccountName: my-tenant    # impersonate this SA
  sourceRef:
    kind: GitRepository
    name: my-tenant-repo
    namespace: my-tenant
EOF

# Cross-namespace source reference (allow tenant to use shared source)
kubectl apply -f - <<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-tenant-app
  namespace: my-tenant
spec:
  interval: 5m
  path: ./deploy
  prune: true
  sourceRef:
    kind: GitRepository
    name: shared-infra
    namespace: flux-system    # reference source in another namespace
EOF

# Create RBAC for a tenant (restrict to own namespace)
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: flux-reconciler
  namespace: my-tenant
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: my-tenant
    namespace: my-tenant
EOF

# List tenants
flux get kustomizations --all-namespaces | grep my-tenant
```

---

## Status & Debugging

```bash
# Get all Flux resources across all namespaces
flux get all
flux get all --all-namespaces

# Show Flux statistics
flux stats

# Stream Flux controller logs
flux logs
flux logs --follow
flux logs --level=error
flux logs --kind=HelmRelease

# Trace a Flux object (full dependency chain)
flux trace kustomization my-app
flux trace helmrelease my-app --namespace production

# Show recent Flux events
flux events
flux events --for GitRepository/my-app

# Check GitRepository status
kubectl get gitrepository -A
kubectl describe gitrepository my-app -n flux-system

# Check Kustomization status
kubectl get kustomization -A
kubectl describe kustomization my-app -n flux-system

# Check HelmRelease status
kubectl get helmrelease -A
kubectl describe helmrelease my-app -n production

# Common error: "Source not ready" – check source status
flux get sources git --all-namespaces

# Common error: "kustomize build failed" – check path
kubectl describe kustomization my-app -n flux-system | grep -A10 "Status:"

# Common error: Helm upgrade failed – check remediation
kubectl describe helmrelease my-app -n production | grep -A20 "Status:"

# Get controller logs for deeper debugging
kubectl logs -n flux-system \
  -l app=source-controller -f

kubectl logs -n flux-system \
  -l app=helm-controller -f

kubectl logs -n flux-system \
  -l app=kustomize-controller -f
```

---

## Tips & Tricks

```bash
# Export all Flux CRs to YAML (backup)
flux export source git --all > sources.yaml
flux export kustomization --all > kustomizations.yaml
flux export helmrelease --all > helmreleases.yaml

# Push a local OCI artifact to a registry as Flux source
flux push artifact oci://registry.example.com/my-org/my-manifests:latest \
  --path=./deploy

# Tag an OCI artifact
flux tag artifact oci://registry.example.com/my-org/my-manifests:latest \
  --tag=production

# Use OCI artifact as Flux source
flux create source oci my-manifests \
  --url=oci://registry.example.com/my-org/my-manifests \
  --tag=production \
  --interval=5m

# Diff a Kustomization before applying
flux diff kustomization my-app --path=./deploy

# Check what would change without applying
flux diff kustomization my-app

# Watch reconciliation in real time
watch flux get kustomizations

# Flux vs ArgoCD quick comparison:
# ┌─────────────────┬───────────────────┬──────────────────────┐
# │ Feature         │ FluxCD            │ ArgoCD               │
# ├─────────────────┼───────────────────┼──────────────────────┤
# │ UI              │ None (CLI/kubectl)│ Full web UI          │
# │ Config model    │ CRD-native        │ Application CRD      │
# │ Image updates   │ Built-in          │ Plugin required      │
# │ Multi-tenancy   │ Namespace-native  │ Projects + AppSets   │
# │ Notifications   │ Notification ctrl │ Built-in             │
# │ Helm support    │ HelmRelease CRD   │ Helm as source       │
# └─────────────────┴───────────────────┴──────────────────────┘

# Install VS Code Flux extension
code --install-extension weaveworks.vscode-gitops-tools
```
