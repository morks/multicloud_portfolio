# Azure Arc Cheat Sheet

## Installation & Setup

```bash
# Install required Azure CLI extensions
az extension add --name connectedk8s
az extension add --name connectedmachine
az extension add --name k8s-configuration
az extension add --name k8s-extension

# Update existing extensions
az extension update --name connectedk8s
az extension update --name connectedmachine
az extension update --name k8s-configuration
az extension update --name k8s-extension

# Check installed extension versions
az extension list --output table

# Login to Azure (opens browser)
az login

# Set active subscription
az account set --subscription "my-subscription"

# Confirm active subscription
az account show --query "{name:name, id:id}" --output table

# Register required resource providers
az provider register --namespace Microsoft.HybridCompute
az provider register --namespace Microsoft.HybridConnectivity
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

# Check registration status
az provider show --namespace Microsoft.HybridCompute --query registrationState
az provider show --namespace Microsoft.Kubernetes --query registrationState
```

---

## Arc-Enabled Servers

```bash
# ---- Linux: Onboard server via azcmagent ----

# Download and install the agent on Linux
curl -L -o /tmp/install_linux_azcmagent.sh \
  https://aka.ms/azcmagent-linux
sudo bash /tmp/install_linux_azcmagent.sh

# Connect the server to Azure Arc
sudo azcmagent connect \
  --resource-group my-rg \
  --tenant-id <TENANT_ID> \
  --location germanywestcentral \
  --subscription-id <SUBSCRIPTION_ID> \
  --cloud AzureCloud

# ---- Windows: Onboard server via azcmagent ----

# Download and run installer (PowerShell)
Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile AzureConnectedMachineAgent.msi
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn

# Connect via PowerShell
& "$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect `
  --resource-group "my-rg" `
  --tenant-id "<TENANT_ID>" `
  --location "germanywestcentral" `
  --subscription-id "<SUBSCRIPTION_ID>"

# ---- Manage Arc-enabled servers with az CLI ----

# List all connected machines
az connectedmachine list --output table

# List machines in a specific resource group
az connectedmachine list --resource-group my-rg --output table

# Show details for a specific server
az connectedmachine show \
  --resource-group my-rg \
  --name my-server

# Delete a connected machine (removes from Azure; does not uninstall agent)
az connectedmachine delete \
  --resource-group my-rg \
  --name my-server

# ---- Extensions on Arc-enabled servers ----

# Install the Log Analytics (MMA) extension on Linux
az connectedmachine extension create \
  --resource-group my-rg \
  --machine-name my-server \
  --name MicrosoftMonitoringAgent \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --type OmsAgentForLinux \
  --settings '{"workspaceId":"<WORKSPACE_ID>"}' \
  --protected-settings '{"workspaceKey":"<WORKSPACE_KEY>"}'

# Install Custom Script Extension
az connectedmachine extension create \
  --resource-group my-rg \
  --machine-name my-server \
  --name CustomScriptExtension \
  --publisher Microsoft.Azure.Extensions \
  --type CustomScript \
  --settings '{"fileUris":["https://mystorageaccount.blob.core.windows.net/scripts/setup.sh"],"commandToExecute":"bash setup.sh"}'

# Install Microsoft Defender for Endpoint extension
az connectedmachine extension create \
  --resource-group my-rg \
  --machine-name my-server \
  --name MDE.Linux \
  --publisher Microsoft.Azure.AzureDefenderForServers \
  --type MDE.Linux

# List extensions on a server
az connectedmachine extension list \
  --resource-group my-rg \
  --machine-name my-server \
  --output table

# Delete an extension
az connectedmachine extension delete \
  --resource-group my-rg \
  --machine-name my-server \
  --name MicrosoftMonitoringAgent

# ---- Tags ----

# Add or update tags on a connected machine
az connectedmachine update \
  --resource-group my-rg \
  --name my-server \
  --tags environment=production owner=ops-team

# ---- Run command remotely on Arc server ----

# Run a script on the server (preview)
az connectedmachine run-command create \
  --resource-group my-rg \
  --machine-name my-server \
  --run-command-name my-run-cmd \
  --script "hostname && uptime"

# ---- SSH access via Azure Arc ----

# Enable SSH connectivity (run on server or via bootstrap script)
az connectedmachine extension create \
  --resource-group my-rg \
  --machine-name my-server \
  --name SSH \
  --publisher Microsoft.Azure.OpenSSH \
  --type WindowsOpenSSH   # or LinuxOpenSSH

# SSH into the server through Arc
az ssh arc \
  --resource-group my-rg \
  --name my-server \
  --local-user azureuser
```

