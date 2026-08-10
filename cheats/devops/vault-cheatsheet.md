# HashiCorp Vault Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/vault

# Check version
vault version

# Shell completion
vault -autocomplete-install
exec $SHELL

# Set Vault address
export VAULT_ADDR='https://vault.beispiel.de'
export VAULT_TOKEN='hvs.mytoken'
export VAULT_NAMESPACE='admin'          # Enterprise: namespace

# Check connection
vault status

# Start Vault server locally (dev mode, for testing only!)
vault server -dev -dev-root-token-id="root"
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'
```

---

## Authentication

```bash
# Log in with token
vault login hvs.mytoken

# Log in with UserPass
vault login -method=userpass \
  username=my-user \
  password=mypassword

# With LDAP
vault login -method=ldap username=my-user

# With AppRole
vault write auth/approle/login \
  role_id=<role-id> \
  secret_id=<secret-id>

# With Kubernetes Service Account (inside a pod)
vault write auth/kubernetes/login \
  role=my-role \
  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# With AWS IAM
vault login -method=aws

# Show current token
vault token lookup

# Renew token
vault token renew

# Revoke token
vault token revoke <token>

# Create token
vault token create \
  --policy=my-policy \
  --ttl=24h \
  --display-name="ci-pipeline"

# Currently enabled auth methods
vault auth list
```

---

## KV Secrets Engine (Key-Value)

```bash
# Enable KV v2
vault secrets enable -path=secret kv-v2
# or KV v1
vault secrets enable -path=secret kv

# Write secret (KV v2)
vault kv put secret/my-app \
  db_password="geheim123" \
  api_key="abc123xyz"

# Write secret from file
vault kv put secret/my-app @secret.json

# Read secret
vault kv get secret/my-app

# Read only a specific key
vault kv get -field=db_password secret/my-app

# Output as JSON
vault kv get -format=json secret/my-app | jq '.data.data'

# Update secret (merges with existing values)
vault kv patch secret/my-app \
  new_key="new-value"

# Show all versions of a secret
vault kv metadata get secret/my-app

# Read specific version
vault kv get -version=2 secret/my-app

# Delete version (soft-delete, recoverable)
vault kv delete secret/my-app             # latest
vault kv delete -versions=1,2 secret/my-app

# Restore version
vault kv undelete -versions=1 secret/my-app

# Permanently delete (non-recoverable)
vault kv destroy -versions=1,2 secret/my-app

# Delete entire secret path (all versions)
vault kv metadata delete secret/my-app

# List all secrets under a path
vault kv list secret/
vault kv list secret/my-app/

# Load secret into environment variable
export DB_PASS=$(vault kv get -field=db_password secret/my-app)
```

---

## Manage Secrets Engines

```bash
# Show enabled engines
vault secrets list

# Enable engines
vault secrets enable -path=aws aws
vault secrets enable -path=database database
vault secrets enable -path=pki pki
vault secrets enable -path=transit transit
vault secrets enable -path=ssh ssh

# Show engine configuration
vault secrets tune -output=json secret/

# Disable engine
vault secrets disable aws/

# Rename engine path (disable & re-enable)
vault secrets disable old-path/
vault secrets enable -path=new-path kv-v2
```

---

## Database Secrets Engine

```bash
# Configure PostgreSQL plugin
vault write database/config/my-db \
  plugin_name=postgresql-database-plugin \
  allowed_roles="readonly,readwrite" \
  connection_url="postgresql://{{username}}:{{password}}@db.beispiel.de:5432/mydb?sslmode=disable" \
  username="vault-admin" \
  password="admin-password"

# Rotate database connection
vault write -force database/rotate-root/my-db

# Create role for dynamic credentials
vault write database/roles/readonly \
  db_name=my-db \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Generate dynamic credentials
vault read database/creds/readonly

# Revoke credentials (before expiry)
vault lease revoke <lease-id>

# List all leases for a role
vault list sys/leases/lookup/database/creds/readonly/
```

---

## PKI Secrets Engine (Certificates)

```bash
# Create Root CA
vault secrets enable pki
vault write pki/root/generate/internal \
  common_name="My CA" \
  ttl=87600h

# Create Intermediate CA
vault secrets enable -path=pki_int pki
vault write pki_int/intermediate/generate/internal \
  common_name="My Intermediate CA"
# Sign CSR with Root CA:
vault write pki/root/sign-intermediate csr=@pki_int.csr \
  format=pem_bundle ttl=43800h

# Set CRL/OCSP URLs
vault write pki/config/urls \
  issuing_certificates="https://vault.beispiel.de/v1/pki/ca" \
  crl_distribution_points="https://vault.beispiel.de/v1/pki/crl"

# Create role
vault write pki_int/roles/my-app \
  allowed_domains="beispiel.de" \
  allow_subdomains=true \
  max_ttl="720h"

# Issue certificate
vault write pki_int/issue/my-app \
  common_name="app.beispiel.de" \
  ttl="24h"

# Revoke certificate
vault write pki_int/revoke \
  serial_number=<serial>
```

---

## Transit Secrets Engine (Encryption-as-a-Service)

```bash
# Enable & create key
vault secrets enable transit
vault write -f transit/keys/my-key

# Set key type
vault write transit/keys/my-key \
  type=aes256-gcm96

# Encrypt data (Base64-encoded plaintext)
vault write transit/encrypt/my-key \
  plaintext=$(echo -n "Secret Text" | base64)

