# Rancher Cheat Sheet

## Installation & Setup

```bash
# Install Rancher CLI (macOS)
brew install rancher-cli

# Or download binary manually
curl -LO https://github.com/rancher/cli/releases/latest/download/rancher-linux-amd64.tar.gz
tar xvf rancher-linux-amd64.tar.gz && sudo mv rancher /usr/local/bin/

# Check version
rancher --version

# Log in to Rancher server
rancher login https://rancher.example.com \
  --token token-xxxxx:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Log in and store context by name
rancher login https://rancher.example.com \
  --token token-xxxxx:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
  --name prod-rancher

# Enable shell completion (bash)
source <(rancher completion bash)
# Enable shell completion (zsh)
source <(rancher completion zsh)

# Install Rancher Desktop (macOS)
brew install --cask rancher

# Rancher Desktop CLI basics (rdctl)
rdctl version
rdctl list-settings                  # show current settings
rdctl set --container-engine=containerd
rdctl set --kubernetes-version=1.29.0
rdctl start                          # start Rancher Desktop
rdctl stop                           # stop Rancher Desktop
rdctl shell                          # open shell inside VM
```

---

## Cluster Management

```bash
# List all clusters
rancher cluster list
rancher clusters ls

# Show cluster details
rancher cluster ls --format json | jq '.[] | select(.name=="my-cluster")'

# Import an existing Kubernetes cluster
rancher cluster import my-cluster
# (then apply the generated kubectl command on the target cluster)

# Create a new cluster (RKE hosted on existing nodes)
rancher cluster create my-cluster \
  --rke-config=rke-config.yaml

# Delete a cluster
rancher cluster delete my-cluster

# Get kubeconfig for a cluster
rancher cluster kubeconfig my-cluster > ~/.kube/my-cluster.kubeconfig
export KUBECONFIG=~/.kube/my-cluster.kubeconfig

# Run kubectl commands through Rancher (without kubeconfig file)
rancher cluster kubectl my-cluster -- get pods -A

# Check cluster health
rancher cluster ls | grep my-cluster

# Add a node to a cluster (generate registration command)
rancher cluster add-node my-cluster \
  --etcd \
  --controlplane \
  --worker

# Remove a node from a cluster
rancher node delete my-cluster:my-node

# Supported cluster drivers
# RKE   – Rancher Kubernetes Engine (on-prem VMs)
# RKE2  – hardened successor to RKE
# K3s   – lightweight Kubernetes
# EKS   – Amazon Elastic Kubernetes Service
# GKE   – Google Kubernetes Engine
# AKS   – Azure Kubernetes Service

# Scale cluster node pool (cloud driver)
rancher cluster scale my-cluster --node-pool default --count 5
```

---

## RKE2 / K3s Cluster Bootstrap

```bash
# Install RKE2 server (first control-plane node)
curl -sfL https://get.rke2.io | sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service

# RKE2 kubeconfig location
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
# or copy to user
cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
chmod 600 ~/.kube/config

# Add a worker node to an existing RKE2 cluster
# (on the server, get the node-token first)
cat /var/lib/rancher/rke2/server/node-token

# On the worker node:
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -
cat <<EOF > /etc/rancher/rke2/config.yaml
server: https://my-cluster-server:9345
token: <node-token>
EOF
systemctl enable rke2-agent.service
systemctl start rke2-agent.service

# Upgrade RKE2 cluster (rolling)
curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.30.0+rke2r1 sh -
systemctl restart rke2-server.service

# Backup etcd snapshot (RKE2)
rke2 etcd-snapshot save --name my-backup
rke2 etcd-snapshot list
rke2 etcd-snapshot restore --name my-backup

# Install K3s (single-node or first server)
curl -sfL https://get.k3s.io | sh -

# K3s kubeconfig location
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# K3s kubectl shortcut
k3s kubectl get nodes
k3s kubectl get pods -A

# Add a K3s agent node
# (on the server, get the token)
cat /var/lib/rancher/k3s/server/node-token

# On the agent node:
curl -sfL https://get.k3s.io | \
  K3S_URL=https://my-server:6443 \
  K3S_TOKEN=<node-token> sh -

# Install k3sup (helper tool for K3s over SSH)
brew install k3sup

# Deploy K3s to a remote server with k3sup
k3sup install \
  --ip 203.0.113.10 \
  --user ubuntu \
  --ssh-key ~/.ssh/id_rsa

# Join a node with k3sup
k3sup join \
  --ip 203.0.113.11 \
  --server-ip 203.0.113.10 \
  --user ubuntu
```

---

## Projects & Namespaces

```bash
# List all projects (within current cluster context)
rancher projects list
rancher projects ls

# Create a project
rancher projects create my-project \
  --cluster my-cluster \
  --description "Production workloads"

# Delete a project
rancher projects delete my-project

# Add a namespace to a project
rancher namespaces create my-namespace \
  --project my-project

# List namespaces in a project
rancher namespaces list --project my-project

# Move a namespace to another project
rancher namespaces move my-namespace my-other-project

# Add a member to a project (with role)
rancher projects add-member my-project \
  --user my-user \
  --role project-member

# Remove a member from a project
rancher projects remove-member my-project --user my-user

# Set project resource quota
# (done via Rancher UI or API – CLI example using kubectl)
kubectl annotate namespace my-namespace \
  field.cattle.io/projectId=my-cluster:my-project

# Default system projects (auto-created)
# Default – for user workloads
# System  – for Rancher system components
```

