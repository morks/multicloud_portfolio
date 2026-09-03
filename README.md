# 🌐 Multi-Cloud Admin Portfolio

> **Your Quick Reference for Cloud Architectures & DevOps Tooling**  
> Battle-tested CLI commands, workflows, and cheat sheets for multi-cloud admins.

---

## 🗺️ Overview

This repository is a curated collection of cheat sheets and references for admins and architects who work daily with multiple cloud platforms and modern DevOps tools. No noise, no theory — just the commands that are actually needed.

https://morks.github.io/multicloud_portfolio/

---

## 🌐 Cloud Provider Portals

| Provider | Web Console | Status |
|---|---|---|
| **AWS** | [console.aws.amazon.com](https://console.aws.amazon.com) | Global |
| **Azure** | [portal.azure.com](https://portal.azure.com) | Global |
| **Azure Arc** | [portal.azure.com/#blade/…/AzureArc](https://portal.azure.com/#blade/Microsoft_Azure_HybridCompute/AzureArcCenterBlade/overview) | Part of Azure |
| **Google Cloud** | [console.cloud.google.com](https://console.cloud.google.com) | Global |
| **Anthos** | [console.cloud.google.com/anthos](https://console.cloud.google.com/anthos) | Part of GCP |
| **Oracle Cloud (OCI)** | [cloud.oracle.com](https://cloud.oracle.com) | Global |
| **Telekom Cloud (OTC)** | [console.otc.t-systems.com](https://console.otc.t-systems.com) | EU (T-Systems) |
| **OpenStack** | Deployment-specific (Horizon) | Self-hosted |
| **STACKIT** | [portal.stackit.cloud](https://portal.stackit.cloud) | EU (Telekom) |
| **Hetzner Cloud** | [console.hetzner.cloud](https://console.hetzner.cloud) | EU |
| **Cloudflare** | [dash.cloudflare.com](https://dash.cloudflare.com) | Global |
| **MeshStack** | [panel.meshcloud.io](https://panel.meshcloud.io) | SaaS |

---

## ☁️ Cloud Platforms

| Provider | CLI | Focus Areas |
|---|---|---|
| [AWS](cheats/cloud/aws-cli-cheatsheet.md) | `aws` | EC2, S3, IAM, SSO, Profile, STS |
| [Azure](cheats/cloud/azure-cli-cheatsheet.md) | `az` | Resources, AKS, Storage, RBAC |
| [Google Cloud](cheats/cloud/gcp-cli-cheatsheet.md) | `gcloud` | Compute, GKE, IAM, Artifact Registry |
| [Oracle Cloud (OCI)](cheats/cloud/oci-cli-cheatsheet.md) | `oci` | Compute, VCN, Object Storage, OKE, OCIR |
| [Telekom Cloud (OTC)](cheats/cloud/ctc-cheatsheet.md) | `openstack` / `otc` | ECS, VPC, OBS, CCE, DNS, EVS |
| [STACKIT](cheats/cloud/stackit-cli-cheatsheet.md) | `stackit` | Projects, Services, Kubernetes |
| [Hetzner Cloud](cheats/cloud/hetzner-cheatsheet.md) | `hcloud` | Servers, Networks, Firewalls, Load Balancers, Volumes |
| [Cloudflare](cheats/cloud/cloudflare-cheatsheet.md) | `flarectl` / `wrangler` | DNS, CDN, Workers, Zero Trust, R2, Tunnel |
| [Azure Arc](cheats/cloud/azure-arc-cheatsheet.md) | `az connectedk8s` | Arc Servers, Arc Kubernetes, GitOps, Data Services |
| [Anthos](cheats/cloud/anthos-cheatsheet.md) | `gcloud` / `nomos` | Fleet, ACM, ASM, Policy Controller, Multi-Cluster |
| [OpenStack](cheats/cloud/openstack-cheatsheet.md) | `openstack` | Nova, Neutron, Cinder, Glance, Swift, Heat, Ironic |
| [MeshStack](cheats/cloud/meshstack-cheatsheet.md) | `meshstack` | Workspaces, Projects, Landing Zones, Chargeback |

---

## 🛠️ DevOps Tools

| Tool | Cheat Sheet | Focus Areas |
|---|---|---|
| **Kubernetes** | [kubectl](cheats/devops/k8s-cheatsheet.md) | Pods, Deployments, Services, RBAC, Debugging |
| **Helm** | [helm](cheats/devops/helm-cheatsheet.md) | Charts, Releases, Repos, Templates, Plugins |
| **Terraform / OpenTofu** | [terraform](cheats/devops/terraform-cheatsheet.md) | IaC, State, Workspaces, Modules, Multi-Cloud |
| **ArgoCD** | [argocd](cheats/devops/argocd-cheatsheet.md) | GitOps, Apps, Sync, Projects, ApplicationSets |
| **Vault** | [vault](cheats/devops/vault-cheatsheet.md) | KV, PKI, Transit, Auth Methods, Policies |
| **Ansible** | [ansible](cheats/devops/ansible-cheatsheet.md) | Inventory, Playbooks, Roles, Templates, Galaxy |
| **Prometheus & Grafana** | [prometheus-grafana](cheats/devops/prometheus-grafana-cheatsheet.md) | PromQL, Alertmanager, Dashboards, Loki |
| **Docker** | [docker](cheats/devops/docker-cheatsheet.md) | Images, Container, Compose, Registry |
| **Podman** | [podman](cheats/devops/podman-cheatsheet.md) | Rootless Containers, Pods, Systemd, Compose |
| **Trivy** | [trivy](cheats/devops/trivy-cheatsheet.md) | Image Scan, IaC Scan, Secrets, SBOM, K8s Audit |
| **OpenShift** | [oc](cheats/devops/openshift-cheatsheet.md) | Projects, Builds, Routes, SCC, OLM Operators |
| **Rancher** | [rancher](cheats/devops/rancher-cheatsheet.md) | Cluster Mgmt, RKE2/K3s, Fleet GitOps, App Catalog |
| **FluxCD** | [flux](cheats/devops/fluxcd-cheatsheet.md) | GitOps, HelmRelease, Image Automation, Multi-Tenancy |
| **NGINX** | [nginx](cheats/devops/nginx-cheatsheet.md) | Server Blocks, Reverse Proxy, Load Balancing, Ingress |
| **HAProxy** | [haproxy](cheats/devops/haproxy-cheatsheet.md) | Frontend/Backend, ACLs, SSL, Health Checks, Stats |
| **MLflow** | [mlflow](cheats/devops/mlflow-cheatsheet.md) | Experiment Tracking, Model Registry, Serving, Projects |
| **NVIDIA AI Enterprise** | [nvidia](cheats/devops/nvidia-ai-enterprise-cheatsheet.md) | GPU Operator, NIM, Triton, MIG, DCGM Monitoring |
| **Git** | [git](cheats/devops/git-cheatsheet.md) | Branches, Rebase, Stash, Tags, Hooks |
| **GitHub CLI** | [gh](cheats/devops/github-cheatsheet.md) | PRs, Issues, Actions, Releases |
| **GitLab CLI** | [glab](cheats/devops/gitlab-cheatsheet.md) | MRs, CI/CD, Registry, Variables |

---

## 🚀 Quickstart: Using Cheat Sheets Directly

### Setting Up Cloud Access

```bash
# AWS – SSO Login
aws sso login --profile mein-profil
aws sts get-caller-identity

# Azure – Interactive Login
az login
az account set --subscription "Mein Abo"

# GCP – Application Default Credentials
gcloud auth login
gcloud config set project mein-projekt

# OCI – Configuration Wizard
oci setup config

# Telekom Cloud (OTC) – Source RC file
source ~/Downloads/MeinProjekt-openrc.sh
openstack token issue

# STACKIT – Login
stackit auth login
```

### Kubernetes – Switch and Check Cluster

```bash
# Show and switch contexts
kubectl config get-contexts
kubectl config use-context mein-cluster

# or interactively with kubectx
kubectx

# Quick check
kubectl get nodes -o wide
kubectl get pods -A | grep -v Running
```

### GitOps – Deploy ArgoCD App

```bash
# Login
argocd login argocd.beispiel.de --username admin

# Create app with auto-sync
argocd app create meine-app \
  --repo https://github.com/org/repo.git \
  --path helm/meine-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace produktion \
  --sync-policy automated \
  --auto-prune --self-heal

# Check status
argocd app get meine-app
```

### Read Secrets from Vault

```bash
export VAULT_ADDR='https://vault.beispiel.de'
vault login                                  # interactive
vault kv get secret/meine-app               # Read secret
vault kv get -field=db_password secret/meine-app | pbcopy  # copy directly to clipboard
```

---

## 📂 Repository Structure

```
multicloud_portfolio/
│
├── README.md                          # This file
│
├── shell-completions/                 # Shell auto-completion scripts
│   ├── README.md                      # Setup guide
│   ├── completions.sh                 # Main entry point (source this in rc file)
│   ├── clouds/                        # Cloud CLI completions
│   │   ├── aws.sh                     # AWS CLI + aws_completer
│   │   ├── azure.sh                   # Azure CLI (az)
│   │   ├── gcp.sh                     # Google Cloud SDK (gcloud)
│   │   ├── oci.sh                     # Oracle Cloud CLI (oci)
│   │   ├── openstack.sh               # OpenStack + OTC CLI
│   │   ├── stackit.sh                 # STACKIT CLI
│   │   ├── hetzner.sh                 # Hetzner Cloud CLI (hcloud)
│   │   └── cloudflare.sh              # Cloudflare (wrangler)
│   └── devops/                        # DevOps tool completions
│       ├── kubectl.sh                 # kubectl + k alias + oc (OpenShift)
│       ├── helm.sh                    # Helm
│       ├── terraform.sh               # Terraform + OpenTofu
│       ├── argocd.sh                  # ArgoCD CLI
│       ├── flux.sh                    # FluxCD CLI
│       ├── vault.sh                   # HashiCorp Vault
│       ├── github.sh                  # gh + glab
│       └── extras.sh                  # kubectx, stern, k9s
│
└── cheats/                            # All cheat sheets
    ├── README.md                      # Cheat sheet index
    │
    ├── cloud/                              # Cloud provider CLIs
    │   ├── anthos-cheatsheet.md            # Google Anthos (Fleet, ACM, ASM)
    │   ├── aws-cli-cheatsheet.md           # Amazon Web Services
    │   ├── azure-arc-cheatsheet.md         # Azure Arc (hybrid/multi-cloud)
    │   ├── azure-cli-cheatsheet.md         # Microsoft Azure
    │   ├── cloudflare-cheatsheet.md        # Cloudflare (DNS, CDN, Workers, Zero Trust)
    │   ├── ctc-cheatsheet.md               # Telekom Cloud (OTC/OpenStack)
    │   ├── gcp-cli-cheatsheet.md           # Google Cloud Platform
    │   ├── hetzner-cheatsheet.md           # Hetzner Cloud
    │   ├── meshstack-cheatsheet.md         # MeshStack (cloud management)
    │   ├── oci-cli-cheatsheet.md           # Oracle Cloud Infrastructure
    │   ├── openstack-cheatsheet.md         # OpenStack (generic/self-hosted)
    │   └── stackit-cli-cheatsheet.md       # STACKIT (Deutsche Telekom)
    │
    └── devops/                             # DevOps tooling
        ├── ansible-cheatsheet.md           # Ansible Automation
        ├── argocd-cheatsheet.md            # ArgoCD GitOps
        ├── docker-cheatsheet.md            # Docker / Container
        ├── fluxcd-cheatsheet.md            # FluxCD GitOps
        ├── git-cheatsheet.md               # Git Version Control
        ├── github-cheatsheet.md            # GitHub CLI (gh)
        ├── gitlab-cheatsheet.md            # GitLab CLI (glab)
        ├── haproxy-cheatsheet.md           # HAProxy Load Balancer
        ├── helm-cheatsheet.md              # Helm Package Manager
        ├── k8s-cheatsheet.md               # Kubernetes (kubectl)
        ├── mlflow-cheatsheet.md            # MLflow (ML Experiment Tracking)
        ├── nginx-cheatsheet.md             # NGINX Web Server / Proxy
        ├── nvidia-ai-enterprise-cheatsheet.md # NVIDIA AI Enterprise / GPU
        ├── openshift-cheatsheet.md         # OpenShift / OKD (oc CLI)
        ├── podman-cheatsheet.md            # Podman (rootless containers)
        ├── prometheus-grafana-cheatsheet.md # Prometheus & Grafana
        ├── rancher-cheatsheet.md           # Rancher Kubernetes Management
        ├── terraform-cheatsheet.md         # Terraform / OpenTofu (IaC)
        ├── trivy-cheatsheet.md             # Trivy Security Scanner
        └── vault-cheatsheet.md             # HashiCorp Vault
```

---

## 💡 Tools & Installation

### Cloud CLIs

```bash
# all at once (macOS via Homebrew)
brew install awscli azure-cli google-cloud-sdk oci-cli
brew install openstack-client          # OTC/Telekom Cloud
brew install stackit                   # STACKIT CLI
brew install hcloud                    # Hetzner Cloud
brew install cloudflare/cloudflare/flarectl   # Cloudflare
npm install -g wrangler                # Cloudflare Workers CLI
```

### DevOps Tools

```bash
brew install kubectl helm argocd vault ansible
brew install terraform                 # or: brew install opentofu
brew install kubectx k9s stern        # Kubernetes extras
brew install docker                   # or Docker Desktop
brew install podman                   # rootless Docker alternative
brew install trivy                    # security scanner
```

---

## 🤝 Contributing

Additions, corrections, and new cheat sheets are welcome!

1. Fork the repository
2. Create a branch: `git checkout -b feat/neues-cheatsheet`
3. Add the cheat sheet in the appropriate folder (`cheats/cloud/` or `cheats/devops/`)
4. Create a pull request

**Format Convention:** Each cheat sheet follows the pattern:
- Sections with `## Heading`
- Code always in ` ```bash ` blocks
- Comments in English (`# What this command does`)
- No lengthy explanations — just the essentials

---

## 📜 License

MIT License — free to use, attribution appreciated.

---

<div align="center">

**Maintained by Multi-Cloud Admins, for Multi-Cloud Admins** 🚀

*Found what you were looking for? Give the repo a ⭐*

</div>
