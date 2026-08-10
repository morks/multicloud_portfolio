# Hetzner Cloud (hcloud) Cheat Sheet

## Installation & Setup

```bash
# Install hcloud CLI via Homebrew (macOS)
brew install hcloud

# Alternative: download binary from GitHub
# https://github.com/hetznercloud/cli/releases

# Check installed version
hcloud version

# Create a new context (project token)
hcloud context create my-project

# Switch to an existing context
hcloud context use my-project

# List all contexts
hcloud context list

# Set token via environment variable instead of context
export HCLOUD_TOKEN="your-api-token-here"

# Show help
hcloud help
hcloud server --help
```

---

## Servers

```bash
# List all servers
hcloud server list

# Create a server (minimal)
hcloud server create \
  --name my-server \
  --image ubuntu-24.04 \
  --type cx22 \
  --location nbg1

# Create a server with SSH key, firewall, network and user-data
hcloud server create \
  --name my-server \
  --image ubuntu-24.04 \
  --type cx22 \
  --location fsn1 \
  --ssh-key my-ssh-key \
  --firewall my-firewall \
  --network my-network \
  --user-data-from-file cloud-init.yaml

# Show server details
hcloud server describe my-server

# Start a server
hcloud server poweron my-server

# Stop a server (graceful)
hcloud server shutdown my-server

# Force stop a server
hcloud server poweroff my-server

# Reboot a server (graceful)
hcloud server reboot my-server

# Hard reset a server
hcloud server reset my-server

# Delete a server
hcloud server delete my-server

# SSH into a server (uses the primary public IP)
hcloud server ssh my-server

# SSH as a specific user
hcloud server ssh -u ubuntu my-server

# Rebuild server with a new image (destructive – all data lost)
hcloud server rebuild --image ubuntu-24.04 my-server

# Rename a server
hcloud server update my-server --name my-server-renamed

# Enable rescue mode (boots into rescue system)
hcloud server enable-rescue --type linux64 --ssh-key my-ssh-key my-server

# Disable rescue mode
hcloud server disable-rescue my-server

# Get public IPs of a server
hcloud server ip my-server

# Enable automatic backups (daily snapshot)
hcloud server enable-backup my-server

# Disable automatic backups
hcloud server disable-backup my-server

# Change server type (resize – server must be powered off first)
hcloud server poweroff my-server
hcloud server change-type --server-type cx32 my-server
hcloud server poweron my-server

# Add labels to a server
hcloud server add-label my-server env=production

# Remove labels from a server
hcloud server remove-label my-server env

# List servers filtered by label
hcloud server list --selector env=production
```

---

## Server Types & Images

```bash
# List all available server types
hcloud server-type list

# Show details for a specific server type
hcloud server-type describe cx22

# List all available images (OS images, app images, snapshots, backups)
hcloud image list

# List only system images (OS images)
hcloud image list --type system

# List only snapshot images
hcloud image list --type snapshot

# List only backup images
hcloud image list --type backup

# List all available locations (regions)
hcloud location list

# Show details for a specific location
hcloud location describe nbg1

# List all datacenters
hcloud datacenter list

# Show details for a specific datacenter
hcloud datacenter describe nbg1-dc3
```

---

## Networks & Firewalls

```bash
# ── Networks ─────────────────────────────────────────────────────────────────

# List all networks
hcloud network list

# Create a private network
hcloud network create --name my-network --ip-range 10.0.0.0/16

# Add a subnet to a network
hcloud network add-subnet my-network \
  --type cloud \
  --network-zone eu-central \
  --ip-range 10.0.1.0/24

# Show network details
hcloud network describe my-network

# Attach a server to a network
hcloud server attach-to-network my-server \
  --network my-network \
  --ip 10.0.1.10

# Detach a server from a network
hcloud server detach-from-network my-server --network my-network

# Delete a network
hcloud network delete my-network

# ── Firewalls ─────────────────────────────────────────────────────────────────

# List all firewalls
hcloud firewall list

# Create a firewall
hcloud firewall create --name my-firewall

# Add an inbound rule (allow SSH from anywhere)
hcloud firewall add-rule my-firewall \
  --direction in \
  --protocol tcp \
  --port 22 \
  --source-ips 0.0.0.0/0 \
  --source-ips ::/0

# Add an inbound rule (allow HTTPS from anywhere)
hcloud firewall add-rule my-firewall \
  --direction in \
  --protocol tcp \
  --port 443 \
  --source-ips 0.0.0.0/0 \
  --source-ips ::/0

# Add an outbound rule (allow all outbound TCP)
hcloud firewall add-rule my-firewall \
  --direction out \
  --protocol tcp \
  --port 1-65535 \
  --destination-ips 0.0.0.0/0

# Apply firewall to a server
hcloud firewall apply-to-resource my-firewall \
  --type server \
  --server my-server

# Apply firewall to all servers with a label
hcloud firewall apply-to-resource my-firewall \
  --type label_selector \
  --label-selector env=production

# Remove firewall from a server
hcloud firewall remove-from-resource my-firewall \
  --type server \
  --server my-server

# Show firewall details (rules + applied resources)
hcloud firewall describe my-firewall

# Delete a firewall
hcloud firewall delete my-firewall
```