---

## Arc-Enabled Kubernetes

```bash
# Connect an existing Kubernetes cluster to Azure Arc
az connectedk8s connect \
  --resource-group my-rg \
  --name my-cluster \
  --location germanywestcentral

# Connect with custom tags
az connectedk8s connect \
  --resource-group my-rg \
  --name my-cluster \
  --location germanywestcentral \
  --tags environment=staging team=platform

# List all Arc-enabled Kubernetes clusters
az connectedk8s list --output table

# List clusters in a resource group
az connectedk8s list --resource-group my-rg --output table

# Show details of a connected cluster
az connectedk8s show \
  --resource-group my-rg \
  --name my-cluster

# Update cluster metadata (tags, distribution, infrastructure)
az connectedk8s update \
  --resource-group my-rg \
  --name my-cluster \
  --auto-upgrade false

# Get credentials for a connected Arc cluster (cluster-connect feature)
az connectedk8s proxy \
  --resource-group my-rg \
  --name my-cluster \
  --port 47011

# Enable optional features on the connected cluster
# Enable Custom Locations feature
az connectedk8s enable-features \
  --resource-group my-rg \
  --name my-cluster \
  --features custom-locations

# Enable Cluster Connect feature
az connectedk8s enable-features \
  --resource-group my-rg \
  --name my-cluster \
  --features cluster-connect

# Enable multiple features at once
az connectedk8s enable-features \
  --resource-group my-rg \
  --name my-cluster \
  --features cluster-connect custom-locations

# Disable a feature
az connectedk8s disable-features \
  --resource-group my-rg \
  --name my-cluster \
  --features cluster-connect

# Configure proxy settings for Arc agents in the cluster
az connectedk8s connect \
  --resource-group my-rg \
  --name my-cluster \
  --proxy-https http://proxy.corp.local:3128 \
  --proxy-http http://proxy.corp.local:3128 \
  --proxy-skip-range "10.0.0.0/8,localhost,127.0.0.1"

# Disconnect (remove) a cluster from Azure Arc
az connectedk8s delete \
  --resource-group my-rg \
  --name my-cluster
```

---

## GitOps with Arc (Flux)

```bash
# ---- Flux v2 configurations (az k8s-configuration flux) ----

# Create a Flux configuration from a public Git repository
az k8s-configuration flux create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-gitops-config \
  --namespace my-namespace \
  --scope cluster \
  --url https://github.com/my-org/my-repo \
  --branch main \
  --kustomization name=apps path=./apps prune=true

# Create a Flux configuration from a private Git repo (SSH)
az k8s-configuration flux create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-private-config \
  --namespace my-namespace \
  --scope cluster \
  --url git@github.com:my-org/my-private-repo \
  --branch main \
  --ssh-private-key-file ~/.ssh/id_rsa \
  --kustomization name=infra path=./infrastructure prune=true interval=5m

# Create a Flux configuration from an Azure Blob Storage source
az k8s-configuration flux create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-blob-config \
  --namespace my-namespace \
  --scope cluster \
  --kind AzureBlob \
  --url "https://mystorageaccount.blob.core.windows.net/my-container" \
  --kustomization name=apps path=./apps prune=true

# Create a Flux configuration from an S3-compatible Bucket source
az k8s-configuration flux create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-bucket-config \
  --namespace my-namespace \
  --scope cluster \
  --kind Bucket \
  --url "minio.corp.local:9000" \
  --bucket-name my-bucket \
  --kustomization name=apps path=./apps prune=true

# List all Flux configurations on a cluster
az k8s-configuration flux list \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --output table

# Show details of a Flux configuration (including sync status)
az k8s-configuration flux show \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-gitops-config

# Delete a Flux configuration
az k8s-configuration flux delete \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-gitops-config

# ---- Classic (Flux v1) configurations ----

# Create a classic GitOps configuration
az k8s-configuration create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-classic-config \
  --operator-instance-name flux \
  --operator-namespace my-namespace \
  --repository-url https://github.com/my-org/my-repo \
  --scope cluster \
  --enable-helm-operator \
  --helm-operator-params '--set helm.versions=v3'

# List classic configurations
az k8s-configuration list \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --output table

# Check sync status of a configuration
az k8s-configuration show \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name my-classic-config \
  --query complianceStatus
```

---

## Arc Extensions

