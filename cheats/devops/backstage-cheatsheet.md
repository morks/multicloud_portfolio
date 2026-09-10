# Backstage Cheat Sheet

## Installation & Setup

```bash
# Create a new Backstage app (interactive)
npx @backstage/create-app@latest

# Project structure overview
# my-backstage-app/
# ├── app-config.yaml          # Main configuration
# ├── app-config.production.yaml
# ├── packages/
# │   ├── app/                 # Frontend (React)
# │   └── backend/             # Backend (Node.js)
# └── plugins/                 # Custom plugins

# Install dependencies
yarn install

# Start in development mode (hot reload)
yarn dev

# Build for production
yarn build

# Run backend only
yarn workspace backend start

# Run frontend only
yarn workspace app start

# Check Backstage version
yarn backstage-cli versions:check

# Bump all Backstage packages to latest
yarn backstage-cli versions:bump
```

---

## catalog-info.yaml — Entity Kinds

```bash
# --- Component (service, website, library, etc.) ---
# catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  description: My backend service
  annotations:
    github.com/project-slug: org/my-service         # GitHub integration
    backstage.io/techdocs-ref: dir:.                # TechDocs location
  tags:
    - java
    - backend
spec:
  type: service          # service | website | library | documentation
  lifecycle: production  # experimental | production | deprecated
  owner: team-platform
  system: my-system
  dependsOn:
    - component:my-database

# --- API ---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: my-api
spec:
  type: openapi          # openapi | asyncapi | grpc | graphql
  lifecycle: production
  owner: team-platform
  definition: |
    openapi: "3.0.0"
    ...

# --- System (group of components) ---
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: my-system
spec:
  owner: team-platform
  domain: my-domain

# --- Domain (high-level business domain) ---
apiVersion: backstage.io/v1alpha1
kind: Domain
metadata:
  name: my-domain
spec:
  owner: engineering

# --- Resource (database, S3 bucket, etc.) ---
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: my-database
spec:
  type: database
  owner: team-platform
  system: my-system

# --- Group (team or organizational unit) ---
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: team-platform
spec:
  type: team
  profile:
    displayName: Platform Team
  parent: engineering
  children: []
  members:
    - user:default/john.doe

# --- User ---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: john.doe
spec:
  profile:
    displayName: John Doe
    email: john.doe@example.com
  memberOf:
    - team-platform
```

---

## Software Templates (Scaffolder)

```bash
# Template file: template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: create-service
  title: Create a new microservice
  description: Scaffolds a new service repository
spec:
  owner: team-platform
  type: service

  parameters:                          # Form fields shown in Backstage UI
    - title: Service Details
      required: [name, owner]
      properties:
        name:
          title: Service Name
          type: string
        owner:
          title: Owner
          type: string
          ui:field: OwnerPicker

  steps:
    - id: fetch                        # Step 1: fetch template files
      name: Fetch template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}

    - id: publish                      # Step 2: create GitHub repo
      name: Publish to GitHub
      action: publish:github
      input:
        repoUrl: github.com?repo=${{ parameters.name }}&owner=my-org

    - id: register                     # Step 3: register in catalog
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}

# Run template from CLI (dry run)
# Navigate to Backstage UI → Create → select template → fill form → review → create
```

---

## TechDocs

```bash
# Enable TechDocs for a component — add to catalog-info.yaml:
metadata:
  annotations:
    backstage.io/techdocs-ref: dir:.       # docs/ folder in same repo
    # or:
    backstage.io/techdocs-ref: url:https://github.com/org/repo/tree/main

# mkdocs.yml (minimal, required at repo root)
site_name: My Service Docs
docs_dir: docs
nav:
  - Home: index.md
  - API: api.md

# Install techdocs-cli
npm install -g @techdocs/cli

# Local preview (serves at http://localhost:3000)
techdocs-cli serve

# Generate static docs
techdocs-cli generate --source-dir . --output-dir ./site

# Publish docs to storage (e.g., S3)
techdocs-cli publish \
  --publisher-type awsS3 \
  --storage-name my-techdocs-bucket \
  --entity default/component/my-service

# app-config.yaml — TechDocs config
techdocs:
  builder: external         # or 'local' for dev
  generator:
    runIn: local
  publisher:
    type: awsS3
    awsS3:
      bucketName: my-techdocs-bucket
      region: eu-central-1
```

---

## Plugins

