# Google Cloud CLI (gcloud) Cheat Sheet

## Installation & Konfiguration

```bash
# Installation (macOS)
brew install --cask google-cloud-sdk

# Login (öffnet Browser)
gcloud auth login

# Application Default Credentials (für SDKs/Terraform)
gcloud auth application-default login

# Aktuelles Konto anzeigen
gcloud auth list

# Konto wechseln
gcloud config set account mein@email.com

# Aktives Projekt anzeigen
gcloud config get-value project

# Projekt wechseln
gcloud config set project mein-projekt-id

# Alle Konfigurationen anzeigen
gcloud config list

# Neue Konfiguration erstellen (Named Profile)
gcloud config configurations create mein-profil

# Konfiguration aktivieren
gcloud config configurations activate mein-profil

# CLI-Version anzeigen
gcloud version

# Komponenten aktualisieren
gcloud components update
```

---

## Projekte

```bash
# Alle Projekte auflisten
gcloud projects list

# Projekt erstellen
gcloud projects create mein-neues-projekt \
  --name "Mein Projekt" \
  --organization ORG_ID

# Projekt-Details anzeigen
gcloud projects describe mein-projekt-id

# Projekt löschen
gcloud projects delete mein-projekt-id

# Billing-Konto verknüpfen
gcloud billing projects link mein-projekt-id \
  --billing-account 0X0X0X-0X0X0X-0X0X0X
```

---

## Compute Engine – Virtuelle Maschinen

```bash
# Alle VM-Instanzen auflisten
gcloud compute instances list

# VM erstellen
gcloud compute instances create meine-vm \
  --zone europe-west3-a \
  --machine-type e2-micro \
  --image-family debian-12 \
  --image-project debian-cloud \
  --boot-disk-size 20GB

# VM starten / stoppen / löschen
gcloud compute instances start meine-vm --zone europe-west3-a
gcloud compute instances stop meine-vm --zone europe-west3-a
gcloud compute instances delete meine-vm --zone europe-west3-a

# Per SSH verbinden
gcloud compute ssh meine-vm --zone europe-west3-a

# SSH via IAP-Tunnel (ohne öffentliche IP)
gcloud compute ssh meine-vm \
  --zone europe-west3-a \
  --tunnel-through-iap

# Serielle Konsole anzeigen (Debugging)
gcloud compute instances get-serial-port-output meine-vm \
  --zone europe-west3-a

# Snapshot einer Disk erstellen
gcloud compute disks snapshot meine-disk \
  --zone europe-west3-a \
  --snapshot-names mein-snapshot
```

---

## Netzwerk – VPC, Firewall

```bash
# VPC-Netzwerke auflisten
gcloud compute networks list

# VPC erstellen
gcloud compute networks create mein-netzwerk \
  --subnet-mode custom

# Subnetz erstellen
gcloud compute networks subnets create mein-subnet \
  --network mein-netzwerk \
  --region europe-west3 \
  --range 10.0.1.0/24

# Firewall-Regeln auflisten
gcloud compute firewall-rules list

# Firewall-Regel erstellen (HTTPS eingehend)
gcloud compute firewall-rules create allow-https \
  --network mein-netzwerk \
  --allow tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow HTTPS inbound"

# Firewall-Regel löschen
gcloud compute firewall-rules delete allow-https

# Externe IP-Adressen auflisten
gcloud compute addresses list
```

---

## Cloud Storage (GCS)

```bash
# Alle Buckets auflisten
gcloud storage buckets list

# Bucket erstellen
gcloud storage buckets create gs://mein-bucket \
  --location europe-west3 \
  --uniform-bucket-level-access

# Dateien auflisten
gcloud storage ls gs://mein-bucket/

# Datei hochladen
gcloud storage cp meine-datei.txt gs://mein-bucket/

# Datei herunterladen
gcloud storage cp gs://mein-bucket/meine-datei.txt ./

# Ordner synchronisieren
gcloud storage rsync -r ./lokaler-ordner gs://mein-bucket/ziel/

# Datei/Ordner löschen
gcloud storage rm gs://mein-bucket/meine-datei.txt

# Bucket-Größe anzeigen
gcloud storage du -s gs://mein-bucket/

# Bucket löschen (muss leer sein)
gcloud storage buckets delete gs://mein-bucket
```

