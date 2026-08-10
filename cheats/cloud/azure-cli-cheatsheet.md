# Azure CLI Cheat Sheet

## Installation & Konfiguration

```bash
# Installation (macOS)
brew install azure-cli

# Login (öffnet Browser)
az login

# Login mit Service Principal (CI/CD)
az login --service-principal \
  --username <APP_ID> \
  --password <PASSWORD> \
  --tenant <TENANT_ID>

# Aktuelles Konto anzeigen
az account show

# Alle verfügbaren Subscriptions auflisten
az account list --output table

# Aktive Subscription wechseln
az account set --subscription "Meine Subscription"

# Azure CLI Version
az version

# Logout
az logout
```

---

## Resource Groups

```bash
# Alle Resource Groups auflisten
az group list --output table

# Resource Group erstellen
az group create \
  --name meine-rg \
  --location germanywestcentral

# Resource Group löschen (mit Bestätigung)
az group delete --name meine-rg

# Alle Ressourcen in einer Group anzeigen
az resource list --resource-group meine-rg --output table
```

---

## VMs – Virtuelle Maschinen

```bash
# Alle VMs auflisten
az vm list --output table

# VMs mit Status auflisten
az vm list --show-details --output table

# VM erstellen
az vm create \
  --resource-group meine-rg \
  --name meine-vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --location germanywestcentral

# VM starten / stoppen / neu starten
az vm start --resource-group meine-rg --name meine-vm
az vm stop --resource-group meine-rg --name meine-vm
az vm restart --resource-group meine-rg --name meine-vm

# VM löschen
az vm delete --resource-group meine-rg --name meine-vm

# Per SSH verbinden (public IP abrufen)
az vm show \
  --resource-group meine-rg \
  --name meine-vm \
  --show-details \
  --query publicIps -o tsv

# Größe (SKU) einer VM ändern
az vm resize \
  --resource-group meine-rg \
  --name meine-vm \
  --size Standard_B2s
```

---

## Netzwerk – VNet, NSG, Public IP

```bash
# VNets auflisten
az network vnet list --output table

# VNet erstellen
az network vnet create \
  --resource-group meine-rg \
  --name mein-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.1.0/24

# Network Security Groups auflisten
az network nsg list --output table

# NSG-Regeln anzeigen
az network nsg rule list \
  --resource-group meine-rg \
  --nsg-name meine-nsg \
  --output table

# NSG-Regel hinzufügen (z.B. HTTPS eingehend)
az network nsg rule create \
  --resource-group meine-rg \
  --nsg-name meine-nsg \
  --name allow-https \
  --protocol tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefix '*' \
  --destination-port-range 443 \
  --access Allow

# Public IP-Adressen auflisten
az network public-ip list --output table
```

---

## Storage – Blob Storage

```bash
# Alle Storage Accounts auflisten
az storage account list --output table

# Storage Account erstellen
az storage account create \
  --name meinaccount \
  --resource-group meine-rg \
  --location germanywestcentral \
  --sku Standard_LRS

# Container auflisten
az storage container list \
  --account-name meinaccount \
  --output table

# Container erstellen
az storage container create \
  --name mein-container \
  --account-name meinaccount

# Datei hochladen
az storage blob upload \
  --account-name meinaccount \
  --container-name mein-container \
  --name meine-datei.txt \
  --file ./meine-datei.txt

# Datei herunterladen
az storage blob download \
  --account-name meinaccount \
  --container-name mein-container \
  --name meine-datei.txt \
  --file ./download.txt

# Blobs auflisten
az storage blob list \
  --account-name meinaccount \
  --container-name mein-container \
  --output table
```

---

## AKS – Azure Kubernetes Service

```bash
# Cluster auflisten
az aks list --output table

# Cluster erstellen
az aks create \
  --resource-group meine-rg \
  --name mein-cluster \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

# kubeconfig abrufen
az aks get-credentials \
  --resource-group meine-rg \
  --name mein-cluster

# Cluster skalieren
az aks scale \
  --resource-group meine-rg \
  --name mein-cluster \
  --node-count 3

# Cluster löschen
az aks delete --resource-group meine-rg --name mein-cluster
```

---

## Azure SQL / Datenbanken

```bash
# SQL Server auflisten
az sql server list --output table

# SQL-Datenbanken eines Servers auflisten
az sql db list \
  --resource-group meine-rg \
  --server mein-server \
  --output table

# Datenbank erstellen
az sql db create \
  --resource-group meine-rg \
  --server mein-server \
  --name meine-db \
  --service-objective S0
```

---

## App Service / Web Apps

```bash
# App Service Plans auflisten
az appservice plan list --output table

# Web Apps auflisten
az webapp list --output table

# Web App erstellen
az webapp create \
  --resource-group meine-rg \
  --plan mein-plan \
  --name meine-app \
  --runtime "NODE:18-lts"

# App starten / stoppen
az webapp start --resource-group meine-rg --name meine-app
az webapp stop --resource-group meine-rg --name meine-app

# App-Logs streamen
az webapp log tail \
  --resource-group meine-rg \
  --name meine-app
```

---

## Azure AD / Entra ID

```bash
# Aktuellen Tenant anzeigen
az account show --query tenantId

# Service Principal erstellen
az ad sp create-for-rbac \
  --name mein-sp \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# Aktuelle Benutzer auflisten
az ad user list --output table

# Gruppen auflisten
az ad group list --output table
```

---

## Nützliche Allgemein-Optionen

```bash
# Ausgabeformat setzen: json, table, tsv, yaml
az vm list --output table
az vm list --output json
az vm list --output tsv

# JMESPath Query – nur bestimmte Felder
az vm list --query '[*].[name, location, provisioningState]' --output table

# Standardwerte setzen (spart --resource-group bei jedem Befehl)
az configure --defaults group=meine-rg location=germanywestcentral

# Interaktiver Modus (Autocomplete im Terminal)
az interactive

# Hilfe zu einem Befehl
az vm create --help
```