---

## Load Balancers

```bash
# List all load balancers
hcloud load-balancer list

# Create a load balancer
hcloud load-balancer create \
  --name my-lb \
  --type lb11 \
  --location nbg1

# Show load balancer details
hcloud load-balancer describe my-lb

# Add a server as a target
hcloud load-balancer add-target my-lb \
  --type server \
  --server my-server

# Add all servers matching a label as targets
hcloud load-balancer add-target my-lb \
  --type label_selector \
  --label-selector env=production

# Remove a target
hcloud load-balancer remove-target my-lb \
  --type server \
  --server my-server

# Add a service (HTTP on port 80 → backend port 8080)
hcloud load-balancer add-service my-lb \
  --protocol http \
  --listen-port 80 \
  --destination-port 8080

# Add a service (HTTPS with TLS termination)
hcloud load-balancer add-service my-lb \
  --protocol https \
  --listen-port 443 \
  --destination-port 8080 \
  --http-certificates my-certificate

# Update a service
hcloud load-balancer update-service my-lb \
  --listen-port 80 \
  --destination-port 9090

# Remove a service
hcloud load-balancer delete-service my-lb --listen-port 80

# Enable the public interface
hcloud load-balancer enable-public-interface my-lb

# Disable the public interface (private network only)
hcloud load-balancer disable-public-interface my-lb

# Attach load balancer to a private network
hcloud load-balancer attach-to-network my-lb \
  --network my-network \
  --ip 10.0.1.100

# Detach from network
hcloud load-balancer detach-from-network my-lb --network my-network

# Change load balancer type (resize)
hcloud load-balancer change-type my-lb --load-balancer-type lb21

# Delete a load balancer
hcloud load-balancer delete my-lb
```

---

## Volumes

```bash
# List all volumes
hcloud volume list

# Create a volume (size in GB)
hcloud volume create \
  --name my-volume \
  --size 50 \
  --location nbg1

# Create a volume and immediately attach it to a server
hcloud volume create \
  --name my-volume \
  --size 50 \
  --server my-server

# Show volume details
hcloud volume describe my-volume

# Attach an existing volume to a server
hcloud volume attach my-volume --server my-server

# Detach a volume from a server
hcloud volume detach my-volume

# Resize a volume (only upward; server does not need to be stopped)
hcloud volume resize my-volume --size 100

# Delete a volume
hcloud volume delete my-volume

# ── Format & Mount (via cloud-init user-data) ─────────────────────────────────
# Include this in your --user-data-from-file cloud-init.yaml:
#
# #cloud-config
# disk_setup:
#   /dev/disk/by-id/scsi-0HC_Volume_<volume-id>:
#     table_type: gpt
#     layout: true
#     overwrite: false
# fs_setup:
#   - device: /dev/disk/by-id/scsi-0HC_Volume_<volume-id>
#     filesystem: ext4
# mounts:
#   - [/dev/disk/by-id/scsi-0HC_Volume_<volume-id>, /mnt/data, ext4, "defaults,nofail", 0, 0]
```

---

## SSH Keys

```bash
# List all SSH keys
hcloud ssh-key list

# Add a new SSH key from a public key file
hcloud ssh-key create \
  --name my-ssh-key \
  --public-key-from-file ~/.ssh/id_ed25519.pub

# Add a new SSH key from a string
hcloud ssh-key create \
  --name my-ssh-key \
  --public-key "ssh-ed25519 AAAAC3... user@host"

# Show SSH key details
hcloud ssh-key describe my-ssh-key

# Update SSH key name/labels
hcloud ssh-key update my-ssh-key --name my-ssh-key-renamed

# Delete an SSH key
hcloud ssh-key delete my-ssh-key
```

---

## Floating IPs

