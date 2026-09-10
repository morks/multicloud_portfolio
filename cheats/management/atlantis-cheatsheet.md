# Atlantis Cheat Sheet

## Overview

**Atlantis** is an open-source Terraform/OpenTofu pull request automation server — GitOps for infrastructure code, running plan/apply directly from PR comments.

| | |
|---|---|
| **Strengths** | Simple self-hosted setup · plan output directly in PRs · full audit trail in Git · supports Terraform, OpenTofu, Terragrunt · no SaaS dependency · integrates with GitHub/GitLab/Bitbucket |
| **Weaknesses** | No built-in UI or run history · no native RBAC beyond PR approval · single point of failure if unmanaged · stateless (no persistent dashboard) |
| **Best for** | Teams adopting GitOps for Terraform, PR-based IaC review workflows, open-source alternative to Terraform Cloud/Enterprise, small-to-medium platform teams |

---

## Installation & Setup

```bash
# ── Binary download ───────────────────────────────────────────────────────────
# https://github.com/runatlantis/atlantis/releases
curl -Lo atlantis.zip \
  "https://github.com/runatlantis/atlantis/releases/latest/download/atlantis_linux_amd64.zip"
unzip atlantis.zip && chmod +x atlantis && mv atlantis /usr/local/bin/

atlantis version

# ── Docker run ────────────────────────────────────────────────────────────────
docker run -d \
  -p 4141:4141 \
  --name atlantis \
  -e ATLANTIS_GH_USER=my-bot-user \
  -e ATLANTIS_GH_TOKEN=$GITHUB_TOKEN \
  -e ATLANTIS_GH_WEBHOOK_SECRET=$WEBHOOK_SECRET \
  -e ATLANTIS_REPO_ALLOWLIST="github.com/my-org/*" \
  ghcr.io/runatlantis/atlantis server

# ── Helm (Kubernetes) ─────────────────────────────────────────────────────────
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm repo update

helm install atlantis runatlantis/atlantis \
  --namespace atlantis --create-namespace \
  --set orgAllowlist="github.com/my-org/*" \
  --set github.user=my-bot-user \
  --set github.token=$GITHUB_TOKEN \
  --set github.secret=$WEBHOOK_SECRET \
  --set service.type=LoadBalancer

# Key environment variables
export ATLANTIS_GH_USER="my-bot-user"          # GitHub bot username
export ATLANTIS_GH_TOKEN="ghp_..."             # GitHub personal access token
export ATLANTIS_GH_WEBHOOK_SECRET="secret123"  # Webhook secret (set in GitHub)
export ATLANTIS_REPO_ALLOWLIST="github.com/my-org/*"  # allowed repos (glob)
export ATLANTIS_ATLANTIS_URL="https://atlantis.example.com"  # public URL

# GitLab equivalent env vars
export ATLANTIS_GITLAB_HOSTNAME="gitlab.example.com"
export ATLANTIS_GITLAB_TOKEN="glpat-..."
export ATLANTIS_GITLAB_WEBHOOK_SECRET="secret123"
```

---

## atlantis.yaml — Repo Config

```yaml
# Place in the root of your Terraform repo
version: 3

# ── Autoplanning ──────────────────────────────────────────────────────────────
automerge: false            # auto-merge PR after apply
parallel_plan: true         # run plan for all projects in parallel
parallel_apply: false       # apply sequentially (safer)

projects:
  # ── Simple project (single environment) ──────────────────────────────────
  - name: networking
    dir: modules/networking         # path relative to repo root
    workspace: default
    terraform_version: ~> 1.9.0    # enforced version
    autoplan:
      enabled: true
      when_modified:
        - "**/*.tf"
        - "**/*.tfvars"
    apply_requirements:
      - approved                   # PR must be approved
      - mergeable                  # PR must have no conflicts

  # ── Multi-workspace (one dir, multiple envs) ──────────────────────────────
  - name: app-dev
    dir: services/app
    workspace: dev
    autoplan:
      enabled: true
      when_modified: ["**/*.tf"]

  - name: app-prod
    dir: services/app
    workspace: prod
    apply_requirements:
      - approved
      - mergeable
      - undiverged               # branch must be up-to-date with base

# ── Custom workflow ───────────────────────────────────────────────────────────
workflows:
  custom:
    plan:
      steps:
        - init
        - run: tflint --chdir $PROJECT_DIR
        - run: trivy config --exit-code 0 $PROJECT_DIR
        - plan
    apply:
      steps:
        - apply
```

