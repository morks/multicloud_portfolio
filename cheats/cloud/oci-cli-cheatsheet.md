# OCI CLI Cheat Sheet (Oracle Cloud Infrastructure)

## Installation & Konfiguration

```bash
# Installation (macOS via Homebrew)
brew install oci-cli

# Installation (offizieller Installer)
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Version prüfen
oci --version

# Setup-Assistent (interaktiv, legt ~/.oci/config an)
oci setup config

# Config-Datei manuell prüfen
cat ~/.oci/config

# Konfigurationsprofil auflisten
oci setup repair-file-permissions --file ~/.oci/config

# API-Key-Fingerprint anzeigen
oci iam user list-api-keys --user-id <user-ocid>

# Aktuelle Identität prüfen
oci iam user get --user-id $(oci iam user list --query 'data[0].id' --raw-output)
```

---

## Profile & Tenancies

```bash
# Standard-Profil nutzen (DEFAULT in ~/.oci/config)
oci iam compartment list

# Alternatives Profil nutzen
oci iam compartment list --profile PROD

# Tenancy-OCID anzeigen
oci iam tenancy get --tenancy-id <tenancy-ocid>

# Alle Regionen anzeigen
oci iam region list

# Abonnierte Regionen der Tenancy
oci iam region-subscription list --tenancy-id <tenancy-ocid>

# Region für eine Session setzen
export OCI_CLI_REGION=eu-frankfurt-1
```

---

## IAM – Compartments & Policies

```bash
# Alle Compartments auflisten (root)
oci iam compartment list --all

# Compartment erstellen
oci iam compartment create \
  --compartment-id <parent-ocid> \
  --name "mein-compartment" \
  --description "Beschreibung"

# Groups auflisten
oci iam group list --all

# User einer Gruppe hinzufügen
oci iam group add-user \
  --group-id <group-ocid> \
  --user-id <user-ocid>

# Policies auflisten
oci iam policy list --compartment-id <compartment-ocid>

# Policy erstellen
oci iam policy create \
  --compartment-id <compartment-ocid> \
  --name "meine-policy" \
  --description "Zugriff auf Object Storage" \
  --statements '["Allow group Admins to manage object-family in compartment MeinCompartment"]'
```

---

## Compute – Instanzen

```bash
# Instanzen auflisten
oci compute instance list \
  --compartment-id <compartment-ocid> \
  --output table

# Instanz-Details anzeigen
oci compute instance get --instance-id <instance-ocid>

# Instanz starten
oci compute instance action \
  --instance-id <instance-ocid> \
  --action START

# Instanz stoppen
oci compute instance action \
  --instance-id <instance-ocid> \
  --action STOP

# Instanz neu starten
oci compute instance action \
  --instance-id <instance-ocid> \
  --action SOFTRESET

# Instanz terminieren
oci compute instance terminate \
  --instance-id <instance-ocid>

# Verfügbare Shapes auflisten
oci compute shape list --compartment-id <compartment-ocid>

# Images auflisten (Oracle-Images)
oci compute image list \
  --compartment-id <compartment-ocid> \
  --operating-system "Oracle Linux" \
  --output table

# SSH-Verbindung via bastion (Instance Console Connection)
oci compute instance-console-connection create \
  --instance-id <instance-ocid> \
  --public-key-file ~/.ssh/id_rsa.pub
```

---

## VCN – Virtual Cloud Network

```bash
# VCNs auflisten
oci network vcn list --compartment-id <compartment-ocid>

# VCN erstellen
oci network vcn create \
  --compartment-id <compartment-ocid> \
  --cidr-block "10.0.0.0/16" \
  --display-name "mein-vcn"

# Subnets auflisten
oci network subnet list --compartment-id <compartment-ocid>

# Subnet erstellen
oci network subnet create \
  --compartment-id <compartment-ocid> \
  --vcn-id <vcn-ocid> \
  --cidr-block "10.0.1.0/24" \
  --display-name "public-subnet"

# Security Lists anzeigen
oci network security-list list --compartment-id <compartment-ocid>

# Internet Gateway erstellen
oci network internet-gateway create \
  --compartment-id <compartment-ocid> \
  --vcn-id <vcn-ocid> \
  --is-enabled true \
  --display-name "mein-igw"

# Load Balancer auflisten
oci lb load-balancer list --compartment-id <compartment-ocid>
```

---

## Object Storage

