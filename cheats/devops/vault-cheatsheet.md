# HashiCorp Vault Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/vault

# Version prüfen
vault version

# Shell-Completion
vault -autocomplete-install
exec $SHELL

# Vault-Adresse setzen
export VAULT_ADDR='https://vault.beispiel.de'
export VAULT_TOKEN='hvs.meintoken'
export VAULT_NAMESPACE='admin'          # Enterprise: Namespace

# Verbindung prüfen
vault status

# Vault-Server lokal starten (Dev-Modus, nur für Tests!)
vault server -dev -dev-root-token-id="root"
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'
```

---

## Authentifizierung

```bash
# Mit Token einloggen
vault login hvs.meintoken

# Mit UserPass einloggen
vault login -method=userpass \
  username=mein-user \
  password=meinpasswort

# Mit LDAP
vault login -method=ldap username=mein-user

# Mit AppRole
vault write auth/approle/login \
  role_id=<role-id> \
  secret_id=<secret-id>

# Mit Kubernetes Service Account (innerhalb eines Pods)
vault write auth/kubernetes/login \
  role=meine-rolle \
  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Mit AWS IAM
vault login -method=aws

# Aktuelles Token anzeigen
vault token lookup

# Token verlängern
vault token renew

# Token widerrufen
vault token revoke <token>

# Token erstellen
vault token create \
  --policy=meine-policy \
  --ttl=24h \
  --display-name="ci-pipeline"

# Aktuell eingeloggte Auth-Methoden
vault auth list
```

---

## KV Secrets Engine (Key-Value)

```bash
# KV v2 aktivieren
vault secrets enable -path=secret kv-v2
# oder KV v1
vault secrets enable -path=secret kv

# Secret schreiben (KV v2)
vault kv put secret/meine-app \
  db_password="geheim123" \
  api_key="abc123xyz"

# Secret aus Datei schreiben
vault kv put secret/meine-app @secret.json

# Secret lesen
vault kv get secret/meine-app

# Nur einen bestimmten Key auslesen
vault kv get -field=db_password secret/meine-app

# Als JSON ausgeben
vault kv get -format=json secret/meine-app | jq '.data.data'

# Secret aktualisieren (mergt mit bestehenden Werten)
vault kv patch secret/meine-app \
  new_key="neuer-wert"

# Alle Versionen eines Secrets anzeigen
vault kv metadata get secret/meine-app

# Bestimmte Version lesen
vault kv get -version=2 secret/meine-app

# Version löschen (Soft-Delete, wiederherstellbar)
vault kv delete secret/meine-app             # aktuellste
vault kv delete -versions=1,2 secret/meine-app

# Version wiederherstellen
vault kv undelete -versions=1 secret/meine-app

# Permanent löschen (nicht wiederherstellbar)
vault kv destroy -versions=1,2 secret/meine-app

# Secret-Pfad komplett löschen (alle Versionen)
vault kv metadata delete secret/meine-app

# Alle Secrets unter einem Pfad auflisten
vault kv list secret/
vault kv list secret/meine-app/

# Secret in Umgebungsvariable laden
export DB_PASS=$(vault kv get -field=db_password secret/meine-app)
```

---

## Secrets Engines verwalten

```bash
# Aktivierte Engines anzeigen
vault secrets list

# Engines aktivieren
vault secrets enable -path=aws aws
vault secrets enable -path=database database
vault secrets enable -path=pki pki
vault secrets enable -path=transit transit
vault secrets enable -path=ssh ssh

# Engine-Konfiguration anzeigen
vault secrets tune -output=json secret/

# Engine deaktivieren
vault secrets disable aws/

# Engine-Pfad umbenennen (deaktivieren & neu aktivieren)
vault secrets disable old-path/
vault secrets enable -path=new-path kv-v2
```

---

## Database Secrets Engine

```bash
# PostgreSQL-Plugin konfigurieren
vault write database/config/meine-db \
  plugin_name=postgresql-database-plugin \
  allowed_roles="readonly,readwrite" \
  connection_url="postgresql://{{username}}:{{password}}@db.beispiel.de:5432/mydb?sslmode=disable" \
  username="vault-admin" \
  password="admin-passwort"

