# CTC Cheat Sheet (Telekom Cloud / Open Telekom Cloud)

> Die Open Telekom Cloud (OTC) basiert auf OpenStack. CLI-Tools: `otc` (eigener Client) sowie die OpenStack-Standard-CLIs `openstack`, `swift`, `nova`, `neutron` usw.

## Installation & Konfiguration

```bash
# otc-cli installieren (Go-Binary)
brew install iits-consulting/tap/otc-cli

# Alternativ via GitHub-Releases
curl -Lo otc https://github.com/iits-consulting/otc-cli/releases/latest/download/otc-linux-amd64
chmod +x otc && sudo mv otc /usr/local/bin/

# OpenStack-Client (Standard-Tools)
pip install python-openstackclient

# Version prüfen
otc --version
openstack --version

# Konfigurationsassistent (interaktiv)
otc configure

# Konfiguration anzeigen
otc configure show

# openstack rc-Datei sourcen (aus OTC-Konsole heruntergeladen)
source ~/Downloads/MeinProjekt-openrc.sh

# Umgebungsvariablen direkt setzen
export OS_AUTH_URL=https://iam.eu-de.otc.t-systems.com/v3
export OS_PROJECT_NAME=eu-de_<projektname>
export OS_USER_DOMAIN_NAME=OTC-EU-DE-<domainid>
export OS_USERNAME=<username>
export OS_PASSWORD=<password>
export OS_REGION_NAME=eu-de
```

---

## Authentifizierung & Projekte

```bash
# Token anfordern (Prüfung ob Auth funktioniert)
openstack token issue

# Aktuelles Projekt anzeigen
openstack project show $OS_PROJECT_NAME

# Alle Projekte auflisten
openstack project list

# Domänen auflisten
openstack domain list

# Benutzer auflisten (Adminrechte nötig)
openstack user list

# Eigene Rollen prüfen
openstack role assignment list --user $OS_USERNAME --names

# Token-Ablauf und Details
openstack token issue -f json | jq '.expires'
```

---

## Compute – ECS (Elastic Cloud Server)

```bash
# Instanzen auflisten
openstack server list
otc ecs list

# Instanzdetails anzeigen
openstack server show <server-name-oder-id>

# Instanz erstellen
openstack server create \
  --image "Standard_Debian_12_latest" \
  --flavor s3.medium.4 \
  --network <network-name> \
  --key-name mein-keypair \
  --security-group default \
  mein-server

# Instanz starten / stoppen / neu starten
openstack server start <server-id>
openstack server stop <server-id>
openstack server reboot <server-id>

# Instanz löschen
openstack server delete <server-id>

# SSH-Key erstellen
openstack keypair create mein-keypair > mein-keypair.pem
chmod 400 mein-keypair.pem

# SSH-Key importieren
openstack keypair create --public-key ~/.ssh/id_rsa.pub mein-keypair

# Keypairs auflisten
openstack keypair list

# Verfügbare Flavors (VM-Typen)
openstack flavor list --public

# Verfügbare Images
openstack image list --status active
```

---

## Netzwerk – VPC & Neutron

```bash
# VPCs / Netzwerke auflisten
openstack network list
otc vpc list

# VPC erstellen
otc vpc create --name mein-vpc --cidr 10.0.0.0/16

# Subnets auflisten
openstack subnet list

# Subnet erstellen
openstack subnet create \
  --network <network-name> \
  --subnet-range 10.0.1.0/24 \
  --gateway 10.0.1.1 \
  --dns-nameserver 100.125.4.25 \
  mein-subnet

# Floating IP zuweisen
openstack floating ip create admin_external_net
openstack server add floating ip <server-id> <floating-ip>

# Floating IPs auflisten
openstack floating ip list

# Security Groups auflisten
openstack security group list

# Security Group erstellen
openstack security group create meine-sg --description "HTTP+SSH"

# Regel hinzufügen (SSH)
openstack security group rule create \
  --protocol tcp --dst-port 22 \
  --remote-ip 0.0.0.0/0 meine-sg

# Regel hinzufügen (HTTP)
openstack security group rule create \
  --protocol tcp --dst-port 80 \
  --remote-ip 0.0.0.0/0 meine-sg

# Router auflisten / erstellen
openstack router list
openstack router create mein-router
openstack router set --external-gateway admin_external_net mein-router
openstack router add subnet mein-router mein-subnet

# ELB (Load Balancer) auflisten
otc elb list
```

---

## Object Storage – OBS (OpenStack Swift)

```bash
# Container (Buckets) auflisten
openstack container list
swift list

# Container erstellen
openstack container create mein-container

# Objekte hochladen
openstack object create mein-container lokale-datei.txt
swift upload mein-container lokale-datei.txt

# Objekte auflisten
openstack object list mein-container

# Objekt herunterladen
openstack object save mein-container datei.txt
swift download mein-container datei.txt

# Objekt löschen
openstack object delete mein-container datei.txt

# Container löschen (muss leer sein)
openstack container delete mein-container

# Container öffentlich zugänglich machen
swift post -r '.r:*' mein-container

# Statistik anzeigen
swift stat
swift stat mein-container
```