---

## App Catalog & Helm

```bash
# Add a Helm chart catalog
rancher catalog add my-catalog \
  --url https://charts.example.com \
  --branch main

# Add a Helm OCI catalog
rancher catalog add my-oci-catalog \
  --url oci://registry.example.com/helm-charts

# List available catalogs
rancher catalog list

# Refresh catalog (re-index charts)
rancher catalog refresh my-catalog

# Delete a catalog
rancher catalog delete my-catalog

# Install an app from catalog
rancher app install my-catalog/my-chart \
  --name my-app \
  --namespace my-namespace \
  --set replicaCount=2 \
  --set image.tag=v1.2.0

# Install with values file
rancher app install my-catalog/my-chart \
  --name my-app \
  --namespace my-namespace \
  --values ./values-prod.yaml

# List installed apps
rancher app list
rancher app ls

# Upgrade an installed app
rancher app upgrade my-app \
  --set image.tag=v1.3.0

# Delete an installed app
rancher app delete my-app

# Deploy Helm chart directly via kubectl (Rancher-managed cluster)
helm install my-app my-catalog/my-chart \
  --namespace my-namespace \
  --create-namespace \
  --values ./values-prod.yaml

# Add Rancher app store repositories (v2 – Cluster Explorer)
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: my-chart-repo
spec:
  url: https://charts.example.com
EOF
```

---

## Fleet (GitOps)

```bash
# Fleet is Rancher's built-in GitOps engine (multi-cluster)

# Apply a Fleet bundle from local directory
fleet apply --name my-app ./my-app-bundle/

# List all Fleet bundles
fleet get bundles -A

# List all Git repos registered in Fleet
fleet get gitrepos -A

# Delete a bundle
fleet delete bundle my-app -n fleet-local

# Register a GitRepo in Fleet
kubectl apply -f - <<EOF
apiVersion: fleet.cattle.io/v1alpha1
kind: GitRepo
metadata:
  name: my-app
  namespace: fleet-local    # fleet-local = local cluster, fleet-default = all downstream
spec:
  repo: https://github.com/my-org/my-app.git
  branch: main
  paths:
    - ./deploy
  targets:
    - name: production
      clusterSelector:
        matchLabels:
          env: production
EOF

# BundleDeployment – check status per cluster
kubectl get bundledeployment -A

# Cluster label selector – target specific clusters
kubectl label cluster.fleet.cattle.io my-cluster env=production

# Multi-cluster deployment with override per cluster
# fleet.yaml in repo root:
# defaultNamespace: my-namespace
# targetCustomizations:
#   - name: production
#     clusterSelector:
#       matchLabels:
#         env: production
#     helm:
#       values:
#         replicaCount: 3

# Fleet namespaces:
# fleet-local    – bundles deployed only to local (Rancher) cluster
# fleet-default  – bundles deployed to all downstream clusters
```

---

## RBAC & Authentication

```bash
# List global roles
rancher role list
rancher roles ls

# Show settings
rancher settings list

# Change a Rancher setting
rancher settings set ui-pl Rancher

# List API keys / service account tokens
rancher token list

# Create a service account API key
rancher token create \
  --description "CI pipeline token" \
  --ttl 0    # 0 = no expiry

# Delete a token
rancher token delete token-xxxxx

# Global roles (built-in)
# admin              – full Rancher admin
# user               – standard user
# restricted-admin   – admin without user management

# Project roles (built-in)
# project-owner      – full control within project
# project-member     – deploy, view resources
# read-only          – view only

# Configure GitHub OAuth provider (via Rancher UI or API)
curl -X POST https://rancher.example.com/v3/githubconfigs \
  -H "Authorization: Bearer $RANCHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "my-github-client-id",
    "clientSecret": "my-github-client-secret",
    "enabled": true,
    "hostname": "github.com"
  }'

# Configure LDAP / Active Directory (example API call)
# Recommended: use Rancher UI under Global Settings > Authentication

# List all users
rancher users list

# Disable a user
rancher users disable my-user
```

---

## Monitoring & Logging