```bash
# Add a plugin package to the frontend
yarn workspace app add @backstage/plugin-kubernetes

# Add a plugin package to the backend
yarn workspace backend add @backstage/plugin-kubernetes-backend

# Register a frontend plugin in packages/app/src/App.tsx
# import { KubernetesPage } from '@backstage/plugin-kubernetes';
# <Route path="/kubernetes" element={<KubernetesPage />} />

# Register in the sidebar (packages/app/src/components/Root/Root.tsx)
# import KubernetesIcon from '@material-ui/icons/Memory';
# <SidebarItem icon={KubernetesIcon} to="kubernetes" text="Kubernetes" />

# Commonly used plugins:
# @backstage/plugin-kubernetes             Kubernetes resource viewer
# @backstage/plugin-github-actions         GitHub Actions workflow status
# @backstage/plugin-pagerduty             PagerDuty on-call & incidents
# @backstage/plugin-cost-insights         Cloud cost monitoring
# @backstage/plugin-techdocs             TechDocs viewer
# @roadiehq/backstage-plugin-argo-cd      ArgoCD integration
# @backstage/plugin-scaffolder            Software templates (Scaffolder)
# @backstage/plugin-search                Global search

# List installed plugins
yarn workspaces list
```

---

## backstage-cli

```bash
# Build the entire repo
yarn backstage-cli repo build

# Build a single package
yarn workspace app backstage-cli package build
yarn workspace backend backstage-cli package build

# Lint the repo
yarn backstage-cli repo lint

# Run tests
yarn backstage-cli repo test

# Export config schema (for validation)
yarn backstage-cli config:schema --output schema.json

# Check for outdated Backstage packages
yarn backstage-cli versions:check

# Bump all @backstage/* packages
yarn backstage-cli versions:bump

# Create a new plugin scaffold
yarn backstage-cli new --select plugin
yarn backstage-cli new --select backend-plugin

# Generate API report
yarn backstage-cli package api-extractor run
```

---

## Configuration (app-config.yaml)

```bash
# app-config.yaml — key sections

app:
  title: My Developer Portal
  baseUrl: http://localhost:3000

backend:
  baseUrl: http://localhost:7007
  listen:
    port: 7007
  database:
    client: pg                         # or 'better-sqlite3' for dev
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}

# --- Auth Providers ---
auth:
  providers:
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
    microsoft:
      development:
        clientId: ${AUTH_MICROSOFT_CLIENT_ID}
        clientSecret: ${AUTH_MICROSOFT_CLIENT_SECRET}
        tenantId: ${AUTH_MICROSOFT_TENANT_ID}

# --- GitHub Integration ---
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
  gitlab:
    - host: gitlab.com
      token: ${GITLAB_TOKEN}
  azure:
    - host: dev.azure.com
      credentials:
        - personalAccessToken: ${AZURE_TOKEN}

# --- Catalog Locations ---
catalog:
  rules:
    - allow: [Component, API, System, Domain, Resource, Group, User, Template]
  locations:
    - type: url
      target: https://github.com/org/repo/blob/main/catalog-info.yaml
    - type: url
      target: https://github.com/org/*/blob/main/catalog-info.yaml  # wildcard
    - type: file
      target: ../../catalog/*.yaml                                   # local dev

# --- Kubernetes Plugin ---
kubernetes:
  serviceLocatorMethod:
    type: multiTenant
  clusterLocatorMethods:
    - type: config
      clusters:
        - url: ${K8S_URL}
          name: my-cluster
          authProvider: serviceAccount
          serviceAccountToken: ${K8S_SA_TOKEN}
```

---

## Deployment

```bash
# Build Docker image (from repo root)
docker build -t backstage:latest .

# Run with Docker
docker run -p 7007:7007 \
  -e POSTGRES_HOST=db \
  -e POSTGRES_USER=backstage \
  -e POSTGRES_PASSWORD=secret \
  -e GITHUB_TOKEN=ghp_xxx \
  backstage:latest

# Add Helm repo
helm repo add backstage https://backstage.github.io/charts
helm repo update

# Install via Helm
helm install backstage backstage/backstage \
  --namespace backstage \
  --create-namespace \
  --values values.yaml

# Minimal values.yaml for Helm
# backstage:
#   image:
#     repository: my-registry/backstage
#     tag: latest
#   appConfig:
#     app:
#       baseUrl: https://backstage.example.com
#     backend:
#       baseUrl: https://backstage.example.com

# Kubernetes deployment — check pods
kubectl get pods -n backstage
kubectl logs -n backstage -l app.kubernetes.io/name=backstage -f

# Scale deployment
kubectl scale deployment backstage -n backstage --replicas=2
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [backstage.io/docs](https://backstage.io/docs/) | Backstage documentation — architecture, plugins, deployment, and software catalog guides. |
| **Backstage GitHub** | [github.com/backstage/backstage](https://github.com/backstage/backstage) | Source code, issues, plugin development, and community contributions. |
| **Plugin Marketplace** | [backstage.io/plugins](https://backstage.io/plugins) | Browse community and official plugins for Backstage integrations. |
| **Helm Chart** | [github.com/backstage/charts](https://github.com/backstage/charts) | Official Helm chart for deploying Backstage on Kubernetes. |