```bash
# List all floating IPs
hcloud floating-ip list

# Create a floating IP (IPv4, located in Nuremberg)
hcloud floating-ip create \
  --type ipv4 \
  --home-location nbg1 \
  --name my-floating-ip

# Create a floating IP (IPv6)
hcloud floating-ip create \
  --type ipv6 \
  --home-location nbg1 \
  --name my-floating-ipv6

# Show floating IP details
hcloud floating-ip describe my-floating-ip

# Assign a floating IP to a server
hcloud floating-ip assign my-floating-ip my-server

# Unassign a floating IP (makes it available again)
hcloud floating-ip unassign my-floating-ip

# Update floating IP (rename or add labels)
hcloud floating-ip update my-floating-ip --name my-floating-ip-renamed

# Delete a floating IP
hcloud floating-ip delete my-floating-ip
```

---

## Snapshots & Backups

```bash
# Create a manual snapshot from a running or stopped server
hcloud server create-image \
  --type snapshot \
  --description "my-server before upgrade" \
  my-server

# List all snapshots
hcloud image list --type snapshot

# List all backups
hcloud image list --type backup

# Show details of a snapshot or backup
hcloud image describe <image-id>

# Rebuild a server from a snapshot (destructive – all data lost)
hcloud server rebuild --image <image-id> my-server

# Update snapshot (rename, labels)
hcloud image update <image-id> --description "clean base image"

# Delete a snapshot
hcloud image delete <image-id>

# Share a snapshot with another Hetzner project (read-only)
hcloud image change-protection <image-id> --delete

# List images sorted by creation date
hcloud image list --type snapshot --output columns=id,name,description,created
```

---

## Kubernetes (Self-Managed on Hetzner)

```bash
# Note: Hetzner does not offer a managed Kubernetes service (HKS) via hcloud CLI.
# Recommended approach: use hetzner-k3s (open-source tool) or
# the Hetzner Cloud Controller Manager (CCM) with kubeadm/k3s.

# ── hetzner-k3s (community tool) ─────────────────────────────────────────────
# https://github.com/vitobotta/hetzner-k3s

# Install hetzner-k3s
brew install hetzner-k3s

# Generate a sample config
hetzner-k3s releases

# Create cluster from config file
hetzner-k3s create --config cluster.yaml

# Delete cluster
hetzner-k3s delete --config cluster.yaml

# Example cluster.yaml structure:
# ---
# hetzner_token: <HCLOUD_TOKEN>
# cluster_name: my-cluster
# kubeconfig_path: ~/.kube/my-cluster.yaml
# k3s_version: v1.30.2+k3s1
# networking:
#   ssh:
#     port: 22
#     use_agent: false
#     public_key_path: ~/.ssh/id_ed25519.pub
#     private_key_path: ~/.ssh/id_ed25519
#   allowed_networks:
#     ssh:
#       - 0.0.0.0/0
#   public_network:
#     ipv4: true
#     ipv6: true
# masters:
#   instance_type: cx22
#   instance_count: 3
#   location: nbg1
#   image: ubuntu-24.04
# worker_node_pools:
#   - name: worker-pool
#     instance_type: cx32
#     instance_count: 3
#     location: nbg1
#     image: ubuntu-24.04

# ── Typical manual node setup (hcloud + k3s) ──────────────────────────────────

# Create master node server
hcloud server create \
  --name my-cluster-master-1 \
  --image ubuntu-24.04 \
  --type cx22 \
  --location nbg1 \
  --ssh-key my-ssh-key \
  --network my-network \
  --label role=master \
  --label cluster=my-cluster

# Create worker node servers
hcloud server create \
  --name my-cluster-worker-1 \
  --image ubuntu-24.04 \
  --type cx32 \
  --location nbg1 \
  --ssh-key my-ssh-key \
  --network my-network \
  --label role=worker \
  --label cluster=my-cluster

# Install k3s on master (run on the server via SSH)
# curl -sfL https://get.k3s.io | sh -

# Join workers using the node token from /var/lib/rancher/k3s/server/node-token
# curl -sfL https://get.k3s.io | K3S_URL=https://<master-ip>:6443 K3S_TOKEN=<node-token> sh -

# List all nodes belonging to the cluster
hcloud server list --selector cluster=my-cluster
```

---

## DNS (Hetzner DNS API)