```bash
# List all available extension types for a cluster
az k8s-extension extension-types list \
  --cluster-name my-cluster \
  --resource-group my-rg \
  --cluster-type connectedClusters \
  --output table

# Install Azure Monitor (Container Insights) extension
az k8s-extension create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name azuremonitor-containers \
  --extension-type Microsoft.AzureMonitor.Containers \
  --configuration-settings logAnalyticsWorkspaceResourceID=/subscriptions/<SUB_ID>/resourceGroups/my-rg/providers/Microsoft.OperationalInsights/workspaces/my-workspace

# Install Microsoft Defender for Containers extension
az k8s-extension create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name microsoft-defender \
  --extension-type microsoft.azuredefender.kubernetes

# Install Azure App Services extension (for Arc-enabled app services)
az k8s-extension create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name appservice-ext \
  --extension-type Microsoft.Web.Appservice \
  --release-train stable \
  --auto-upgrade-minor-version true \
  --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default"

# Install Azure Arc Data Services extension
az k8s-extension create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name arc-data-services \
  --extension-type microsoft.arcdataservices \
  --auto-upgrade false \
  --scope cluster \
  --release-namespace arc-data-services \
  --config Microsoft.CustomLocation.ServiceAccount=sa-arc-bootstrapper

# Install Azure Machine Learning extension
az k8s-extension create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name aml-ext \
  --extension-type Microsoft.AzureML.Kubernetes \
  --scope cluster \
  --configuration-settings enableTraining=True enableInference=True inferenceRouterServiceType=LoadBalancer

# List all extensions on a cluster
az k8s-extension list \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --output table

# Show extension details and provisioning state
az k8s-extension show \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name azuremonitor-containers

# Update extension configuration or auto-upgrade settings
az k8s-extension update \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name azuremonitor-containers \
  --auto-upgrade-minor-version true

# Pin extension to a specific version (disable auto-upgrade)
az k8s-extension update \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name microsoft-defender \
  --version 0.6.0 \
  --auto-upgrade-minor-version false

# Delete an extension
az k8s-extension delete \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name azuremonitor-containers
```

---

## Arc-Enabled Data Services

```bash
# ---- Data Controller ----

# Create a data controller (indirect connectivity mode)
az arcdata dc create \
  --resource-group my-rg \
  --name my-data-ctrl \
  --location germanywestcentral \
  --connectivity-mode indirect \
  --profile-name azure-arc-kubeadm \
  --storage-class default \
  --namespace arc-data \
  --custom-location my-custom-location

# Create a data controller (direct connectivity mode, requires Arc extension)
az arcdata dc create \
  --resource-group my-rg \
  --name my-data-ctrl \
  --location germanywestcentral \
  --connectivity-mode direct \
  --profile-name azure-arc-aks-default-storage \
  --storage-class managed-premium \
  --namespace arc-data

# List data controllers
az arcdata dc list --output table

# List data controllers in a resource group
az arcdata dc list --resource-group my-rg --output table

# Show data controller status
az arcdata dc show \
  --resource-group my-rg \
  --name my-data-ctrl

# Upload usage/telemetry (indirect mode only)
az arcdata dc upload \
  --path ./usage.json

# ---- SQL Managed Instance ----

# Create a SQL Managed Instance on Arc
az sql mi-arc create \
  --name my-sql-mi \
  --resource-group my-rg \
  --custom-location my-custom-location \
  --storage-class-data managed-premium \
  --storage-class-logs managed-premium \
  --storage-class-backups azurefile \
  --tier GeneralPurpose \
  --cores-request "2" \
  --cores-limit "4" \
  --memory-request "4Gi" \
  --memory-limit "8Gi"

# List SQL Managed Instances
az sql mi-arc list --resource-group my-rg --output table

# Show SQL MI details
az sql mi-arc show \
  --resource-group my-rg \
  --name my-sql-mi

# Get SQL MI endpoint (connection string)
az sql mi-arc show \
  --resource-group my-rg \
  --name my-sql-mi \
  --query "properties.k8SRaw.status.endpoints"

# Delete SQL Managed Instance
az sql mi-arc delete \
  --resource-group my-rg \
  --name my-sql-mi

# ---- PostgreSQL on Arc ----

# Create a PostgreSQL instance
az postgres arc-server create \
  --name my-pg-server \
  --resource-group my-rg \
  --custom-location my-custom-location \
  --storage-class-data managed-premium \
  --cores-request "1" \
  --cores-limit "2" \
  --memory-request "2Gi" \
  --memory-limit "4Gi" \
  --workers 2

# List PostgreSQL instances
az postgres arc-server list --resource-group my-rg --output table

# Show PostgreSQL details and endpoint
az postgres arc-server show \
  --resource-group my-rg \
  --name my-pg-server
```

