# Cheat Sheets

Quick references for cloud and DevOps tools, organized by category.

## 📁 Structure

```
cheats/
├── cloud/                              # Cloud provider CLIs
│   ├── anthos-cheatsheet.md
│   ├── aws-cli-cheatsheet.md
│   ├── azure-arc-cheatsheet.md
│   ├── azure-cli-cheatsheet.md
│   ├── cloudflare-cheatsheet.md
│   ├── ctc-cheatsheet.md
│   ├── gcp-cli-cheatsheet.md
│   ├── hetzner-cheatsheet.md
│   ├── ibmcloud-cheatsheet.md
│   ├── ionos-cheatsheet.md
│   ├── meshstack-cheatsheet.md
│   ├── oci-cli-cheatsheet.md
│   ├── openstack-cheatsheet.md
│   └── stackit-cli-cheatsheet.md
│
└── devops/                             # DevOps tools
    ├── ansible-cheatsheet.md
    ├── argocd-cheatsheet.md
    ├── backstage-cheatsheet.md
    ├── cert-manager-cheatsheet.md
    ├── crossplane-cheatsheet.md
    ├── docker-cheatsheet.md
    ├── external-secrets-cheatsheet.md
    ├── fluxcd-cheatsheet.md
    ├── git-cheatsheet.md
    ├── github-cheatsheet.md
    ├── gitlab-cheatsheet.md
    ├── haproxy-cheatsheet.md
    ├── helm-cheatsheet.md
    ├── k8s-cheatsheet.md
    ├── kyverno-cheatsheet.md
    ├── loki-cheatsheet.md
    ├── mlflow-cheatsheet.md
    ├── nginx-cheatsheet.md
    ├── nvidia-ai-enterprise-cheatsheet.md
    ├── openshift-cheatsheet.md
    ├── opentelemetry-cheatsheet.md
    ├── podman-cheatsheet.md
    ├── prometheus-grafana-cheatsheet.md
    ├── pulumi-cheatsheet.md
    ├── rancher-cheatsheet.md
    ├── terraform-cheatsheet.md
    ├── trivy-cheatsheet.md
    └── vault-cheatsheet.md
```

## ☁️ Cloud

| File | Content |
|---|---|
| [anthos-cheatsheet.md](cloud/anthos-cheatsheet.md) | Google Anthos – Fleet, ACM, ASM, Policy Controller, Multi-Cluster |
| [aws-cli-cheatsheet.md](cloud/aws-cli-cheatsheet.md) | AWS CLI – EC2, S3, IAM, SSO, Profile |
| [azure-arc-cheatsheet.md](cloud/azure-arc-cheatsheet.md) | Azure Arc – Hybrid/Multi-Cloud, Arc Servers, Arc K8s, GitOps, Data Services |
| [azure-cli-cheatsheet.md](cloud/azure-cli-cheatsheet.md) | Azure CLI – Resources, AKS, Storage, RBAC |
| [cloudflare-cheatsheet.md](cloud/cloudflare-cheatsheet.md) | Cloudflare – DNS, CDN, Workers, Zero Trust, R2, Tunnel |
| [ctc-cheatsheet.md](cloud/ctc-cheatsheet.md) | Telekom Cloud (OTC) – OpenStack, ECS, OBS, CCE, VPC |
| [gcp-cli-cheatsheet.md](cloud/gcp-cli-cheatsheet.md) | GCP `gcloud` – Compute, GKE, IAM |
| [hetzner-cheatsheet.md](cloud/hetzner-cheatsheet.md) | Hetzner Cloud – Servers, Networks, Firewalls, Load Balancers |
| [meshstack-cheatsheet.md](cloud/meshstack-cheatsheet.md) | MeshStack – Workspaces, Projects, Landing Zones, Chargeback |
| [ibmcloud-cheatsheet.md](cloud/ibmcloud-cheatsheet.md) | IBM Cloud CLI – IKS, ROKS, COS, ICR, IAM, Resource Groups |
| [ionos-cheatsheet.md](cloud/ionos-cheatsheet.md) | IONOS Cloud CLI `ionosctl` – Servers, Kubernetes, Networking, Load Balancer |
| [oci-cli-cheatsheet.md](cloud/oci-cli-cheatsheet.md) | OCI CLI – Compute, VCN, Object Storage, OKE, OCIR |
| [openstack-cheatsheet.md](cloud/openstack-cheatsheet.md) | OpenStack – Nova, Neutron, Cinder, Glance, Swift, Heat, Ironic |
| [stackit-cli-cheatsheet.md](cloud/stackit-cli-cheatsheet.md) | STACKIT CLI – Projects, Services |

