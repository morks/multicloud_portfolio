# ArgoCD Cheat Sheet

## Installation & Setup

```bash
# Install ArgoCD CLI (macOS)
brew install argocd

# Check version
argocd version

# Install ArgoCD in Kubernetes
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Retrieve initial password
argocd admin initial-password -n argocd
# or:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Expose ArgoCD server via port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# then: https://localhost:8080

# Log in
argocd login localhost:8080 \
  --username admin \
  --password <password> \
  --insecure

# Change password
argocd account update-password \
  --current-password <old> \
  --new-password <new>

# Log in via Kubernetes context (when inside cluster)
argocd login --core
```

---

## Manage Applications

```bash
# List all applications
argocd app list

# Show application details
argocd app get my-app

# Create application (from Git repository)
argocd app create my-app \
  --repo https://github.com/my-org/my-repo.git \
  --path helm/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production

# Create application with Helm values
argocd app create my-app \
  --repo https://github.com/my-org/my-repo.git \
  --path helm/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --helm-set replicaCount=3 \
  --helm-set image.tag=v1.2.0

# Create application with Helm values file
argocd app create my-app \
  --repo https://github.com/my-org/my-repo.git \
  --path helm/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --values values-prod.yaml

# Enable auto-sync
argocd app set my-app \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Disable auto-sync
argocd app set my-app --sync-policy none

# Sync application (deploy)
argocd app sync my-app

# Sync with prune (delete outdated resources)
argocd app sync my-app --prune

# Force sync
argocd app sync my-app --force

# Track sync status live
argocd app wait my-app --sync --health

# Delete application (with resources)
argocd app delete my-app
# delete without resources:
argocd app delete my-app --cascade=false
```

---

## Sync Status & Health

```bash
# Check app status
argocd app get my-app

# List all apps with status
argocd app list -o wide

# Show OutOfSync apps
argocd app list | grep OutOfSync

# Diff between Git and live state
argocd app diff my-app

# Diff for specific resource
argocd app diff my-app --resource apps:Deployment:my-deploy

# List resources of an app
argocd app resources my-app

# Show app logs (pod logs)
argocd app logs my-app
argocd app logs my-app --container app

# Deployment history
argocd app history my-app

# Rollback to previous version
argocd app rollback my-app <revision-id>
argocd app rollback my-app 0   # latest version
```

---

## Projects

```bash
# List projects
argocd proj list

# Show project details
argocd proj get my-project

# Create project
argocd proj create my-project \
  --description "Production Apps" \
  --src https://github.com/my-org/my-repo.git \
  --dest https://kubernetes.default.svc,production

# Add source repository
argocd proj add-source my-project \
  https://github.com/my-org/another-repo.git

# Add destination
argocd proj add-destination my-project \
  https://kubernetes.default.svc staging

# Set cluster resource whitelist
argocd proj allow-cluster-resource my-project \
  "" Namespace

# Blacklist namespaced resources
argocd proj deny-namespace-resource my-project \
  "" LimitRange

# Delete project
argocd proj delete my-project
```

---

## Cluster & Repositories

```bash
# List clusters
argocd cluster list

# Add cluster (from current kubeconfig context)
argocd cluster add my-context-name
argocd cluster add my-context-name --name "Prod-Cluster"

# Remove cluster
argocd cluster rm https://my-cluster-api:6443

# List repositories
argocd repo list

# Add Git repository (HTTPS with token)
argocd repo add https://github.com/my-org/my-repo.git \
  --username my-user \
  --password <token>

# Add Git repository with SSH key
argocd repo add git@github.com:my-org/my-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa

# Add Helm repository
argocd repo add https://charts.bitnami.com/bitnami \
  --type helm \
  --name bitnami

# OCI Helm repository
argocd repo add registry.beispiel.de \
  --type helm \
  --name my-oci-registry \
  --enable-oci \
  --username my-user \
  --password <token>

# Remove repository
argocd repo rm https://github.com/my-org/my-repo.git
```

---

## Users & RBAC

```bash
# List users
argocd account list

# Show own account status
argocd account get --account my-user

# Create token for user
argocd account generate-token --account ci-user

# Token with expiry (24h)
argocd account generate-token \
  --account ci-user \
  --expires-in 24h

# Set password for user
argocd account update-password \
  --account my-user \
  --new-password <new-password>

# Reset admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'

# RBAC policy (in argocd-rbac-cm ConfigMap)
# p, role:developer, applications, sync, */*, allow
# p, role:developer, applications, get, */*, allow
# g, my-user, role:developer
```

---

## ApplicationSets

```bash
# List ApplicationSets
argocd appset list

# Create ApplicationSet (list)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-apps
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - cluster: dev
        url: https://dev.k8s.beispiel.de
      - cluster: prod
        url: https://prod.k8s.beispiel.de
  template:
    metadata:
      name: '{{cluster}}-my-app'
    spec:
      project: my-project
      source:
        repoURL: https://github.com/my-org/my-repo.git
        path: helm/my-app
        targetRevision: HEAD
      destination:
        server: '{{url}}'
        namespace: my-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
EOF

# Delete ApplicationSet
argocd appset delete my-apps
```

---

## App of Apps Pattern

```yaml
# Root app (manages other ArgoCD apps)
# apps/templates/child-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ .Values.name }}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: {{ .Values.project }}
  source:
    repoURL: {{ .Values.repoURL }}
    path: {{ .Values.path }}
    targetRevision: {{ .Values.targetRevision | default "HEAD" }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ .Values.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## CLI Context & Multiple ArgoCD Servers

```bash
# Show current context
argocd context

# Switch to another server
argocd context prod-argocd

# Log in to second server
argocd login argocd.prod.beispiel.de \
  --username admin \
  --password <password> \
  --name prod-argocd

# List all configured contexts
cat ~/.argocd/config | grep -A2 servers
```

---

## Emergency & Troubleshooting

```bash
# Restart ArgoCD server
kubectl rollout restart deployment argocd-server -n argocd

# Sync waves and hooks in annotations
# argocd.argoproj.io/sync-wave: "0"        # Order
# argocd.argoproj.io/hook: PreSync         # Hook type
# argocd.argoproj.io/hook-delete-policy: HookSucceeded

# Exclude resource from ArgoCD management
argocd app patch-resource my-app \
  --kind Deployment \
  --resource-name my-deploy \
  --patch '{"metadata":{"annotations":{"argocd.argoproj.io/managed": "false"}}}' \
  --patch-type application/merge-patch+json

# App controller logs
kubectl logs -n argocd \
  -l app.kubernetes.io/name=argocd-application-controller \
  -f

# Server logs
kubectl logs -n argocd \
  -l app.kubernetes.io/name=argocd-server \
  -f

# List all ArgoCD pods
kubectl get pods -n argocd

# ArgoCD version in cluster
kubectl -n argocd get deploy argocd-server \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```