---

## Azure Policy & Compliance

```bash
# ---- List built-in policies for Arc ----

# Find Arc-related policy definitions
az policy definition list \
  --query "[?contains(displayName, 'Arc')].[displayName, name]" \
  --output table

# ---- Assign a policy to Arc-enabled servers ----

# Assign "Configure Linux Arc machines to run Azure Monitor Agent"
az policy assignment create \
  --name "arc-linux-ama" \
  --display-name "Arc Linux: Install Azure Monitor Agent" \
  --policy "a4034bc6-ae50-406d-bf76-50f4ee5a7811" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/my-rg" \
  --identity-type SystemAssigned \
  --location germanywestcentral

# Assign a policy to all Arc servers in a subscription
az policy assignment create \
  --name "arc-tag-enforcement" \
  --display-name "Require environment tag on Arc servers" \
  --policy "96670d01-0a4d-4649-9c89-2d3abc0a5025" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>"

# ---- View compliance state ----

# List non-compliant resources for a policy assignment
az policy state list \
  --resource-group my-rg \
  --filter "complianceState eq 'NonCompliant'" \
  --output table

# Summarize compliance for a specific assignment
az policy state summarize \
  --resource-group my-rg \
  --policy-assignment arc-linux-ama

# Get compliance details for a specific Arc server
az policy state list \
  --resource "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/my-rg/providers/Microsoft.HybridCompute/machines/my-server" \
  --output table

# ---- Remediation ----

# Create a remediation task for a non-compliant assignment
az policy remediation create \
  --resource-group my-rg \
  --name remediate-arc-ama \
  --policy-assignment arc-linux-ama

# List remediation tasks
az policy remediation list \
  --resource-group my-rg \
  --output table

# Show remediation task status
az policy remediation show \
  --resource-group my-rg \
  --name remediate-arc-ama
```

---

## Custom Locations

```bash
# Prerequisites: cluster-connect and custom-locations features must be enabled
# See: az connectedk8s enable-features (above)

# Get the Arc cluster resource ID
CLUSTER_ID=$(az connectedk8s show \
  --resource-group my-rg \
  --name my-cluster \
  --query id --output tsv)

# Get the Arc Data Services extension ID
EXT_ID=$(az k8s-extension show \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name arc-data-services \
  --query id --output tsv)

# Create a custom location on the connected cluster
az customlocation create \
  --resource-group my-rg \
  --name my-custom-location \
  --host-resource-id "$CLUSTER_ID" \
  --namespace arc-data \
  --cluster-extension-ids "$EXT_ID" \
  --location germanywestcentral

# Create a custom location for App Services
az customlocation create \
  --resource-group my-rg \
  --name my-appservice-location \
  --host-resource-id "$CLUSTER_ID" \
  --namespace my-namespace \
  --cluster-extension-ids "$(az k8s-extension show -g my-rg --cluster-name my-cluster --cluster-type connectedClusters --name appservice-ext --query id -o tsv)" \
  --location germanywestcentral

# List all custom locations
az customlocation list --output table

# List custom locations in a resource group
az customlocation list --resource-group my-rg --output table

# Show custom location details
az customlocation show \
  --resource-group my-rg \
  --name my-custom-location

# List namespace resource sync rules for a custom location
az customlocation list-enabled-resource-types \
  --resource-group my-rg \
  --name my-custom-location \
  --output table

# Delete a custom location
az customlocation delete \
  --resource-group my-rg \
  --name my-custom-location
```

---

## Monitoring & Diagnostics

```bash
# ---- Enable Container Insights on Arc Kubernetes cluster ----

az k8s-extension create \
  --resource-group my-rg \
  --cluster-name my-cluster \
  --cluster-type connectedClusters \
  --name azuremonitor-containers \
  --extension-type Microsoft.AzureMonitor.Containers \
  --configuration-settings \
    logAnalyticsWorkspaceResourceID="/subscriptions/<SUB_ID>/resourceGroups/my-rg/providers/Microsoft.OperationalInsights/workspaces/my-workspace" \
    amalogs.useAADAuth=true

# ---- Arc agent diagnostics on the server (run on the machine) ----

# Show agent status and configuration
sudo azcmagent show

# Run connectivity and configuration checks
sudo azcmagent check

# Collect agent logs to a ZIP archive for troubleshooting
sudo azcmagent logs

# Show the agent version
sudo azcmagent version

# Disconnect and reconnect the agent
sudo azcmagent disconnect
sudo azcmagent connect \
  --resource-group my-rg \
  --tenant-id <TENANT_ID> \
  --location germanywestcentral \
  --subscription-id <SUBSCRIPTION_ID>

# ---- Log Analytics: heartbeat query for Arc servers ----
# Run this in Log Analytics Workspace / Azure Monitor Logs:
#
# Heartbeat
# | where Category == "Direct Agent"
# | where TimeGenerated > ago(1h)
# | summarize LastHeartbeat=max(TimeGenerated) by Computer, OSType
# | where LastHeartbeat < ago(5m)
# | project Computer, OSType, LastHeartbeat

# ---- View Arc agent logs on Linux ----
# Agent service log
sudo journalctl -u himds -n 100 --no-pager
# Extension manager log
sudo cat /var/lib/waagent/log/extension-manager.log
# GC agent log
sudo cat /var/opt/azcmagent/log/gc_agent.log

# ---- Verify Arc agent service status on Linux ----
systemctl status himds
systemctl status gcad

# ---- Verify Arc agent service status on Windows (PowerShell) ----
# Get-Service -Name "himds","GCArcService" | Select-Object Name, Status
```

