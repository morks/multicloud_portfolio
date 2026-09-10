# Crossplane Cheat Sheet

## Overview

**Crossplane** is a Kubernetes-native control plane for infrastructure provisioning — manage cloud resources as Kubernetes custom resources using GitOps workflows.

| | |
|---|---|
| **Strengths** | K8s-native (no separate state file) · GitOps compatible · powerful abstraction via Compositions · self-service infrastructure APIs via Claims · CNCF project · growing provider ecosystem |
| **Weaknesses** | Complex composition model · steep learning curve · slower reconciliation than Terraform · debugging Compositions is hard · requires a running K8s cluster |
| **Best for** | Platform engineering teams building internal cloud platforms, K8s-native IaC, self-service infrastructure APIs, teams already running K8s wanting no separate IaC toolchain |

---

## Installation & Setup

```bash
# Add Crossplane Helm repo
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane into its own namespace
helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace

# Verify Crossplane pods are running
kubectl get pods -n crossplane-system

# Check installed CRDs
kubectl get crds | grep crossplane

# Install up CLI (Upbound CLI)
brew install upbound/tap/up

# Verify up CLI version
up version
```

---

## Providers

```bash
# Install AWS provider
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1
EOF

# Install Azure provider
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure-storage
spec:
  package: xpkg.upbound.io/upbound/provider-azure-storage:v1
EOF

# Install GCP provider
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-gcp-storage
spec:
  package: xpkg.upbound.io/upbound/provider-gcp-storage:v1
EOF

# Check provider installation status
kubectl get providers
kubectl get providerrevisions

# Wait for provider to become healthy
kubectl wait provider/provider-aws-s3 --for=condition=Healthy --timeout=180s

# Create ProviderConfig for AWS (using secret)
cat <<EOF | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: creds
EOF

# Create the AWS credentials secret
kubectl create secret generic aws-creds \
  -n crossplane-system \
  --from-file=creds=~/.aws/credentials
```

---

## Managed Resources

```bash
# Example: S3 Bucket as a Crossplane Managed Resource
cat <<EOF | kubectl apply -f -
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-crossplane-bucket
  annotations:
    crossplane.io/external-name: my-crossplane-bucket-unique-name
spec:
  forProvider:
    region: eu-central-1
  providerConfigRef:
    name: default
EOF

# Example: RDS PostgreSQL Instance
cat <<EOF | kubectl apply -f -
apiVersion: rds.aws.upbound.io/v1beta1
kind: Instance
metadata:
  name: my-postgres
spec:
  forProvider:
    region: eu-central-1
    instanceClass: db.t3.micro
    engine: postgres
    engineVersion: "15"
    username: adminuser
    skipFinalSnapshot: true
    allocatedStorage: 20
    dbName: mydb
    passwordSecretRef:
      namespace: default
      name: db-secret
      key: password
  providerConfigRef:
    name: default
EOF

# List all managed resources across all providers
kubectl get managed

# Show managed resource details (incl. sync status)
kubectl describe bucket my-crossplane-bucket

# Check if resource is synced and ready
kubectl get bucket my-crossplane-bucket \
  -o jsonpath='{.status.conditions[*].type}: {.status.conditions[*].status}'

# Delete a managed resource (also deletes external resource)
kubectl delete bucket my-crossplane-bucket

# Orphan a resource on deletion (keep external, remove MR only)
kubectl annotate bucket my-crossplane-bucket \
  crossplane.io/paused=true
kubectl patch bucket my-crossplane-bucket \
  --type merge -p '{"spec":{"deletionPolicy":"Orphan"}}'
kubectl delete bucket my-crossplane-bucket
```

---

## Composite Resources (XR)