# Datenbankverbindung rotieren
vault write -force database/rotate-root/meine-db

# Rolle für dynamische Credentials erstellen
vault write database/roles/readonly \
  db_name=meine-db \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Dynamische Credentials generieren
vault read database/creds/readonly

# Credentials widerrufen (vor Ablauf)
vault lease revoke <lease-id>

# Alle Leases einer Rolle anzeigen
vault list sys/leases/lookup/database/creds/readonly/
```

---

## PKI Secrets Engine (Zertifikate)

```bash
# Root-CA erstellen
vault secrets enable pki
vault write pki/root/generate/internal \
  common_name="Meine CA" \
  ttl=87600h

# Intermediate CA erstellen
vault secrets enable -path=pki_int pki
vault write pki_int/intermediate/generate/internal \
  common_name="Meine Intermediate CA"
# CSR signieren mit Root-CA:
vault write pki/root/sign-intermediate csr=@pki_int.csr \
  format=pem_bundle ttl=43800h

# CRL/OCSP-URLs setzen
vault write pki/config/urls \
  issuing_certificates="https://vault.beispiel.de/v1/pki/ca" \
  crl_distribution_points="https://vault.beispiel.de/v1/pki/crl"

# Rolle erstellen
vault write pki_int/roles/meine-app \
  allowed_domains="beispiel.de" \
  allow_subdomains=true \
  max_ttl="720h"

# Zertifikat ausstellen
vault write pki_int/issue/meine-app \
  common_name="app.beispiel.de" \
  ttl="24h"

# Zertifikat widerrufen
vault write pki_int/revoke \
  serial_number=<serial>
```

---

## Transit Secrets Engine (Encryption-as-a-Service)

```bash
# Aktivieren & Schlüssel erstellen
vault secrets enable transit
vault write -f transit/keys/mein-schluessel

# Schlüsseltyp festlegen
vault write transit/keys/mein-schluessel \
  type=aes256-gcm96

# Daten verschlüsseln (Base64-kodierter Plaintext)
vault write transit/encrypt/mein-schluessel \
  plaintext=$(echo -n "Geheimer Text" | base64)

# Daten entschlüsseln
vault write transit/decrypt/mein-schluessel \
  ciphertext="vault:v1:abc123..."
# Ergebnis decodieren:
echo "base64-ergebnis" | base64 -d

# Schlüssel rotieren (neue Verschlüsselungsversion)
vault write -f transit/keys/mein-schluessel/rotate

# Bestehende Daten re-encrypten
vault write transit/rewrap/mein-schluessel \
  ciphertext="vault:v1:alter-ciphertext"
```

---

## Policies

```bash
# Policies auflisten
vault policy list

# Policy anzeigen
vault policy read meine-policy

# Policy erstellen
vault policy write meine-policy - <<EOF
# Lesezugriff auf App-Secrets
path "secret/data/meine-app/*" {
  capabilities = ["read", "list"]
}

# KV-Metadata lesen
path "secret/metadata/meine-app/*" {
  capabilities = ["list"]
}

# Datenbankzugriff für Rolle
path "database/creds/readonly" {
  capabilities = ["read"]
}

# Eigenes Token verlängern
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF

# Policy aus Datei erstellen
vault policy write meine-policy policy.hcl

# Policy löschen
vault policy delete meine-policy

# Capability einer Policy auf einem Pfad prüfen
vault token capabilities secret/data/meine-app
```

---

## Auth Methods konfigurieren

```bash
# Kubernetes-Auth aktivieren
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Kubernetes-Rolle erstellen
vault write auth/kubernetes/role/meine-app \
  bound_service_account_names=mein-sa \
  bound_service_account_namespaces=production \
  policies=meine-policy \
  ttl=1h

# AppRole-Auth aktivieren
vault auth enable approle

# AppRole erstellen
vault write auth/approle/role/meine-app \
  secret_id_ttl=24h \
  token_num_uses=10 \
  token_ttl=1h \
  token_max_ttl=4h \
  policies=meine-policy