```bash
# Enable Rancher Monitoring (Prometheus + Grafana) via Helm
helm install rancher-monitoring \
  rancher-charts/rancher-monitoring \
  --namespace cattle-monitoring-system \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=7d

# Access Grafana (port-forward)
kubectl port-forward svc/rancher-monitoring-grafana \
  -n cattle-monitoring-system 3000:80 &
# then open: http://localhost:3000

# Access Prometheus (port-forward)
kubectl port-forward svc/rancher-monitoring-prometheus \
  -n cattle-monitoring-system 9090:9090 &

# Enable Rancher Logging (Banzai Cloud / Logging Operator) via Helm
helm install rancher-logging \
  rancher-charts/rancher-logging \
  --namespace cattle-logging-system \
  --create-namespace

# Configure a log output to Elasticsearch
kubectl apply -f - <<EOF
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterOutput
metadata:
  name: elasticsearch-output
  namespace: cattle-logging-system
spec:
  elasticsearch:
    host: my-elasticsearch.example.com
    port: 9200
    index_name: rancher-logs
EOF

# Configure a log output to Loki
kubectl apply -f - <<EOF
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterOutput
metadata:
  name: loki-output
  namespace: cattle-logging-system
spec:
  loki:
    url: http://loki.my-namespace:3100
    buffer:
      timekey: 1m
      timekey_wait: 30s
EOF

# Create a ClusterFlow to collect pod logs and send to output
kubectl apply -f - <<EOF
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterFlow
metadata:
  name: all-logs
  namespace: cattle-logging-system
spec:
  match:
    - select: {}
  outputRefs:
    - elasticsearch-output
EOF

# Check logging operator status
kubectl get logging -A
kubectl get clusteroutput -A
kubectl get clusterflow -A
```

---

## Node & Infrastructure

```bash
# List all nodes across clusters
rancher nodes list

# List nodes in a specific cluster
rancher nodes list --cluster my-cluster

# Show node details
rancher nodes ls | grep my-node

# Delete / remove a node
rancher node delete my-cluster:my-node

# Cordon a node (via kubectl)
kubectl cordon my-node

# Drain a node (via kubectl)
kubectl drain my-node \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force

# Uncordon a node
kubectl uncordon my-node

# List node drivers (cloud providers)
rancher node-driver list

# Enable a node driver
rancher node-driver enable digitalocean

# List node templates
rancher node-template list

# Create a node template (example: AWS)
rancher node-template create my-aws-template \
  --driver amazonec2 \
  --amazonec2-instance-type t3.large \
  --amazonec2-region eu-central-1 \
  --amazonec2-ami ami-xxxxxxxxx

# List cloud credentials
rancher cloud-credential list

# Create cloud credential for AWS
rancher cloud-credential create my-aws-creds \
  --driver aws \
  --aws-access-key-id $AWS_ACCESS_KEY_ID \
  --aws-secret-access-key $AWS_SECRET_ACCESS_KEY

# Machine list (Rancher provisioned nodes)
rancher machine list
```

---

## Tips & Tricks

```bash
# Rancher API explorer – browse all resources interactively
# v3 API: https://rancher.example.com/v3
# v1 API (Norman): https://rancher.example.com/v1

# Quick kubectl alias for a managed cluster
alias kprod='kubectl --kubeconfig ~/.kube/my-cluster.kubeconfig'
kprod get pods -A

# Access Rancher API with curl
RANCHER_URL=https://rancher.example.com
RANCHER_TOKEN=token-xxxxx:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# List clusters via API
curl -s -H "Authorization: Bearer $RANCHER_TOKEN" \
  "$RANCHER_URL/v3/clusters" | jq '.data[].name'

# Get a specific cluster kubeconfig via API
curl -s -X POST \
  -H "Authorization: Bearer $RANCHER_TOKEN" \
  "$RANCHER_URL/v3/clusters/my-cluster?action=generateKubeconfig" \
  | jq -r '.config' > ~/.kube/my-cluster.kubeconfig

# Useful Rancher API endpoints
# /v3/clusters                        – all clusters
# /v3/projects                        – all projects
# /v3/nodes                           – all nodes
# /v3/users                           – all users
# /v3/globalroles                     – global RBAC roles
# /v3/settings                        – Rancher settings

# Install Rancher Backup Operator
helm install rancher-backup \
  rancher-charts/rancher-backup \
  --namespace cattle-resources-system \
  --create-namespace \
  --set s3.enabled=true \
  --set s3.bucketName=my-rancher-backups \
  --set s3.region=eu-central-1

# Trigger a manual backup
kubectl apply -f - <<EOF
apiVersion: resources.cattle.io/v1
kind: Backup
metadata:
  name: my-backup
spec:
  storageLocation:
    s3:
      bucketName: my-rancher-backups
      region: eu-central-1
EOF

# Cluster template (RKE template) – enforce cluster config across teams
# Create via Rancher UI: Cluster Management > RKE Templates

# Access downstream cluster directly (bypass Rancher)
kubectl config use-context my-cluster
kubectl get nodes    # direct access to downstream cluster

# Multi-tenant pattern:
# 1. Create a cluster per tenant (hard isolation)
# 2. Create a project per tenant (namespace isolation)
# 3. Use Fleet GitRepo per tenant (separate Git paths/repos)
# 4. Assign project-owner role to tenant admin user

# Rancher system upgrade controller (for automated K8s upgrades)
kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/latest/download/system-upgrade-controller.yaml

kubectl apply -f - <<EOF
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-server-upgrade
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  channel: https://update.k3s.io/v1-release/channels/stable
  upgrade:
    image: rancher/k3s-upgrade
  nodeSelector:
    matchExpressions:
      - {key: node-role.kubernetes.io/control-plane, operator: In, values: ["true"]}
EOF
```