## 🛠️ DevOps

| File | Content |
|---|---|
| [ansible-cheatsheet.md](devops/ansible-cheatsheet.md) | Ansible – Inventory, Playbooks, Roles, Vault, Templates |
| [argocd-cheatsheet.md](devops/argocd-cheatsheet.md) | ArgoCD – Apps, Sync, Projects, ApplicationSets, RBAC |
| [backstage-cheatsheet.md](devops/backstage-cheatsheet.md) | Backstage – Developer Portal, Software Catalog, Scaffolder, TechDocs |
| [cert-manager-cheatsheet.md](devops/cert-manager-cheatsheet.md) | cert-manager – TLS Certs, ACME, Let's Encrypt, ClusterIssuer, cmctl |
| [crossplane-cheatsheet.md](devops/crossplane-cheatsheet.md) | Crossplane – K8s-native IaC, Providers, Managed Resources, Compositions |
| [docker-cheatsheet.md](devops/docker-cheatsheet.md) | Docker – Images, Container, Compose, Registry |
| [external-secrets-cheatsheet.md](devops/external-secrets-cheatsheet.md) | External Secrets Operator – Vault/AWS/GCP/Azure → K8s Secrets |
| [fluxcd-cheatsheet.md](devops/fluxcd-cheatsheet.md) | FluxCD – GitOps, HelmRelease, Image Automation, Multi-Tenancy |
| [git-cheatsheet.md](devops/git-cheatsheet.md) | Git – Branches, Rebase, Stash, Tags, Hooks |
| [github-cheatsheet.md](devops/github-cheatsheet.md) | GitHub CLI `gh` – PRs, Issues, Actions, Releases |
| [gitlab-cheatsheet.md](devops/gitlab-cheatsheet.md) | GitLab CLI `glab` – MRs, CI/CD, Registry, Variables |
| [haproxy-cheatsheet.md](devops/haproxy-cheatsheet.md) | HAProxy – Frontend/Backend, ACLs, SSL, Health Checks, Stats |
| [helm-cheatsheet.md](devops/helm-cheatsheet.md) | Helm – Charts, Releases, Repos, Templates, Plugins |
| [k8s-cheatsheet.md](devops/k8s-cheatsheet.md) | Kubernetes `kubectl` – Pods, Deployments, Services, RBAC |
| [kyverno-cheatsheet.md](devops/kyverno-cheatsheet.md) | Kyverno – K8s Policy Engine, Validate, Mutate, Generate, Reports |
| [loki-cheatsheet.md](devops/loki-cheatsheet.md) | Loki – Log Aggregation, LogQL, Promtail, logcli |
| [mlflow-cheatsheet.md](devops/mlflow-cheatsheet.md) | MLflow – Experiment Tracking, Model Registry, Serving, Projects |
| [nginx-cheatsheet.md](devops/nginx-cheatsheet.md) | NGINX – Server Blocks, Reverse Proxy, Load Balancing, Ingress |
| [nvidia-ai-enterprise-cheatsheet.md](devops/nvidia-ai-enterprise-cheatsheet.md) | NVIDIA AI Enterprise – GPU Operator, NIM, Triton, MIG, DCGM |
| [openshift-cheatsheet.md](devops/openshift-cheatsheet.md) | OpenShift `oc` – Projects, Builds, Routes, SCC, OLM Operators |
| [opentelemetry-cheatsheet.md](devops/opentelemetry-cheatsheet.md) | OpenTelemetry – Traces, Metrics, Logs, OTel Collector, otelcli |
| [podman-cheatsheet.md](devops/podman-cheatsheet.md) | Podman – Rootless Containers, Pods, Systemd, Compose |
| [prometheus-grafana-cheatsheet.md](devops/prometheus-grafana-cheatsheet.md) | Prometheus & Grafana – PromQL, Alertmanager, Loki, Dashboards |
| [pulumi-cheatsheet.md](devops/pulumi-cheatsheet.md) | Pulumi – IaC with Python/TypeScript/Go, Stacks, State, Import |
| [rancher-cheatsheet.md](devops/rancher-cheatsheet.md) | Rancher – Cluster Mgmt, RKE2/K3s, Fleet GitOps, App Catalog |
| [terraform-cheatsheet.md](devops/terraform-cheatsheet.md) | Terraform / OpenTofu – IaC, State, Workspaces, Modules |
| [trivy-cheatsheet.md](devops/trivy-cheatsheet.md) | Trivy – Image Scan, IaC Scan, Secrets, SBOM, K8s Audit |
| [vault-cheatsheet.md](devops/vault-cheatsheet.md) | HashiCorp Vault – KV, PKI, Transit, Auth, Policies |
