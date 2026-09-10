# External Secrets Operator (ESO) Cheat Sheet

## Overview

**External Secrets Operator (ESO)** is a Kubernetes operator that synchronizes secrets from external stores (Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault) into native K8s Secrets.

| | |
|---|---|
| **Strengths** | 20+ provider backends · unified API for all secret stores · templating for output secrets · ClusterSecretStore for cross-namespace use · PushSecret for reverse sync · no secrets in Git |
| **Weaknesses** | Adds operational complexity · debugging sync failures requires understanding both the operator and the backend · secret rotation needs careful planning · refresh interval tuning matters |
| **Best for** | Centralized secret management with Vault/cloud KMS, eliminating secrets-in-Git, enterprise secret governance across K8s namespaces |

---

## Installation & Setup

```bash
# Add ESO Helm repo
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install External Secrets Operator
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace

# Verify CRDs were installed
kubectl get crds | grep external-secrets.io

# Verify operator pod is running
kubectl get pods -n external-secrets

# Check ESO version
kubectl -n external-secrets get deploy external-secrets \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## SecretStore & ClusterSecretStore

```bash
# SecretStore  – namespace-scoped, can only be referenced within same namespace
# ClusterSecretStore – cluster-scoped, can be referenced from any namespace

# HashiCorp Vault – ClusterSecretStore
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"          # KV mount path
      version: "v2"           # v1 or v2
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
EOF

# AWS Secrets Manager – ClusterSecretStore
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-central-1
      auth:
        jwt:                    # IRSA (IAM Roles for Service Accounts)
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
EOF

# GCP Secret Manager – ClusterSecretStore
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: gcp-secret-manager
spec:
  provider:
    gcpsm:
      projectID: "my-gcp-project"
      auth:
        workloadIdentity:
          clusterLocation: europe-west3
          clusterName: my-cluster
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
EOF

# Azure Key Vault – ClusterSecretStore
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: azure-keyvault
spec:
  provider:
    azurekv:
      url: "https://my-keyvault.vault.azure.net"
      authType: WorkloadIdentity
      serviceAccountRef:
        name: external-secrets
        namespace: external-secrets
EOF

# Check SecretStore status (VALID = ready)
kubectl get clustersecretstore
kubectl describe clustersecretstore vault-backend
```

---

## ExternalSecret Resource

```bash
# Basic ExternalSecret – fetch specific keys from Vault
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
  namespace: my-namespace
spec:
  refreshInterval: 1h           # how often to sync
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: my-app-secret         # name of the K8s Secret to create
    creationPolicy: Owner       # Owner | Merge | Orphan
  data:
    - secretKey: db-password    # key in the K8s Secret
      remoteRef:
        key: secret/my-app      # path in Vault
        property: db_password   # field within the secret
    - secretKey: api-key
      remoteRef:
        key: secret/my-app
        property: api_key
EOF

# Check sync status
kubectl get externalsecret my-app-secrets -n my-namespace
kubectl describe externalsecret my-app-secrets -n my-namespace

# Verify the K8s Secret was created
kubectl get secret my-app-secret -n my-namespace
kubectl get secret my-app-secret -n my-namespace -o jsonpath='{.data}' | \
  jq 'to_entries[] | {key: .key, value: (.value | @base64d)}'
```

---

## Common Patterns

```bash
# Bulk sync – fetch ALL keys from a Vault path (dataFrom)
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-bulk
  namespace: my-namespace
spec:
  refreshInterval: 30m
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: my-app-secret-bulk
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: secret/my-app    # fetches all key/value pairs at this path
EOF

# Template the output Secret (rename keys, add prefix, base64 encode)
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-templated
  namespace: my-namespace
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: my-app-secret-templated
    creationPolicy: Owner
    template:
      type: kubernetes.io/dockerconfigjson    # create a docker registry secret
      data:
        .dockerconfigjson: |
          {"auths":{"registry.example.com":{"username":"{{ .username }}","password":"{{ .password }}"}}}
  data:
    - secretKey: username
      remoteRef:
        key: secret/registry
        property: username
    - secretKey: password
      remoteRef:
        key: secret/registry
        property: password
EOF

# Force immediate refresh (delete and let ESO recreate)
kubectl annotate externalsecret my-app-secrets -n my-namespace \
  force-sync=$(date +%s) --overwrite
```

---

## PushSecret

```bash
# Push a K8s Secret to an external store (reverse of ExternalSecret)
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1alpha1
kind: PushSecret
metadata:
  name: push-my-cert
  namespace: my-namespace
spec:
  refreshInterval: 10m
  secretStoreRefs:
    - name: vault-backend
      kind: ClusterSecretStore
  selector:
    secret:
      name: my-tls-secret       # existing K8s Secret to push
  data:
    - match:
        secretKey: tls.crt       # key in K8s Secret
        remoteRef:
          remoteKey: secret/my-app/tls   # destination path in Vault
          property: tls_crt
    - match:
        secretKey: tls.key
        remoteRef:
          remoteKey: secret/my-app/tls
          property: tls_key
EOF

# Check PushSecret status
kubectl get pushsecret -n my-namespace
kubectl describe pushsecret push-my-cert -n my-namespace
```

---

## Debugging

```bash
# Check ExternalSecret sync status and last sync time
kubectl get externalsecret -A
kubectl get externalsecret my-app-secrets -n my-namespace \
  -o jsonpath='{.status.conditions}'

# Describe for detailed events and error messages
kubectl describe externalsecret my-app-secrets -n my-namespace

# Check operator logs for errors
kubectl logs -n external-secrets \
  -l app.kubernetes.io/name=external-secrets -f

# Common errors:
# "could not find provider" → SecretStore name/kind is wrong
# "401 Unauthorized"        → wrong credentials or expired token
# "SecretStore not ready"   → describe the SecretStore, check auth config
# "Secret not found"        → wrong remoteRef key/property path

# Validate that a ClusterSecretStore is healthy
kubectl get clustersecretstore vault-backend \
  -o jsonpath='{.status.conditions[0].message}'
```

---

## Multiple Namespaces

```bash
# ClusterSecretStore can be referenced from any namespace
# ExternalSecret in namespace A → ClusterSecretStore (cluster-scoped) = works
# ExternalSecret in namespace A → SecretStore in namespace B = NOT allowed

# Restrict ClusterSecretStore to specific namespaces via conditions
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: restricted-vault
spec:
  conditions:
    - namespaceSelector:
        matchLabels:
          eso-access: "true"   # only namespaces with this label can use this store
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "restricted-role"
EOF

# Label a namespace to grant access
kubectl label namespace my-namespace eso-access=true

# List all ExternalSecrets across all namespaces
kubectl get externalsecret -A

# Watch sync status across all namespaces
watch kubectl get externalsecret -A
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [external-secrets.io/latest](https://external-secrets.io/latest/) | External Secrets Operator documentation — providers, API reference, installation, and best practices. |
| **ESO GitHub** | [github.com/external-secrets/external-secrets](https://github.com/external-secrets/external-secrets) | Source code, releases, issue tracker, and community contributions. |
| **Supported Providers** | [external-secrets.io/latest/provider](https://external-secrets.io/latest/provider/aws-secrets-manager/) | Full list of supported secret backends — Vault, AWS, GCP, Azure, 1Password, Doppler, and more. |
| **Terraform Provider (ESO)** | [registry.terraform.io/external-secrets-inc/external-secrets](https://registry.terraform.io/providers/external-secrets-inc/external-secrets/latest/docs) | Official ESO Terraform provider — manage ExternalSecret and SecretStore resources as infrastructure code. |