```bash
# Note: Hetzner DNS has a separate API and token from hcloud.
# Get your DNS token at: https://dns.hetzner.com/settings/api-token
export HETZNER_DNS_TOKEN="your-dns-api-token-here"

# ── Zones ─────────────────────────────────────────────────────────────────────

# List all DNS zones
curl -s -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/zones | jq '.zones[] | {id, name}'

# Create a DNS zone
curl -s -X POST \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "example.com", "ttl": 86400}' \
  https://dns.hetzner.com/api/v1/zones | jq '.zone.id'

# Get details of a specific zone
export ZONE_ID="your-zone-id"
curl -s -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/zones/$ZONE_ID | jq '.zone'

# Delete a DNS zone
curl -s -X DELETE \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/zones/$ZONE_ID

# ── Records ────────────────────────────────────────────────────────────────────

# List all records in a zone
curl -s -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  "https://dns.hetzner.com/api/v1/records?zone_id=$ZONE_ID" \
  | jq '.records[] | {id, name, type, value}'

# Create an A record
curl -s -X POST \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"zone_id\": \"$ZONE_ID\", \"type\": \"A\", \"name\": \"www\", \"value\": \"1.2.3.4\", \"ttl\": 300}" \
  https://dns.hetzner.com/api/v1/records | jq '.record.id'

# Create a CNAME record
curl -s -X POST \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"zone_id\": \"$ZONE_ID\", \"type\": \"CNAME\", \"name\": \"blog\", \"value\": \"www.example.com.\", \"ttl\": 300}" \
  https://dns.hetzner.com/api/v1/records

# Update a record
export RECORD_ID="your-record-id"
curl -s -X PUT \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"zone_id\": \"$ZONE_ID\", \"type\": \"A\", \"name\": \"www\", \"value\": \"5.6.7.8\", \"ttl\": 300}" \
  https://dns.hetzner.com/api/v1/records/$RECORD_ID

# Delete a record
curl -s -X DELETE \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/records/$RECORD_ID
```

---

## Tips & Tricks

```bash
# ── JSON output & jq ──────────────────────────────────────────────────────────

# Output as JSON and pipe to jq
hcloud server list --output json | jq '.[] | {id, name, status, public_net}'

# Get just the public IPv4 of a specific server
hcloud server describe my-server --output json | jq -r '.public_net.ipv4.ip'

# Get all server names and their status
hcloud server list --output json | jq -r '.[] | "\(.name): \(.status)"'

# List servers with their private IPs in a network
hcloud server list --output json \
  | jq -r '.[] | "\(.name): \(.private_net[0].ip // "no private IP")"'

# ── Label-based filtering ─────────────────────────────────────────────────────

# List servers with a specific label value
hcloud server list --selector env=production

# List servers that have a label key (any value)
hcloud server list --selector env

# Combine multiple labels
hcloud server list --selector env=production,role=worker

# Apply a firewall to all production servers
hcloud firewall apply-to-resource my-firewall \
  --type label_selector \
  --label-selector env=production

# ── Cloud-Init user-data example ──────────────────────────────────────────────

# Save as cloud-init.yaml and use with --user-data-from-file
cat > cloud-init.yaml << 'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - curl
  - git
  - htop
  - ufw
runcmd:
  - ufw allow OpenSSH
  - ufw --force enable
  - echo "Hello from cloud-init" > /var/log/bootstrap.log
users:
  - name: deploy
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... your-public-key
EOF

hcloud server create \
  --name my-server \
  --image ubuntu-24.04 \
  --type cx22 \
  --location nbg1 \
  --ssh-key my-ssh-key \
  --user-data-from-file cloud-init.yaml

# ── HCLOUD_TOKEN environment variable ────────────────────────────────────────

# Set token for the current shell session (bypasses context)
export HCLOUD_TOKEN="your-api-token-here"

# Useful in CI/CD pipelines (GitHub Actions example):
# env:
#   HCLOUD_TOKEN: ${{ secrets.HCLOUD_TOKEN }}

# ── Output columns ────────────────────────────────────────────────────────────

# Customize the columns shown in list commands
hcloud server list --output columns=id,name,status,ipv4,datacenter

# Available columns vary per resource – check with:
hcloud server list --help

# ── Polling & scripting ────────────────────────────────────────────────────────

# Wait until a server is running before SSHing in
until hcloud server describe my-server --output json | jq -e '.status == "running"' > /dev/null 2>&1; do
  echo "Waiting for server to start..."
  sleep 5
done
echo "Server is running!"
hcloud server ssh my-server

# Get the ID of a server by name (useful for scripting)
SERVER_ID=$(hcloud server list --output json | jq -r '.[] | select(.name=="my-server") | .id')
echo "Server ID: $SERVER_ID"

# ── Context management in scripts ────────────────────────────────────────────

# Create a context non-interactively (pipe the token)
echo "$HCLOUD_TOKEN" | hcloud context create my-project

# Show current active context
hcloud context list | grep "^\*"
```