# Role ID auslesen
vault read auth/approle/role/meine-app/role-id

# Secret ID generieren
vault write -f auth/approle/role/meine-app/secret-id

# GitHub-Auth aktivieren
vault auth enable github
vault write auth/github/config organization=mein-org
vault write auth/github/map/teams/backend value=backend-policy
```

---

## Vault Agent & Templates

```bash
# vault-agent.hcl – Konfigurationsbeispiel
cat << 'EOF' > vault-agent.hcl
pid_file = "/tmp/vault-agent.pid"

vault {
  address = "https://vault.beispiel.de"
}

auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role = "meine-app"
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
  command     = "systemctl reload meine-app"
}
EOF

# Template-Syntax (Consul Template)
# app.ctmpl
{{ with secret "secret/data/meine-app" }}
DB_HOST={{ .Data.data.db_host }}
DB_PASSWORD={{ .Data.data.db_password }}
API_KEY={{ .Data.data.api_key }}
{{ end }}

# Vault Agent starten
vault agent -config=vault-agent.hcl
```

---

## Audit & Administration

```bash
# Audit-Backends aktivieren
vault audit enable file file_path=/var/log/vault/audit.log

# Audit-Log-Modus (stdout für dev)
vault audit enable file file_path=stdout

# Aktivierte Audit-Backends anzeigen
vault audit list

# Vault-Status
vault status

# Versiegelungsstatus (Sealed/Unsealed)
vault status -format=json | jq '.sealed'

# Vault entsiegeln (nach Neustart)
vault operator unseal <schluessel>

# Vault versiegeln
vault operator seal

# Raft-Cluster-Status (integrierter Storage)
vault operator raft list-peers

# Snapshot erstellen (Backup)
vault operator raft snapshot save backup.snap

# Snapshot wiederherstellen
vault operator raft snapshot restore backup.snap

# Lease-Übersicht
vault list sys/leases/lookup/

# Ablaufende Leases erneuern
vault lease renew <lease-id>
vault lease renew -increment=2h <lease-id>

# Alle Leases eines Pfades widerrufen
vault lease revoke -prefix database/creds/readonly/
```

---

## Vault mit Kubernetes (Vault Secrets Operator)

```bash
# Vault Secrets Operator installieren (via Helm)
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault-secrets-operator \
  hashicorp/vault-secrets-operator \
  -n vault-secrets-operator-system \
  --create-namespace

# VaultAuth erstellen
kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: static-auth
  namespace: mein-namespace
spec:
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: meine-app
    serviceAccount: default
EOF

# VaultStaticSecret erstellen
kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: app-secrets
  namespace: mein-namespace
spec:
  type: kv-v2
  mount: secret
  path: meine-app/config
  destination:
    name: app-secrets
    create: true
  refreshAfter: 30s
  vaultAuthRef: static-auth
EOF
```

---

## Tipps & Tricks

```bash
# Vault-Umgebungsvariablen sicher setzen
source <(cat << 'EOF'
export VAULT_ADDR='https://vault.beispiel.de'
export VAULT_TOKEN=$(cat ~/.vault-token)
EOF
)

# Secret als Env-Variable in Shell laden
export $(vault kv get -format=json secret/meine-app | \
  jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"')

# Alle Pfade rekursiv auflisten
vault kv list -format=json secret/ | jq -r '.[]'

# JSON-Ausgabe filtern
vault kv get -format=json secret/meine-app | \
  jq '.data.data'

# Vault in CI/CD (GitHub Actions)
# VAULT_ADDR und VAULT_TOKEN als Repository-Secrets setzen
# hashicorp/vault-action nutzen:
# uses: hashicorp/vault-action@v2
#   with:
#     url: ${{ secrets.VAULT_ADDR }}
#     token: ${{ secrets.VAULT_TOKEN }}
#     secrets: secret/data/meine-app db_password | DB_PASSWORD

# Vault-Dokumentation
# https://developer.hashicorp.com/vault/docs
```
