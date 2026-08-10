# AWS CLI Cheat Sheet

## Installation & Konfiguration

```bash
# Installation (macOS)
brew install awscli

# Konfigurieren (Access Key, Secret, Region, Output-Format)
aws configure

# Standard-Ausgabeformat dauerhaft auf Tabelle setzen (~/.aws/config)
aws configure set output table

# Nur für ein bestimmtes Profil
aws configure set output table --profile mein-profil

# Alternativ: Session-weit per Umgebungsvariable
export AWS_DEFAULT_OUTPUT=table

# Konfigurieren mit Named Profile
aws configure --profile mein-profil

# Aktuelles Profil anzeigen
aws configure list

# SSO Login (für Accenture Landing Zone)
aws sso login --profile mein-profil

# Aktuelle Identität prüfen
aws sts get-caller-identity
```

---

## IAM – Identity & Access Management

```bash
# Alle IAM-User auflisten
aws iam list-users

# IAM-User erstellen
aws iam create-user --user-name max-mustermann

# Access Key für User erstellen
aws iam create-access-key --user-name max-mustermann

# Gruppen eines Users anzeigen
aws iam list-groups-for-user --user-name max-mustermann

# Aktuelle Rollen (Policies) des eigenen Accounts prüfen
aws iam list-attached-user-policies --user-name max-mustermann

# Rolle annehmen (AssumeRole)
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/MeineRolle \
  --role-session-name meine-session
```

---

## EC2 – Virtuelle Maschinen

```bash
# Alle Instanzen auflisten (mit Name-Tag und Status)
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],State.Name,InstanceId]' \
  --output table

# Instanz starten
aws ec2 start-instances --instance-ids i-0abc123def456

# Instanz stoppen
aws ec2 stop-instances --instance-ids i-0abc123def456

# Instanz beenden (terminieren)
aws ec2 terminate-instances --instance-ids i-0abc123def456

# Neue Instanz starten
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name mein-key \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678

# Instanz via EC2 Instance Connect verbinden
aws ec2-instance-connect send-ssh-public-key \
  --instance-id i-0abc123def456 \
  --instance-os-user ec2-user \
  --ssh-public-key file://~/.ssh/id_rsa.pub

# Security Groups auflisten
aws ec2 describe-security-groups --output table

# Key Pairs auflisten
aws ec2 describe-key-pairs
```

---

## S3 – Object Storage

```bash
# Alle Buckets auflisten
aws s3 ls

# Inhalt eines Buckets anzeigen
aws s3 ls s3://mein-bucket/

# Datei hochladen
aws s3 cp meine-datei.txt s3://mein-bucket/pfad/

# Datei herunterladen
aws s3 cp s3://mein-bucket/pfad/meine-datei.txt ./

# Ordner synchronisieren (lokal → S3)
aws s3 sync ./lokaler-ordner s3://mein-bucket/ziel/

# Datei/Ordner löschen
aws s3 rm s3://mein-bucket/pfad/meine-datei.txt

# Bucket erstellen
aws s3 mb s3://neuer-bucket --region eu-central-1

# Bucket-Größe anzeigen
aws s3 ls s3://mein-bucket --recursive --human-readable --summarize
```

---

## VPC – Netzwerk

```bash
# Alle VPCs auflisten
aws ec2 describe-vpcs --output table

# Subnets einer VPC auflisten
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-12345678" \
  --output table

# Security Group Regeln anzeigen
aws ec2 describe-security-groups \
  --group-ids sg-12345678

# Internet Gateway auflisten
aws ec2 describe-internet-gateways
```

---

## RDS – Managed Datenbanken

```bash
# Alle DB-Instanzen auflisten
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]' \
  --output table

# DB-Instanz starten / stoppen
aws rds start-db-instance --db-instance-identifier meine-db
aws rds stop-db-instance --db-instance-identifier meine-db

# Snapshot erstellen
aws rds create-db-snapshot \
  --db-instance-identifier meine-db \
  --db-snapshot-identifier mein-snapshot
```

---

## EKS – Kubernetes

```bash
# Cluster auflisten
aws eks list-clusters

# kubeconfig für Cluster setzen
aws eks update-kubeconfig \
  --name mein-cluster \
  --region eu-central-1

# Nodegroups eines Clusters auflisten
aws eks list-nodegroups --cluster-name mein-cluster
```

---

## CloudFormation / Terraform

```bash
# Stacks auflisten
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Stack-Events (Fehlerdiagnose)
aws cloudformation describe-stack-events \
  --stack-name mein-stack

# Stack löschen
aws cloudformation delete-stack --stack-name mein-stack
```

---

## Nützliche Allgemein-Optionen

```bash
# Ausgabe als JSON (Standard)
aws ec2 describe-instances --output json

# Ausgabe als Tabelle
aws ec2 describe-instances --output table

# Ausgabe als Text (für Skripte)
aws ec2 describe-instances --output text

# JMESPath Query – nur bestimmte Felder
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId'

# Mit spezifischem Profil ausführen
aws s3 ls --profile mein-profil

# Mit spezifischer Region ausführen
aws ec2 describe-instances --region us-east-1

# Dry Run – Befehl testen ohne Ausführung
aws ec2 run-instances --dry-run ...

# Debug-Ausgabe aktivieren
aws ec2 describe-instances --debug
```

---

## Häufige Filter-Muster

```bash
# Instanzen nach Tag filtern
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production"

# Nur laufende Instanzen
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running"

# Ressourcen nach Name-Tag suchen
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mein-server*"
```
