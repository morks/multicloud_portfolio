# Google Cloud CLI (gcloud) Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install --cask google-cloud-sdk

# Login (opens browser)
gcloud auth login

# Application Default Credentials (for SDKs/Terraform)
gcloud auth application-default login

# Show current account
gcloud auth list

# Switch account
gcloud config set account my@email.com

# Show active project
gcloud config get-value project

# Switch project
gcloud config set project my-project-id

# Show all configurations
gcloud config list

# Create new configuration (Named Profile)
gcloud config configurations create my-profile

# Activate configuration
gcloud config configurations activate my-profile

# Show CLI version
gcloud version

# Update components
gcloud components update
```

---

## Projects

```bash
# List all projects
gcloud projects list

# Create project
gcloud projects create my-new-project \
  --name "My Project" \
  --organization ORG_ID

# Show project details
gcloud projects describe my-project-id

# Delete project
gcloud projects delete my-project-id

# Link billing account
gcloud billing projects link my-project-id \
  --billing-account 0X0X0X-0X0X0X-0X0X0X
```

---

## Compute Engine – Virtual Machines

```bash
# List all VM instances
gcloud compute instances list

# Create VM
gcloud compute instances create my-vm \
  --zone europe-west3-a \
  --machine-type e2-micro \
  --image-family debian-12 \
  --image-project debian-cloud \
  --boot-disk-size 20GB

# Start / stop / delete VM
gcloud compute instances start my-vm --zone europe-west3-a
gcloud compute instances stop my-vm --zone europe-west3-a
gcloud compute instances delete my-vm --zone europe-west3-a

# Connect via SSH
gcloud compute ssh my-vm --zone europe-west3-a

# SSH via IAP tunnel (without public IP)
gcloud compute ssh my-vm \
  --zone europe-west3-a \
  --tunnel-through-iap

# Show serial console output (debugging)
gcloud compute instances get-serial-port-output my-vm \
  --zone europe-west3-a

# Create a disk snapshot
gcloud compute disks snapshot my-disk \
  --zone europe-west3-a \
  --snapshot-names my-snapshot
```

---

## Network – VPC, Firewall

```bash
# List VPC networks
gcloud compute networks list

# Create VPC
gcloud compute networks create my-network \
  --subnet-mode custom

# Create subnet
gcloud compute networks subnets create my-subnet \
  --network my-network \
  --region europe-west3 \
  --range 10.0.1.0/24

# List firewall rules
gcloud compute firewall-rules list

# Create firewall rule (HTTPS inbound)
gcloud compute firewall-rules create allow-https \
  --network my-network \
  --allow tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow HTTPS inbound"

# Delete firewall rule
gcloud compute firewall-rules delete allow-https

# List external IP addresses
gcloud compute addresses list
```

---

## Cloud Storage (GCS)

```bash
# List all buckets
gcloud storage buckets list

# Create bucket
gcloud storage buckets create gs://my-bucket \
  --location europe-west3 \
  --uniform-bucket-level-access

# List files
gcloud storage ls gs://my-bucket/

# Upload file
gcloud storage cp my-file.txt gs://my-bucket/

# Download file
gcloud storage cp gs://my-bucket/my-file.txt ./

# Sync folder
gcloud storage rsync -r ./local-folder gs://my-bucket/target/

# Delete file/folder
gcloud storage rm gs://my-bucket/my-file.txt

# Show bucket size
gcloud storage du -s gs://my-bucket/

# Delete bucket (must be empty)
gcloud storage buckets delete gs://my-bucket
```

---

## GKE – Google Kubernetes Engine

```bash
# List clusters
gcloud container clusters list

# Create cluster
gcloud container clusters create my-cluster \
  --zone europe-west3-a \
  --num-nodes 2 \
  --machine-type e2-standard-2

# Fetch kubeconfig
gcloud container clusters get-credentials my-cluster \
  --zone europe-west3-a

# Scale cluster
gcloud container clusters resize my-cluster \
  --zone europe-west3-a \
  --num-nodes 3

# Upgrade cluster
gcloud container clusters upgrade my-cluster \
  --zone europe-west3-a

# Delete cluster
gcloud container clusters delete my-cluster --zone europe-west3-a
```

---

## Cloud SQL – Managed Databases

```bash
# List instances
gcloud sql instances list

# Create instance (PostgreSQL)
gcloud sql instances create my-db \
  --database-version POSTGRES_15 \
  --tier db-f1-micro \
  --region europe-west3

# Start / stop instance
gcloud sql instances patch my-db --activation-policy ALWAYS
gcloud sql instances patch my-db --activation-policy NEVER

# Create database
gcloud sql databases create my-schema --instance my-db

# Create backup
gcloud sql backups create --instance my-db

# Connect to instance
gcloud sql connect my-db --user postgres
```

---

## IAM – Permissions

```bash
# Show current IAM policy for a project
gcloud projects get-iam-policy my-project-id

# Assign role to a user
gcloud projects add-iam-policy-binding my-project-id \
  --member="user:max@example.com" \
  --role="roles/compute.admin"

# Remove role
gcloud projects remove-iam-policy-binding my-project-id \
  --member="user:max@example.com" \
  --role="roles/compute.admin"

# Create service account
gcloud iam service-accounts create my-sa \
  --display-name "My Service Account"

# Create service account key (JSON)
gcloud iam service-accounts keys create key.json \
  --iam-account my-sa@my-project-id.iam.gserviceaccount.com

# List all service accounts
gcloud iam service-accounts list
```

---

## Cloud Run – Serverless Containers

```bash
# List services
gcloud run services list

# Deploy container
gcloud run deploy my-service \
  --image gcr.io/my-project/my-image:latest \
  --region europe-west3 \
  --platform managed \
  --allow-unauthenticated

# Fetch service URL
gcloud run services describe my-service \
  --region europe-west3 \
  --format 'value(status.url)'

# Delete service
gcloud run services delete my-service --region europe-west3
```

---

## Useful General Options

```bash
# Output format: json, yaml, text, table, value
gcloud compute instances list --format=table
gcloud compute instances list --format=json
gcloud compute instances list --format="value(name,zone)"

# Filter
gcloud compute instances list --filter="status=RUNNING"
gcloud compute instances list --filter="zone:europe-west3-a"

# Set default zone/region
gcloud config set compute/zone europe-west3-a
gcloud config set compute/region europe-west3

# List all available regions/zones
gcloud compute regions list
gcloud compute zones list

# Enable API (e.g. Compute Engine)
gcloud services enable compute.googleapis.com

# Show enabled APIs
gcloud services list --enabled

# Show logs
gcloud logging read "resource.type=gce_instance" --limit 50

# Help for a command
gcloud compute instances create --help
```