```bash
# Buckets auflisten
oci os bucket list --compartment-id <compartment-ocid>

# Bucket erstellen
oci os bucket create \
  --compartment-id <compartment-ocid> \
  --name "mein-bucket" \
  --namespace <namespace>

# Namespace anzeigen
oci os ns get

# Objekte auflisten
oci os object list --bucket-name "mein-bucket"

# Datei hochladen
oci os object put \
  --bucket-name "mein-bucket" \
  --file ./lokale-datei.txt \
  --name "pfad/im/bucket/datei.txt"

# Datei herunterladen
oci os object get \
  --bucket-name "mein-bucket" \
  --name "pfad/im/bucket/datei.txt" \
  --file ./heruntergeladen.txt

# Objekt löschen
oci os object delete \
  --bucket-name "mein-bucket" \
  --name "pfad/im/bucket/datei.txt"

# Bulk-Upload eines Verzeichnisses
oci os object bulk-upload \
  --bucket-name "mein-bucket" \
  --src-dir ./mein-verzeichnis/

# Pre-Authenticated Request (PAR) erstellen
oci os preauth-request create \
  --bucket-name "mein-bucket" \
  --name "mein-par" \
  --access-type ObjectRead \
  --time-expires "2026-12-31T23:59:59Z"
```

---

## Database – Autonomous Database (ADB)

```bash
# Autonomous Databases auflisten
oci db autonomous-database list --compartment-id <compartment-ocid>

# ADB erstellen (ATP)
oci db autonomous-database create \
  --compartment-id <compartment-ocid> \
  --db-name "MYATP" \
  --display-name "Meine ATP" \
  --cpu-core-count 1 \
  --data-storage-size-in-tbs 1 \
  --admin-password "SecurePass#123" \
  --db-workload ATP

# ADB starten
oci db autonomous-database start --autonomous-database-id <adb-ocid>

# ADB stoppen
oci db autonomous-database stop --autonomous-database-id <adb-ocid>

# Wallet herunterladen (für Verbindung)
oci db autonomous-database generate-wallet \
  --autonomous-database-id <adb-ocid> \
  --password "WalletPass#1" \
  --file wallet.zip
```

---

## Container Engine (OKE – Kubernetes)

```bash
# Cluster auflisten
oci ce cluster list --compartment-id <compartment-ocid>

# Cluster erstellen
oci ce cluster create \
  --compartment-id <compartment-ocid> \
  --name "mein-oke-cluster" \
  --vcn-id <vcn-ocid> \
  --kubernetes-version "v1.29.1"

# kubeconfig für OKE-Cluster laden
oci ce cluster create-kubeconfig \
  --cluster-id <cluster-ocid> \
  --file ~/.kube/config \
  --region eu-frankfurt-1 \
  --token-version 2.0.0

# Node Pools auflisten
oci ce node-pool list --compartment-id <compartment-ocid>

# Node Pool erstellen
oci ce node-pool create \
  --cluster-id <cluster-ocid> \
  --compartment-id <compartment-ocid> \
  --name "worker-pool" \
  --node-shape "VM.Standard.E4.Flex" \
  --kubernetes-version "v1.29.1"
```

---

## Container Registry (OCIR)

```bash
# Repositories auflisten
oci artifacts container repository list --compartment-id <compartment-ocid>

# Docker-Login bei OCIR
docker login <region-key>.ocir.io \
  -u "<tenancy-namespace>/<username>" \
  -p "<auth-token>"

# Image taggen für OCIR
docker tag mein-image:1.0 \
  fra.ocir.io/<namespace>/mein-repo/mein-image:1.0

# Image pushen
docker push fra.ocir.io/<namespace>/mein-repo/mein-image:1.0

# Auth-Token erstellen (für Registry-Login)
oci iam auth-token create \
  --user-id <user-ocid> \
  --description "OCIR Token"
```

---

## Resource Manager (Terraform)

```bash
# Stacks auflisten
oci resource-manager stack list --compartment-id <compartment-ocid>

# Stack aus ZIP erstellen
oci resource-manager stack create \
  --compartment-id <compartment-ocid> \
  --display-name "mein-stack" \
  --config-source config-source='{"configSourceType":"ZIP_UPLOAD","zipFileBase64Encoded":"'$(base64 terraform.zip)'"}'

# Plan ausführen
oci resource-manager job create-plan-job \
  --stack-id <stack-ocid>

# Apply ausführen
oci resource-manager job create-apply-job \
  --stack-id <stack-ocid> \
  --execution-plan-strategy FROM_LATEST_JOB_OUTPUTS

# Job-Log anzeigen
oci resource-manager job get-job-logs --job-id <job-ocid>
```

---

## Tipps & Tricks

```bash
# Output als JSON (Standard)
oci iam compartment list --output json

# Output als Tabelle
oci iam compartment list --output table

# JMESPath-Query auf Ausgabe anwenden
oci compute instance list \
  --compartment-id <compartment-ocid> \
  --query 'data[*].{"Name":"display-name","State":"lifecycle-state"}' \
  --output table

# Nur bestimmten Wert ausgeben (raw)
oci iam compartment list \
  --query 'data[?name==`MeinCompartment`].id | [0]' \
  --raw-output

# Debug-Logging aktivieren
oci --debug iam compartment list ...

# CLI-Konfiguration erweitern (~/.oci/oci_cli_rc)
echo "[OCI_CLI_SETTINGS]
default_profile=DEFAULT" >> ~/.oci/oci_cli_rc

# Automatische Paginierung bei großen Ergebnislisten
oci iam compartment list --all
```
