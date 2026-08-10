# STACKIT CLI Cheat Sheet

## Installation & Konfiguration

```bash
# Installation (macOS via Homebrew)
brew install stackitcloud/tap/stackit

# Alternativ: Binary direkt herunterladen
# https://github.com/stackitcloud/stackit-cli/releases

# Login (öffnet Browser für SSO)
stackit auth login

# Login via Service Account Key (CI/CD)
stackit auth activate-service-account

# Aktuelle Konfiguration anzeigen
stackit config list

# Aktives Projekt setzen
stackit config set --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Aktive Organisation setzen
stackit config set --organization-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# CLI-Version anzeigen
stackit --version

# Hilfe
stackit --help
stackit <befehl> --help
```

---

## Projekte & Organisationen

```bash
# Alle Projekte auflisten
stackit project list

# Projekt erstellen
stackit project create \
  --name "Mein Projekt" \
  --parent-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Projekt-Details anzeigen
stackit project describe --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Projekt aktualisieren (umbenennen)
stackit project update \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --name "Neuer Name"

# Projekt löschen
stackit project delete --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Mitglieder eines Projekts auflisten
stackit project member list \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## SKE – STACKIT Kubernetes Engine

```bash
# Cluster auflisten
stackit ske cluster list

# Verfügbare Kubernetes-Versionen
stackit ske options kubernetes-versions

# Cluster erstellen (interaktiv)
stackit ske cluster create \
  --name mein-cluster \
  --kubernetes-version 1.30

# Cluster-Details anzeigen
stackit ske cluster describe --name mein-cluster

# kubeconfig abrufen
stackit ske kubeconfig create \
  --cluster-name mein-cluster \
  --filepath ~/.kube/config

# Cluster aktualisieren (z.B. K8s-Version)
stackit ske cluster update \
  --name mein-cluster \
  --kubernetes-version 1.31

# Cluster löschen
stackit ske cluster delete --name mein-cluster
```

---

## Server Backup Manager

```bash
# Backup-Jobs auflisten
stackit server-backup backup-job list

# Backup-Jobs eines Servers auflisten
stackit server-backup backup-job list \
  --server-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Backups auflisten
stackit server-backup backup list \
  --server-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Backup erstellen
stackit server-backup backup create \
  --server-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --backup-job-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Object Storage

```bash
# Alle Buckets auflisten
stackit object-storage bucket list

# Bucket erstellen
stackit object-storage bucket create --bucket-name mein-bucket

# Bucket-Details anzeigen
stackit object-storage bucket describe --bucket-name mein-bucket

# Bucket löschen
stackit object-storage bucket delete --bucket-name mein-bucket

# Credentials (Access Key) für Object Storage erstellen
stackit object-storage credentials-group create \
  --credentials-group-name meine-credentials

# Credentials auflisten
stackit object-storage credentials-group list

# Access Key erstellen
stackit object-storage access-key create \
  --credentials-group-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

> Hinweis: STACKIT Object Storage ist S3-kompatibel — `aws s3` CLI mit
> `--endpoint-url https://object.storage.eu01.onstackit.cloud` funktioniert ebenfalls.

---

## DNS

```bash
# DNS-Zonen auflisten
stackit dns zone list

# DNS-Zone erstellen
stackit dns zone create \
  --name "meine-domain.de" \
  --dns-name "meine-domain.de."

# DNS-Zone beschreiben
stackit dns zone describe --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# DNS Records auflisten
stackit dns record-set list \
  --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# A-Record erstellen
stackit dns record-set create \
  --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --name "www" \
  --type A \
  --records "1.2.3.4" \
  --ttl 300

# Record löschen
stackit dns record-set delete \
  --zone-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --record-set-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Load Balancer

```bash
# Load Balancer auflisten
stackit load-balancer list

# Load Balancer erstellen (via Payload-Datei)
stackit load-balancer create --payload @payload.json

# Load Balancer beschreiben
stackit load-balancer describe --name mein-lb

# Load Balancer löschen
stackit load-balancer delete --name mein-lb

# Verfügbare Optionen/Plans
stackit load-balancer options
```

---

## PostgreSQL Flex (Managed DB)

```bash
# Instanzen auflisten
stackit postgresflex instance list

# Instanz erstellen
stackit postgresflex instance create \
  --name meine-db \
  --flavor-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --version 15

# Instanz beschreiben
stackit postgresflex instance describe \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Datenbank in einer Instanz erstellen
stackit postgresflex database create \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --name mein-schema

# User erstellen
stackit postgresflex user create \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --username db-user

# Instanz löschen
stackit postgresflex instance delete \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Verfügbare Flavors (Größen) anzeigen
stackit postgresflex options flavors
```

---

## MariaDB Flex

```bash
# Instanzen auflisten
stackit mariadb instance list

# Instanz erstellen
stackit mariadb instance create \
  --name meine-mariadb \
  --flavor-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --version 10.11

# Instanz beschreiben
stackit mariadb instance describe \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Instanz löschen
stackit mariadb instance delete \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Secrets Manager

```bash
# Instanzen auflisten
stackit secrets-manager instance list

# Instanz erstellen
stackit secrets-manager instance create --name mein-vault

# User für Secrets Manager erstellen
stackit secrets-manager user create \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --description "mein service user"

# User auflisten
stackit secrets-manager user list \
  --instance-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Service Accounts & IAM

```bash
# Service Accounts auflisten
stackit service-account list

# Service Account erstellen
stackit service-account create --email mein-sa@mein-projekt.iam.stackit.cloud

# Service Account Key erstellen
stackit service-account key create \
  --service-account-email mein-sa@mein-projekt.iam.stackit.cloud

# Keys auflisten
stackit service-account key list \
  --service-account-email mein-sa@mein-projekt.iam.stackit.cloud

# Projektmitglied hinzufügen
stackit project member add \
  --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --subject mein-sa@mein-projekt.iam.stackit.cloud \
  --role editor
```

---

## Nützliche Allgemein-Optionen

```bash
# Ausgabeformat: pretty (Standard), json, yaml
stackit ske cluster list --output-format json
stackit project list --output-format yaml

# Projekt-ID global für eine Session überschreiben
stackit ske cluster list --project-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Async-Operationen (nicht auf Abschluss warten)
stackit ske cluster create --name mein-cluster --async

# Konfigurationsdatei anzeigen
cat ~/.stackit/config.json

# Konfiguration zurücksetzen
stackit config unset --project-id
stackit config unset --organization-id

# Autocomplete installieren (bash/zsh)
stackit completion bash >> ~/.bashrc
stackit completion zsh >> ~/.zshrc
```