# Decrypt data
vault write transit/decrypt/my-key \
  ciphertext="vault:v1:abc123..."
# Decode result:
echo "base64-result" | base64 -d

# Rotate key (new encryption version)
vault write -f transit/keys/my-key/rotate

# Re-encrypt existing data
vault write transit/rewrap/my-key \
  ciphertext="vault:v1:old-ciphertext"
```

---

## Policies

```bash
# List policies
vault policy list

# Show policy
vault policy read my-policy

# Create policy
vault policy write my-policy - <<EOF
# Read access to app secrets
path "secret/data/my-app/*" {
  capabilities = ["read", "list"]
}

# Read KV metadata
path "secret/metadata/my-app/*" {
  capabilities = ["list"]
}

# Database access for role
path "database/creds/readonly" {
  capabilities = ["read"]
}

# Renew own token
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF

# Create policy from file
vault policy write my-policy policy.hcl

# Delete policy
vault policy delete my-policy

# Check capability of a policy on a path
vault token capabilities secret/data/my-app
```

---

## Configure Auth Methods

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create Kubernetes role
vault write auth/kubernetes/role/my-app \
  bound_service_account_names=my-sa \
  bound_service_account_namespaces=production \
  policies=my-policy \
  ttl=1h

# Enable AppRole auth
vault auth enable approle

# Create AppRole
vault write auth/approle/role/my-app \
  secret_id_ttl=24h \
  token_num_uses=10 \
  token_ttl=1h \
  token_max_ttl=4h \
  policies=my-policy

# Read Role ID
vault read auth/approle/role/my-app/role-id

# Generate Secret ID
vault write -f auth/approle/role/my-app/secret-id

# Enable GitHub auth
vault auth enable github
vault write auth/github/config organization=my-org
vault write auth/github/map/teams/backend value=backend-policy
```

---

## Vault Agent & Templates

```bash
# vault-agent.hcl – Configuration example
cat << 'EOF' > vault-agent.hcl
pid_file = "/tmp/vault-agent.pid"

vault {
  address = "https://vault.beispiel.de"
}

auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role = "my-app"
    }
  }
  sink "file" {
    config = {
      path = "/tmp/vault-token"
    }
  }
}

template {
  source      = "/etc/vault-templates/app.ctmpl"
  destination = "/etc/app/config.env"
  perms       = 0640
  command     = "systemctl reload my-app"
}
EOF

# Template syntax (Consul Template)
# app.ctmpl
{{ with secret "secret/data/my-app" }}
DB_HOST={{ .Data.data.db_host }}
DB_PASSWORD={{ .Data.data.db_password }}
API_KEY={{ .Data.data.api_key }}
{{ end }}

# Start Vault Agent
vault agent -config=vault-agent.hcl
```

---

## Audit & Administration

```bash
# Enable audit backends
vault audit enable file file_path=/var/log/vault/audit.log

# Audit log mode (stdout for dev)
vault audit enable file file_path=stdout

# Show enabled audit backends
vault audit list

# Vault status
vault status

# Seal status (Sealed/Unsealed)
vault status -format=json | jq '.sealed'

# Unseal Vault (after restart)
vault operator unseal <key>

# Seal Vault
vault operator seal

# Raft cluster status (integrated storage)
vault operator raft list-peers

# Create snapshot (backup)
vault operator raft snapshot save backup.snap

# Restore snapshot
vault operator raft snapshot restore backup.snap

# Lease overview
vault list sys/leases/lookup/

# Renew expiring leases
vault lease renew <lease-id>
vault lease renew -increment=2h <lease-id>

# Revoke all leases for a path
vault lease revoke -prefix database/creds/readonly/
```

---

## Vault with Kubernetes (Vault Secrets Operator)

```bash
# Install Vault Secrets Operator (via Helm)
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault-secrets-operator \
  hashicorp/vault-secrets-operator \
  -n vault-secrets-operator-system \
  --create-namespace

# Create VaultAuth
kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: static-auth
  namespace: my-namespace
spec:
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: my-app
    serviceAccount: default
EOF

# Create VaultStaticSecret
kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: app-secrets
  namespace: my-namespace
spec:
  type: kv-v2
  mount: secret
  path: my-app/config
  destination:
    name: app-secrets
    create: true
  refreshAfter: 30s
  vaultAuthRef: static-auth
EOF
```

---

## Tips & Tricks

```bash
# Set Vault environment variables securely
source <(cat << 'EOF'
export VAULT_ADDR='https://vault.beispiel.de'
export VAULT_TOKEN=$(cat ~/.vault-token)
EOF
)

# Load secret as environment variable in shell
export $(vault kv get -format=json secret/my-app | \
  jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"')

# List all paths recursively
vault kv list -format=json secret/ | jq -r '.[]'

# Filter JSON output
vault kv get -format=json secret/my-app | \
  jq '.data.data'

# Vault in CI/CD (GitHub Actions)
# Set VAULT_ADDR and VAULT_TOKEN as repository secrets
# use hashicorp/vault-action:
# uses: hashicorp/vault-action@v2
#   with:
#     url: ${{ secrets.VAULT_ADDR }}
#     token: ${{ secrets.VAULT_TOKEN }}
#     secrets: secret/data/my-app db_password | DB_PASSWORD

# Vault documentation
# https://developer.hashicorp.com/vault/docs
```