---

## PR Workflow

```bash
# Commands typed as PR comments on GitHub/GitLab/Bitbucket

atlantis plan                  # run terraform plan for all modified projects
atlantis plan -p networking    # plan only the 'networking' project
atlantis plan -d modules/networking  # plan by directory

atlantis apply                 # apply all planned projects
atlantis apply -p networking   # apply only 'networking' project

atlantis unlock                # unlock all plan locks for this PR
atlantis unlock -p networking  # unlock a specific project

atlantis import -p networking \
  aws_vpc.main vpc-abc1234     # import existing resource into state

atlantis state rm -p networking \
  aws_vpc.main                 # remove resource from state

atlantis version               # show Terraform version used

# ── PR output ────────────────────────────────────────────────────────────────
# Atlantis posts plan output as a PR comment with expandable diff
# After all projects planned: "Respond with atlantis apply to apply the plans"
# After all projects applied: "All projects applied successfully"
```

---

## Server Config

```bash
# ── Start server with flags ───────────────────────────────────────────────────
atlantis server \
  --repo-allowlist="github.com/my-org/*" \
  --gh-user=my-bot-user \
  --gh-token=$GITHUB_TOKEN \
  --gh-webhook-secret=$WEBHOOK_SECRET \
  --atlantis-url=https://atlantis.example.com \
  --port=4141 \
  --log-level=info \
  --automerge \
  --parallel-plan \
  --tf-download-url=https://releases.hashicorp.com/terraform

# ── Server YAML config (alternative to flags) ─────────────────────────────────
# atlantis.yaml at server level or via --config flag
# repos:
#   - id: github.com/my-org/my-repo
#     apply_requirements: [approved]
#     allowed_overrides: [apply_requirements, workflow]

# ── Repos config file ─────────────────────────────────────────────────────────
# repos.yaml (passed via --repo-config)
repos:
  - id: /.*/
    apply_requirements: []
    allowed_overrides: [apply_requirements, workflow]
    allow_custom_workflows: true

# ── OpenTofu support ──────────────────────────────────────────────────────────
atlantis server \
  --default-tf-version=tofu1.8.0 \
  --tf-download-url=https://github.com/opentofu/opentofu/releases/download

# ── Useful flags ──────────────────────────────────────────────────────────────
--var-file-allowlist="*.tfvars"    # allow -var-file in plan commands
--write-git-creds                  # write .git-credentials for private modules
--hide-prev-plan-comments          # minimise old plan comments
--silence-no-projects              # no comment if no projects found
--disable-apply-all                # disallow `atlantis apply` without -p flag
```

---

## Custom Workflows

```yaml
# In atlantis.yaml — extend plan/apply with extra steps
workflows:
  security-checked:
    plan:
      steps:
        - init:
            extra_args: ["-upgrade"]
        - run: tflint --chdir $PROJECT_DIR --format compact
        - run: |
            tfsec $PROJECT_DIR --soft-fail \
              --format=text --minimum-severity=HIGH
        - run: |
            conftest test $PROJECT_DIR \
              --policy ./policies/ --all-namespaces
        - plan:
            extra_args: ["-parallelism=20"]
    apply:
      steps:
        - run: echo "Applying $PROJECT_NAME in $WORKSPACE"
        - apply

# Available environment variables in run steps:
# $PROJECT_NAME       name from atlantis.yaml
# $PROJECT_DIR        absolute path to project dir
# $WORKSPACE          Terraform workspace
# $PLANFILE           path to the .tfplan file (apply only)
# $REPODIR            repo root directory
# $HEAD_COMMIT        git SHA of the PR head
# $BASE_REPO_OWNER    GitHub org/user
# $BASE_REPO_NAME     repo name
# $PULL_NUM           PR number
```