```bash
# CompositeResourceDefinition (XRD) — defines a new API type
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xpostgresqlinstances.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: XPostgreSQLInstance
    plural: xpostgresqlinstances
  claimNames:
    kind: PostgreSQLInstance
    plural: postgresqlinstances
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                parameters:
                  type: object
                  properties:
                    storageGB:
                      type: integer
                  required:
                    - storageGB
              required:
                - parameters
EOF

# Composition — maps XR → Managed Resources
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: xpostgresqlinstances.aws.platform.example.com
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XPostgreSQLInstance
  resources:
    - name: rdsinstance
      base:
        apiVersion: rds.aws.upbound.io/v1beta1
        kind: Instance
        spec:
          forProvider:
            region: eu-central-1
            instanceClass: db.t3.micro
            engine: postgres
            skipFinalSnapshot: true
      patches:
        - fromFieldPath: spec.parameters.storageGB
          toFieldPath: spec.forProvider.allocatedStorage
EOF

# Claim (XRC) — used by application teams
cat <<EOF | kubectl apply -f -
apiVersion: platform.example.com/v1alpha1
kind: PostgreSQLInstance
metadata:
  name: my-db
  namespace: team-a
spec:
  parameters:
    storageGB: 20
  compositionRef:
    name: xpostgresqlinstances.aws.platform.example.com
  writeConnectionSecretToRef:
    name: my-db-conn
EOF

# List Composite Resources and Claims
kubectl get composite
kubectl get claim --all-namespaces
kubectl get postgresqlinstances -A

# Check composition status
kubectl get xpostgresqlinstances
```

---

## up CLI (Upbound)

```bash
# Login to Upbound Cloud
up login

# List organizations
up organization list

# Create a Control Plane
up controlplane create my-controlplane \
  --configuration-name platform-ref-aws

# List control planes
up controlplane list

# Connect kubectl to a control plane
up controlplane kubeconfig get my-controlplane \
  --namespace my-org

# Build and push a Configuration package
up project build

# Push to Upbound Marketplace
up project push

# Install a Configuration from Upbound Marketplace
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: platform-ref-aws
spec:
  package: xpkg.upbound.io/upbound/platform-ref-aws:v0.9.0
EOF

# Check Configuration status
kubectl get configurations
kubectl get configurationrevisions
```

---

## Common Workflows

```bash
# Import existing external resource into Crossplane management
# 1. Create the MR manifest with the correct external-name annotation
kubectl apply -f - <<EOF
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: existing-bucket
  annotations:
    crossplane.io/external-name: my-already-existing-bucket
spec:
  forProvider:
    region: eu-central-1
  providerConfigRef:
    name: default
EOF
# Crossplane will adopt the existing resource instead of creating a new one

# Pause reconciliation on a managed resource
kubectl annotate managed/my-crossplane-bucket crossplane.io/paused=true

# Resume reconciliation
kubectl annotate managed/my-crossplane-bucket crossplane.io/paused-

# Patch & Transform — convert field in Composition
# fromFieldPath + transforms (math, map, string, convert)
# Example: multiply storageGB by 1024 for MB
# patches:
#   - fromFieldPath: spec.parameters.storageGB
#     toFieldPath: spec.forProvider.allocatedStorageMB
#     transforms:
#       - type: math
#         math:
#           multiply: 1024

# Readiness check in a Composition resource
# readinessChecks:
#   - type: MatchString
#     fieldPath: status.atProvider.bucketVersioning
#     matchString: Enabled
```

---

## Debugging

```bash
# Show all Composite Resources (all namespaces)
kubectl get composite -A

# Show all Claims (all namespaces)
kubectl get claim -A

# Describe a specific Composition to check for errors
kubectl describe composition xpostgresqlinstances.aws.platform.example.com

# Check events on a managed resource
kubectl describe bucket my-crossplane-bucket | grep -A 20 Events

# Show resource tree (requires crossplane CLI plugin or up)
kubectl get managed | grep -v SYNCED

# crossplane trace — show the full resource tree for a claim
crossplane beta trace postgresqlinstance my-db -n team-a

# Show controller logs for debugging
kubectl logs -n crossplane-system \
  -l app=crossplane \
  --tail=50 -f

# Show provider controller logs
kubectl logs -n crossplane-system \
  -l pkg.crossplane.io/revision=provider-aws-s3 \
  --tail=50 -f

# Check if a resource is stuck (common: missing ProviderConfig)
kubectl get managed -o wide | grep -v True

# Crossplane events
kubectl get events -n crossplane-system --sort-by='.lastTimestamp'
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [docs.crossplane.io](https://docs.crossplane.io/) | Crossplane documentation — concepts, providers, compositions, CLI, and platform engineering guides. |
| **Upbound Marketplace** | [marketplace.upbound.io](https://marketplace.upbound.io/) | Provider and Configuration packages — browse official and community Crossplane providers for all major clouds. |
| **Crossplane GitHub** | [github.com/crossplane/crossplane](https://github.com/crossplane/crossplane) | Crossplane source code, releases, roadmap, and community discussions. |
| **Upbound Docs** | [docs.upbound.io](https://docs.upbound.io/) | Upbound managed control planes, Spaces, and enterprise Crossplane documentation. |