---

## Tips & Tricks

```bash
# ---- Azure Resource Graph: query Arc inventory ----

# List all Arc-enabled servers across subscriptions
az graph query -q "
  Resources
  | where type == 'microsoft.hybridcompute/machines'
  | project name, resourceGroup, location, properties.status, properties.osName
  | order by name asc
" --output table

# List all Arc-enabled Kubernetes clusters
az graph query -q "
  Resources
  | where type == 'microsoft.kubernetes/connectedclusters'
  | project name, resourceGroup, location, properties.connectivityStatus, properties.kubernetesVersion
" --output table

# Find Arc machines with a specific tag
az graph query -q "
  Resources
  | where type == 'microsoft.hybridcompute/machines'
  | where tags['environment'] == 'production'
  | project name, resourceGroup, location, tags
" --output table

# Count Arc resources by type
az graph query -q "
  Resources
  | where type startswith 'microsoft.hybridcompute' or type startswith 'microsoft.kubernetes'
  | summarize count() by type
" --output table

# ---- Bulk onboarding script pattern (Linux) ----
# Generate a service principal for onboarding
az ad sp create-for-rbac \
  --name arc-onboarding-sp \
  --role "Azure Connected Machine Onboarding" \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/my-rg \
  --output json

# Use the SP credentials in the azcmagent connect call
sudo azcmagent connect \
  --resource-group my-rg \
  --tenant-id <TENANT_ID> \
  --location germanywestcentral \
  --subscription-id <SUBSCRIPTION_ID> \
  --service-principal-id <SP_APP_ID> \
  --service-principal-secret <SP_SECRET>

# ---- Proxy settings for azcmagent ----
# Set proxy for the Arc agent on Linux
sudo azcmagent config set proxy.url "http://proxy.corp.local:3128"

# Remove proxy setting
sudo azcmagent config clear proxy.url

# Verify current agent config
sudo azcmagent config list

# ---- Arc resource ID format reference ----
# Connected Machine:
#   /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.HybridCompute/machines/<MACHINE_NAME>
# Connected Cluster:
#   /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Kubernetes/connectedClusters/<CLUSTER_NAME>
# K8s Extension:
#   .../providers/Microsoft.KubernetesConfiguration/extensions/<EXTENSION_NAME>
# Custom Location:
#   /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.ExtendedLocation/customLocations/<LOCATION_NAME>

# ---- Useful KQL queries for Arc inventory in Log Analytics ----
# (Paste into Log Analytics Workspace > Logs)

# Arc server inventory with OS and status
# Heartbeat
# | where TimeGenerated > ago(24h)
# | where Category == "Direct Agent"
# | summarize LastSeen=max(TimeGenerated), OSType=any(OSType) by Computer
# | extend Status = iff(LastSeen > ago(1h), "Connected", "Disconnected")
# | project Computer, OSType, Status, LastSeen

# Extension health across Arc machines
# ConfigurationChange
# | where TimeGenerated > ago(7d)
# | where ConfigChangeType == "Software"
# | project Computer, Software, ChangeCategory, TimeGenerated
# | order by TimeGenerated desc

# ---- Tagging strategy tips ----
# Apply consistent tags to all Arc resources at onboarding time
# Recommended tags: environment, owner, cost-center, managed-by, onboarded-date
az connectedmachine update \
  --resource-group my-rg \
  --name my-server \
  --tags \
    environment=production \
    owner=platform-team \
    cost-center=CC-12345 \
    managed-by=azure-arc \
    onboarded-date=2024-01-15
```