---

## Multi-Workspace & Multi-Project

```yaml
# ── Terragrunt support ────────────────────────────────────────────────────────
workflows:
  terragrunt:
    plan:
      steps:
        - run: terragrunt plan -out $PLANFILE
    apply:
      steps:
        - run: terragrunt apply $PLANFILE

# ── Multiple workspaces per directory ─────────────────────────────────────────
projects:
  - name: vpc-dev
    dir: infra/vpc
    workspace: dev
  - name: vpc-staging
    dir: infra/vpc
    workspace: staging
  - name: vpc-prod
    dir: infra/vpc
    workspace: prod
    apply_requirements: [approved, mergeable]

# ── Dynamic project detection (no atlantis.yaml in repo) ─────────────────────
# Server flag: --autoplan-modules
# Atlantis will detect changed directories automatically
atlantis server --autoplan-modules

# ── Per-project variable files ────────────────────────────────────────────────
# Comment in PR:
# atlantis plan -p vpc-prod -- -var-file=vars/prod.tfvars
```

---

## Access Control

```yaml
# ── apply_requirements per project ───────────────────────────────────────────
apply_requirements:
  - approved        # at least 1 approving review
  - mergeable       # no unresolved conflicts, required checks passed
  - undiverged      # branch is up-to-date with base branch

# ── per-repo override (repos.yaml) ───────────────────────────────────────────
repos:
  - id: github.com/my-org/critical-infra
    apply_requirements: [approved, mergeable, undiverged]
    allowed_overrides: []          # repo cannot override anything
    allow_custom_workflows: false

  - id: github.com/my-org/sandbox-.*   # regex matching
    apply_requirements: []
    allow_custom_workflows: true

# ── JSON inline config (no file needed) ──────────────────────────────────────
atlantis server \
  --repo-config-json='{"repos":[{"id":"/.*/","allow_custom_workflows":true}]}'
```

---

## Debugging

```bash
# ── Increase log verbosity ────────────────────────────────────────────────────
atlantis server --log-level=debug

# ── Check webhook delivery (GitHub UI) ───────────────────────────────────────
# Settings → Webhooks → select webhook → Recent Deliveries

# ── Atlantis health & locks ───────────────────────────────────────────────────
curl http://localhost:4141/healthz
curl http://localhost:4141/status

# List & delete locks via API
curl http://localhost:4141/atlantis/locks                    # list all locks
curl -X DELETE \
  "http://localhost:4141/atlantis/locks?id=my-org/repo/dir/default"

# ── Common issues ─────────────────────────────────────────────────────────────
# "command not allowed" → project not in repo-allowlist
# "approval required" → check apply_requirements
# "workspace is locked" → previous plan not applied; atlantis unlock to reset
# "module not found" → set --write-git-creds or configure SSH key for private modules
# Webhook 400 errors → wrong HMAC secret or payload content-type mismatch

# ── Test webhook locally (ngrok) ─────────────────────────────────────────────
atlantis server --repo-allowlist="github.com/my-org/*" \
  --atlantis-url=$(ngrok http 4141 --log=stdout | grep "Forwarding" | head -1 | awk '{print $2}')
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [runatlantis.io/docs](https://www.runatlantis.io/docs/) | Atlantis documentation — setup, atlantis.yaml reference, workflows, access control, and provider support. |
| **Atlantis GitHub** | [github.com/runatlantis/atlantis](https://github.com/runatlantis/atlantis) | Source code, releases, issue tracker, and community discussions. |
| **Helm Chart** | [github.com/runatlantis/helm-charts](https://github.com/runatlantis/helm-charts) | Official Helm chart for deploying Atlantis on Kubernetes — values reference and upgrade notes. |
| **Server Configuration** | [runatlantis.io/docs/server-configuration](https://www.runatlantis.io/docs/server-configuration.html) | Complete reference for all Atlantis server flags and environment variables. |
