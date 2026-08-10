# Azure CLI Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install azure-cli

# Login (opens browser)
az login

# Login with Service Principal (CI/CD)
az login --service-principal \
  --username <APP_ID> \
  --password <PASSWORD> \
  --tenant <TENANT_ID>

# Show current account
az account show

# List all available subscriptions
az account list --output table

# Switch active subscription
az account set --subscription "Meine Subscription"

# Azure CLI version
az version

# Logout
az logout
```

---

## Resource Groups

```bash
# List all resource groups
az group list --output table

# Create resource group
az group create \
  --name meine-rg \
  --location germanywestcentral

# Delete resource group (with confirmation)
az group delete --name meine-rg

# Show all resources in a group
az resource list --resource-group meine-rg --output table
```

---

## VMs – Virtual Machines

```bash
# List all VMs
az vm list --output table

# List VMs with status
az vm list --show-details --output table

# Create VM
az vm create \
  --resource-group meine-rg \
  --name meine-vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --location germanywestcentral

# Start / stop / restart VM
az vm start --resource-group meine-rg --name meine-vm
az vm stop --resource-group meine-rg --name meine-vm
az vm restart --resource-group meine-rg --name meine-vm

# Delete VM
az vm delete --resource-group meine-rg --name meine-vm

# Connect via SSH (retrieve public IP)
az vm show \
  --resource-group meine-rg \
  --name meine-vm \
  --show-details \
  --query publicIps -o tsv

# Change VM size (SKU)
az vm resize \
  --resource-group meine-rg \
  --name meine-vm \
  --size Standard_B2s
```

---

## Network – VNet, NSG, Public IP

```bash
# List VNets
az network vnet list --output table

# Create VNet
az network vnet create \
  --resource-group meine-rg \
  --name mein-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.1.0/24

# List Network Security Groups
az network nsg list --output table

# Show NSG rules
az network nsg rule list \
  --resource-group meine-rg \
  --nsg-name meine-nsg \
  --output table

# Add NSG rule (e.g. HTTPS inbound)
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

# List public IP addresses
az network public-ip list --output table
```

---

## Storage – Blob Storage

```bash
# List all storage accounts
az storage account list --output table

# Create storage account
az storage account create \
  --name meinaccount \
  --resource-group meine-rg \
  --location germanywestcentral \
  --sku Standard_LRS

# List containers
az storage container list \
  --account-name meinaccount \
  --output table

# Create container
az storage container create \
  --name mein-container \
  --account-name meinaccount

# Upload file
az storage blob upload \
  --account-name meinaccount \
  --container-name mein-container \
  --name meine-datei.txt \
  --file ./meine-datei.txt

# Download file
az storage blob download \
  --account-name meinaccount \
  --container-name mein-container \
  --name meine-datei.txt \
  --file ./download.txt

# List blobs
az storage blob list \
  --account-name meinaccount \
  --container-name mein-container \
  --output table
```

---

## AKS – Azure Kubernetes Service

```bash
# List clusters
az aks list --output table

# Create cluster
az aks create \
  --resource-group meine-rg \
  --name mein-cluster \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

# Retrieve kubeconfig
az aks get-credentials \
  --resource-group meine-rg \
  --name mein-cluster

# Scale cluster
az aks scale \
  --resource-group meine-rg \
  --name mein-cluster \
  --node-count 3

# Delete cluster
az aks delete --resource-group meine-rg --name mein-cluster
```

---

## Azure SQL / Databases

```bash
# List SQL servers
az sql server list --output table

# List SQL databases for a server
az sql db list \
  --resource-group meine-rg \
  --server mein-server \
  --output table

# Create database
az sql db create \
  --resource-group meine-rg \
  --server mein-server \
  --name meine-db \
  --service-objective S0
```

---

## App Service / Web Apps

```bash
# List App Service Plans
az appservice plan list --output table

# List Web Apps
az webapp list --output table

# Create Web App
az webapp create \
  --resource-group meine-rg \
  --plan mein-plan \
  --name meine-app \
  --runtime "NODE:18-lts"

# Start / stop app
az webapp start --resource-group meine-rg --name meine-app
az webapp stop --resource-group meine-rg --name meine-app

# Stream app logs
az webapp log tail \
  --resource-group meine-rg \
  --name meine-app
```

---

## Azure AD / Entra ID

```bash
# Show current tenant
az account show --query tenantId

# Create Service Principal
az ad sp create-for-rbac \
  --name mein-sp \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# List current users
az ad user list --output table

# List groups
az ad group list --output table
```

---

## Useful General Options

```bash
# Set output format: json, table, tsv, yaml
az vm list --output table
az vm list --output json
az vm list --output tsv

# JMESPath query – specific fields only
az vm list --query '[*].[name, location, provisioningState]' --output table

# Set defaults (saves typing --resource-group on every command)
az configure --defaults group=meine-rg location=germanywestcentral

# Interactive mode (autocomplete in terminal)
az interactive

# Show help for a command
az vm create --help
```
