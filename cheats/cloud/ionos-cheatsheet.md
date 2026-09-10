# IONOS Cloud CLI Cheat Sheet

## Installation & Setup

```bash
# Install via Homebrew (macOS)
brew install ionos-cloud/tap/ionosctl

# Install binary directly (Linux)
curl -sL https://github.com/ionos-cloud/ionosctl/releases/latest/download/ionosctl-linux-amd64.tar.gz \
  | tar xz && mv ionosctl /usr/local/bin/

# Show version
ionosctl version

# Login interactively (prompts for username/password)
ionosctl login

# Login via environment variables
export IONOS_USERNAME="user@example.com"
export IONOS_PASSWORD="your-password"
ionosctl whoami

# Login via token (recommended for CI/CD)
export IONOS_TOKEN="your-token"
ionosctl whoami

# Generate a token
ionosctl token generate

# List available tokens
ionosctl token list

# Show current configuration
ionosctl cfg list

# Set a profile
ionosctl cfg set --profile prod \
  --token "your-prod-token"

# Switch profile
ionosctl cfg switch --profile prod
```

---

## Data Centers & Locations

```bash
# List all data centers
ionosctl datacenter list

# Get data center details
ionosctl datacenter get --datacenter-id <DC_ID>

# Create a data center
ionosctl datacenter create \
  --name my-datacenter \
  --location de/fra \
  --description "Frankfurt datacenter"

# Update a data center
ionosctl datacenter update \
  --datacenter-id <DC_ID> \
  --name new-name

# Delete a data center
ionosctl datacenter delete --datacenter-id <DC_ID>

# List all available locations
ionosctl location list

# Get location details
ionosctl location get --location-id de/fra

# List CPU families at a location
ionosctl location cpu-family list --location-id de/fra
```

---

## Servers & Compute

```bash
# List all servers in a datacenter
ionosctl server list --datacenter-id <DC_ID>

# Get server details
ionosctl server get \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# Create a server
ionosctl server create \
  --datacenter-id <DC_ID> \
  --name my-server \
  --cores 4 \
  --ram 8192 \
  --cpu-family AMD_OPTERON

# Start a server
ionosctl server start \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# Stop a server
ionosctl server stop \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# Reboot a server
ionosctl server reboot \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# Delete a server
ionosctl server delete \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# List server NICs
ionosctl nic list \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# Attach an existing volume to a server
ionosctl server volume attach \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID> \
  --volume-id <VOLUME_ID>

# List available server templates
ionosctl template list
```

---

## Storage (Volumes)

```bash
# List all volumes in a datacenter
ionosctl volume list --datacenter-id <DC_ID>

# Create a volume
ionosctl volume create \
  --datacenter-id <DC_ID> \
  --name my-volume \
  --size 50 \
  --type SSD_STANDARD \
  --zone AUTO

# Attach volume to server
ionosctl server volume attach \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID> \
  --volume-id <VOLUME_ID>

# Detach volume from server
ionosctl server volume detach \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID> \
  --volume-id <VOLUME_ID>

# Delete a volume
ionosctl volume delete \
  --datacenter-id <DC_ID> \
  --volume-id <VOLUME_ID>

# Create a snapshot from a volume
ionosctl snapshot create \
  --datacenter-id <DC_ID> \
  --volume-id <VOLUME_ID> \
  --name my-snapshot

# List snapshots
ionosctl snapshot list

# Restore snapshot to a volume
ionosctl volume restore \
  --datacenter-id <DC_ID> \
  --volume-id <VOLUME_ID> \
  --snapshot-id <SNAPSHOT_ID>

# Delete snapshot
ionosctl snapshot delete --snapshot-id <SNAPSHOT_ID>
```

---

## Networking

```bash
# List LANs in a datacenter
ionosctl lan list --datacenter-id <DC_ID>

# Create a public LAN
ionosctl lan create \
  --datacenter-id <DC_ID> \
  --name my-public-lan \
  --public=true

# Create a private LAN
ionosctl lan create \
  --datacenter-id <DC_ID> \
  --name my-private-lan \
  --public=false

# List NICs for a server
ionosctl nic list \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID>

# Create a NIC and attach to LAN
ionosctl nic create \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID> \
  --name eth0 \
  --lan-id <LAN_ID>

# List IP blocks
ionosctl ipblock list

# Reserve an IP block
ionosctl ipblock create \
  --location de/fra \
  --size 1 \
  --name my-ip

# Delete IP block
ionosctl ipblock delete --ipblock-id <IPBLOCK_ID>

# List firewall rules for a NIC
ionosctl firewall-rule list \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID> \
  --nic-id <NIC_ID>

# Create a firewall rule (allow SSH)
ionosctl firewall-rule create \
  --datacenter-id <DC_ID> \
  --server-id <SERVER_ID> \
  --nic-id <NIC_ID> \
  --name allow-ssh \
  --protocol TCP \
  --port-range-start 22 \
  --port-range-end 22 \
  --direction INGRESS
```

---

## Kubernetes (Managed Kubernetes / DCD)