---

## GKE – Google Kubernetes Engine

```bash
# Cluster auflisten
gcloud container clusters list

# Cluster erstellen
gcloud container clusters create mein-cluster \
  --zone europe-west3-a \
  --num-nodes 2 \
  --machine-type e2-standard-2

# kubeconfig abrufen
gcloud container clusters get-credentials mein-cluster \
  --zone europe-west3-a

# Cluster skalieren
gcloud container clusters resize mein-cluster \
  --zone europe-west3-a \
  --num-nodes 3

# Cluster upgraden
gcloud container clusters upgrade mein-cluster \
  --zone europe-west3-a

# Cluster löschen
gcloud container clusters delete mein-cluster --zone europe-west3-a
```

---

## Cloud SQL – Managed Datenbanken

```bash
# Instanzen auflisten
gcloud sql instances list

# Instanz erstellen (PostgreSQL)
gcloud sql instances create meine-db \
  --database-version POSTGRES_15 \
  --tier db-f1-micro \
  --region europe-west3

# Instanz starten / stoppen
gcloud sql instances patch meine-db --activation-policy ALWAYS
gcloud sql instances patch meine-db --activation-policy NEVER

# Datenbank erstellen
gcloud sql databases create mein-schema --instance meine-db

# Backup erstellen
gcloud sql backups create --instance meine-db

# Mit Instanz verbinden
gcloud sql connect meine-db --user postgres
```

---

## IAM – Berechtigungen

```bash
# Aktuelle IAM-Policy eines Projekts anzeigen
gcloud projects get-iam-policy mein-projekt-id

# Rolle einem Nutzer zuweisen
gcloud projects add-iam-policy-binding mein-projekt-id \
  --member="user:max@example.com" \
  --role="roles/compute.admin"

# Rolle entfernen
gcloud projects remove-iam-policy-binding mein-projekt-id \
  --member="user:max@example.com" \
  --role="roles/compute.admin"

# Service Account erstellen
gcloud iam service-accounts create mein-sa \
  --display-name "Mein Service Account"

# Service Account Key erstellen (JSON)
gcloud iam service-accounts keys create key.json \
  --iam-account mein-sa@mein-projekt-id.iam.gserviceaccount.com

# Alle Service Accounts auflisten
gcloud iam service-accounts list
```

---

## Cloud Run – Serverless Container

```bash
# Services auflisten
gcloud run services list

# Container deployen
gcloud run deploy mein-service \
  --image gcr.io/mein-projekt/mein-image:latest \
  --region europe-west3 \
  --platform managed \
  --allow-unauthenticated

# Service-URL abrufen
gcloud run services describe mein-service \
  --region europe-west3 \
  --format 'value(status.url)'

# Service löschen
gcloud run services delete mein-service --region europe-west3
```

---

## Nützliche Allgemein-Optionen

```bash
# Ausgabeformat: json, yaml, text, table, value
gcloud compute instances list --format=table
gcloud compute instances list --format=json
gcloud compute instances list --format="value(name,zone)"

# Filter
gcloud compute instances list --filter="status=RUNNING"
gcloud compute instances list --filter="zone:europe-west3-a"

# Standardzone/-region setzen
gcloud config set compute/zone europe-west3-a
gcloud config set compute/region europe-west3

# Alle verfügbaren Regionen/Zonen
gcloud compute regions list
gcloud compute zones list

# API aktivieren (z.B. Compute Engine)
gcloud services enable compute.googleapis.com

# Aktivierte APIs anzeigen
gcloud services list --enabled

# Logs anzeigen
gcloud logging read "resource.type=gce_instance" --limit 50

# Hilfe zu einem Befehl
gcloud compute instances create --help
```
