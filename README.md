# 🌐 Multi-Cloud Admin Portfolio

> **Deine Schnellreferenz für Cloud-Architekturen & DevOps-Tooling**  
> Praxiserprobte CLI-Befehle, Workflows und Cheat Sheets für Multi-Cloud-Admins.

---

## 🗺️ Übersicht

Dieses Repository ist eine kuratierte Sammlung von Cheat Sheets und Referenzen für Admins und Architekten, die täglich mit mehreren Cloud-Plattformen und modernen DevOps-Tools arbeiten. Kein Noise, keine Theory – nur die Befehle, die wirklich gebraucht werden.

---

## ☁️ Cloud Platforms

| Provider | CLI | Schwerpunkte |
|---|---|---|
| [AWS](cheats/cloud/aws-cli-cheatsheet.md) | `aws` | EC2, S3, IAM, SSO, Profile, STS |
| [Azure](cheats/cloud/azure-cli-cheatsheet.md) | `az` | Ressourcen, AKS, Storage, RBAC |
| [Google Cloud](cheats/cloud/gcp-cli-cheatsheet.md) | `gcloud` | Compute, GKE, IAM, Artifact Registry |
| [Oracle Cloud (OCI)](cheats/cloud/oci-cli-cheatsheet.md) | `oci` | Compute, VCN, Object Storage, OKE, OCIR |
| [Telekom Cloud (OTC)](cheats/cloud/ctc-cheatsheet.md) | `openstack` / `otc` | ECS, VPC, OBS, CCE, DNS, EVS |
| [STACKIT](cheats/cloud/stackit-cli-cheatsheet.md) | `stackit` | Projekte, Services, Kubernetes |

---

## 🛠️ DevOps Tools

| Tool | Cheat Sheet | Schwerpunkte |
|---|---|---|
| **Kubernetes** | [kubectl](cheats/devops/k8s-cheatsheet.md) | Pods, Deployments, Services, RBAC, Debugging |
| **Helm** | [helm](cheats/devops/helm-cheatsheet.md) | Charts, Releases, Repos, Templates, Plugins |
| **ArgoCD** | [argocd](cheats/devops/argocd-cheatsheet.md) | GitOps, Apps, Sync, Projects, ApplicationSets |
| **Vault** | [vault](cheats/devops/vault-cheatsheet.md) | KV, PKI, Transit, Auth Methods, Policies |
| **Ansible** | [ansible](cheats/devops/ansible-cheatsheet.md) | Inventory, Playbooks, Roles, Templates, Galaxy |
| **Docker** | [docker](cheats/devops/docker-cheatsheet.md) | Images, Container, Compose, Registry |
| **Git** | [git](cheats/devops/git-cheatsheet.md) | Branches, Rebase, Stash, Tags, Hooks |
| **GitHub CLI** | [gh](cheats/devops/github-cheatsheet.md) | PRs, Issues, Actions, Releases |
| **GitLab CLI** | [glab](cheats/devops/gitlab-cheatsheet.md) | MRs, CI/CD, Registry, Variablen |

---

## 🚀 Quickstart: Cheat Sheets direkt nutzen

### Cloud-Zugang einrichten

```bash
# AWS – SSO Login
aws sso login --profile mein-profil
aws sts get-caller-identity

# Azure – Interaktiver Login
az login
az account set --subscription "Mein Abo"

# GCP – Application Default Credentials
gcloud auth login
gcloud config set project mein-projekt

# OCI – Konfigurationsassistent
oci setup config

# Telekom Cloud (OTC) – RC-Datei sourcen
source ~/Downloads/MeinProjekt-openrc.sh
openstack token issue

# STACKIT – Login
stackit auth login
```

### Kubernetes – Cluster wechseln und prüfen

```bash
# Kontexte anzeigen und wechseln
kubectl config get-contexts
kubectl config use-context mein-cluster

# oder interaktiv mit kubectx
kubectx

# Schnell-Check
kubectl get nodes -o wide
kubectl get pods -A | grep -v Running
```

### GitOps – ArgoCD App deployen

```bash
# Login
argocd login argocd.beispiel.de --username admin

# App anlegen mit Auto-Sync
argocd app create meine-app \
  --repo https://github.com/org/repo.git \
  --path helm/meine-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace produktion \
  --sync-policy automated \
  --auto-prune --self-heal

# Status prüfen
argocd app get meine-app
```

### Secrets aus Vault lesen

```bash
export VAULT_ADDR='https://vault.beispiel.de'
vault login                                  # interaktiv
vault kv get secret/meine-app               # Secret lesen
vault kv get -field=db_password secret/meine-app | pbcopy  # direkt in Clipboard
```

---

## 📂 Repository-Struktur

```
multicloud_portfolio/
│
├── README.md                          # Diese Datei
│
└── cheats/                            # Alle Cheat Sheets
    ├── README.md                      # Cheat-Sheet-Index
    │
    ├── cloud/                         # Cloud-Provider CLIs
    │   ├── aws-cli-cheatsheet.md      # Amazon Web Services
    │   ├── azure-cli-cheatsheet.md    # Microsoft Azure
    │   ├── ctc-cheatsheet.md          # Telekom Cloud (OTC/OpenStack)
    │   ├── gcp-cli-cheatsheet.md      # Google Cloud Platform
    │   ├── oci-cli-cheatsheet.md      # Oracle Cloud Infrastructure
    │   └── stackit-cli-cheatsheet.md  # STACKIT (Deutsche Telekom)
    │
    └── devops/                        # DevOps-Tooling
        ├── ansible-cheatsheet.md      # Ansible Automatisierung
        ├── argocd-cheatsheet.md       # ArgoCD GitOps
        ├── docker-cheatsheet.md       # Docker / Container
        ├── git-cheatsheet.md          # Git Versionskontrolle
        ├── github-cheatsheet.md       # GitHub CLI (gh)
        ├── gitlab-cheatsheet.md       # GitLab CLI (glab)
        ├── helm-cheatsheet.md         # Helm Package Manager
        ├── k8s-cheatsheet.md          # Kubernetes (kubectl)
        └── vault-cheatsheet.md        # HashiCorp Vault
```

---

## 💡 Verwendete Tools & Installation

### Cloud CLIs

```bash
# alle auf einmal (macOS via Homebrew)
brew install awscli azure-cli google-cloud-sdk oci-cli
brew install openstack-client          # OTC/Telekom Cloud

# STACKIT CLI
brew install stackit
```

### DevOps Tools

```bash
brew install kubectl helm argocd vault ansible
brew install kubectx k9s stern        # Kubernetes-Extras
brew install docker                   # oder Docker Desktop
```

---

## 🤝 Beitragen

Ergänzungen, Korrekturen und neue Cheat Sheets sind willkommen!

1. Fork des Repositories
2. Branch anlegen: `git checkout -b feat/neues-cheatsheet`
3. Cheat Sheet im passenden Ordner anlegen (`cheats/cloud/` oder `cheats/devops/`)
4. Pull Request erstellen

**Format-Konvention:** Jedes Cheat Sheet folgt dem Muster:
- Abschnitte mit `## Überschrift`
- Code immer in ` ```bash ` Blöcken
- Kommentare auf Deutsch (`# Was macht dieser Befehl`)
- Keine langen Erklärungen – nur das Wesentliche

---

## 📜 Lizenz

MIT License – frei verwendbar, Nennung erwünscht.

---

<div align="center">

**Maintained by Multi-Cloud Admins, for Multi-Cloud Admins** 🚀

*Gefunden, was du gesucht hast? Dann gib dem Repo einen ⭐*

</div>