```bash
# List Kubernetes clusters
ionosctl k8s cluster list

# Create a Kubernetes cluster
ionosctl k8s cluster create \
  --name my-cluster \
  --k8s-version 1.30.0

# Get cluster details
ionosctl k8s cluster get --cluster-id <CLUSTER_ID>

# Download kubeconfig
ionosctl k8s kubeconfig get \
  --cluster-id <CLUSTER_ID> \
  --output yaml > ~/.kube/ionos-config.yaml

export KUBECONFIG=~/.kube/ionos-config.yaml
kubectl get nodes

# List node pools
ionosctl k8s nodepool list --cluster-id <CLUSTER_ID>

# Create a node pool
ionosctl k8s nodepool create \
  --cluster-id <CLUSTER_ID> \
  --name my-pool \
  --node-count 3 \
  --cores-count 4 \
  --ram-size 8192 \
  --storage-size 50 \
  --storage-type SSD_STANDARD \
  --datacenter-id <DC_ID>

# Scale a node pool
ionosctl k8s nodepool update \
  --cluster-id <CLUSTER_ID> \
  --nodepool-id <POOL_ID> \
  --node-count 5

# Delete node pool
ionosctl k8s nodepool delete \
  --cluster-id <CLUSTER_ID> \
  --nodepool-id <POOL_ID>

# Delete cluster
ionosctl k8s cluster delete --cluster-id <CLUSTER_ID>

# List available K8s versions
ionosctl k8s version list
```

---

## Load Balancer

```bash
# List Network Load Balancers (NLB)
ionosctl nlb list --datacenter-id <DC_ID>

# Create Network Load Balancer
ionosctl nlb create \
  --datacenter-id <DC_ID> \
  --name my-nlb \
  --listener-lan-id <LAN_ID> \
  --target-lan-id <LAN_ID>

# List NLB forwarding rules
ionosctl nlb rule list \
  --datacenter-id <DC_ID> \
  --nlb-id <NLB_ID>

# Create NLB forwarding rule
ionosctl nlb rule create \
  --datacenter-id <DC_ID> \
  --nlb-id <NLB_ID> \
  --name my-rule \
  --algorithm ROUND_ROBIN \
  --protocol TCP \
  --listener-port 80

# List Application Load Balancers (ALB)
ionosctl alb list --datacenter-id <DC_ID>

# Create Application Load Balancer
ionosctl alb create \
  --datacenter-id <DC_ID> \
  --name my-alb \
  --listener-lan-id <LAN_ID> \
  --target-lan-id <LAN_ID>

# List target groups
ionosctl targetgroup list

# Create a target group
ionosctl targetgroup create \
  --name my-tg \
  --algorithm ROUND_ROBIN \
  --protocol HTTP

# Add target to group
ionosctl targetgroup target add \
  --targetgroup-id <TG_ID> \
  --ip 10.0.0.10 \
  --port 8080 \
  --weight 1
```

---

## Output & Automation

```bash
# Output as JSON (machine-readable)
ionosctl server list --datacenter-id <DC_ID> --output json

# Output as plain text table (default)
ionosctl server list --datacenter-id <DC_ID> --output text

# Remove header from output (for scripting)
ionosctl server list --datacenter-id <DC_ID> --no-headers

# Show only specific columns
ionosctl server list --datacenter-id <DC_ID> \
  --cols "ServerId,Name,State,Cores,Ram"

# Combine with jq for scripting
ionosctl datacenter list --output json | \
  jq -r '.items[] | [.id, .properties.name] | @tsv'

# Get server ID by name
SERVER_ID=$(ionosctl server list \
  --datacenter-id <DC_ID> \
  --output json | \
  jq -r '.items[] | select(.properties.name=="my-server") | .id')
echo "Server ID: $SERVER_ID"

# Wait for a server to reach AVAILABLE state
while true; do
  STATE=$(ionosctl server get \
    --datacenter-id <DC_ID> \
    --server-id <SERVER_ID> \
    --output json | jq -r '.metadata.state')
  [ "$STATE" = "AVAILABLE" ] && break
  echo "State: $STATE – waiting..."
  sleep 5
done
echo "Server is ready!"
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [docs.ionos.com/cloud](https://docs.ionos.com/cloud/) | IONOS Cloud documentation — all products, APIs, tutorials, and architecture guides. |
| **ionosctl Reference** | [docs.ionos.com/cli-ionosctl](https://docs.ionos.com/cli-ionosctl) | Complete `ionosctl` CLI command reference with all resources and parameters. |
| **Terraform Provider (IONOS)** | [registry.terraform.io/ionos-cloud/ionoscloud](https://registry.terraform.io/providers/ionos-cloud/ionoscloud/latest/docs) | Official IONOS Cloud Terraform provider — manages servers, networks, Kubernetes, load balancers, and storage. |
| **OpenTofu Provider (IONOS)** | [search.opentofu.org/ionos-cloud/ionoscloud](https://search.opentofu.org/provider/ionos-cloud/ionoscloud/latest) | IONOS Cloud provider in the OpenTofu registry — same feature set as the Terraform provider. |