---

## Block Storage – EVS (Cinder)

```bash
# Volumes auflisten
openstack volume list
otc evs list

# Volume erstellen (50 GB SSD)
openstack volume create \
  --size 50 \
  --type SSD \
  --availability-zone eu-de-01 \
  mein-volume

# Volume an Server anhängen
openstack server add volume <server-id> <volume-id>

# Volume trennen
openstack server remove volume <server-id> <volume-id>

# Snapshot erstellen
openstack volume snapshot create \
  --volume <volume-id> \
  --name mein-snapshot

# Volume aus Snapshot wiederherstellen
openstack volume create \
  --snapshot <snapshot-id> \
  --size 50 wiederhergestelltes-volume

# Volume löschen
openstack volume delete <volume-id>
```

---

## CCE – Cloud Container Engine (Kubernetes)

```bash
# Cluster auflisten
otc cce cluster list

# Cluster erstellen
otc cce cluster create \
  --name mein-cce-cluster \
  --flavor cce.s2.small \
  --vpc-id <vpc-id> \
  --subnet-id <subnet-id>

# Cluster-Details anzeigen
otc cce cluster show <cluster-id>

# kubeconfig herunterladen
otc cce cluster get-credentials <cluster-id> > ~/.kube/config
# oder
otc cce cluster get-credentials <cluster-id> --kubeconfig ~/.kube/otc-config.yaml

# Node Pools auflisten
otc cce nodepool list --cluster-id <cluster-id>

# Nodes auflisten
otc cce node list --cluster-id <cluster-id>
```

---

## DNS & Domain

```bash
# Zonen auflisten
openstack zone list
otc dns zone list

# Zone erstellen (öffentlich)
openstack zone create \
  --type public \
  --email admin@meinedomain.de \
  meinedomain.de.

# DNS-Record erstellen (A-Record)
openstack recordset create \
  --type A \
  --records "1.2.3.4" \
  meinedomain.de. www.meinedomain.de.

# Records einer Zone auflisten
openstack recordset list meinedomain.de.

# Zone löschen
openstack zone delete meinedomain.de.
```

---

## IAM – Identity Access Management

```bash
# Benutzer erstellen
openstack user create \
  --domain <domain-id> \
  --password "SecurePass123" \
  neuer-user

# Benutzer einer Gruppe zuweisen
openstack group add user <group-id> <user-id>

# Gruppe erstellen
openstack group create meine-gruppe

# Rolle zuweisen
openstack role add \
  --project <project-id> \
  --user <user-id> \
  <role-name>

# Agenturen (AK/SK) anlegen – für programmatischen Zugriff
# In der OTC-Konsole: IAM → My Credentials → Access Keys

# Umgebungsvariablen für AK/SK setzen
export AWS_ACCESS_KEY_ID=<ak>
export AWS_SECRET_ACCESS_KEY=<sk>
# OBS kann dann via s3-kompatibler API genutzt werden
```

---

## Monitoring & CES (Cloud Eye)

```bash
# Metriken auflisten (via REST-API, da kein direkter CLI-Befehl)
# Basis-URL: https://ces.eu-de.otc.t-systems.com/v1.0/<project-id>/metrics

# OTC Quota anzeigen
otc quota list

# Ressourcen-Taggen
openstack server set --tag Umgebung=Produktion <server-id>
openstack server show <server-id> -f json | jq '.tags'
```

---

## Terraform mit OTC

```bash
# Provider in main.tf
cat << 'EOF' > provider.tf
terraform {
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.36"
    }
  }
}

provider "opentelekomcloud" {
  auth_url    = "https://iam.eu-de.otc.t-systems.com/v3"
  tenant_name = var.project_name
  domain_name = var.domain_name
  user_name   = var.username
  password    = var.password
  region      = "eu-de"
}
EOF

terraform init
terraform plan
terraform apply
```

---

## Tipps & Tricks

```bash
# JSON-Ausgabe für Scripting
openstack server list -f json | jq '.[].Name'

# Tabellenausgabe anpassen
openstack server list -c Name -c Status -c Networks

# Alle Ressourcen eines Projekts finden (Quota-Übersicht)
openstack quota show

# Region in RC-Datei überprüfen
env | grep OS_

# OTC-spezifische API-Endpunkte abrufen
openstack catalog list

# Fehlermeldungen debuggen
openstack --debug server list 2>&1 | head -50

# OTC-Dokumentation
# https://docs.otc.t-systems.com/
# https://github.com/opentelekomcloud/python-otcextensions
```
