# OCI CLI Cheat Sheet (Oracle Cloud Infrastructure)

## Installation & Setup

```bash
# Installation (macOS via Homebrew)
brew install oci-cli

# Installation (official installer)
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Check version
oci --version

# Setup wizard (interactive, creates ~/.oci/config)
oci setup config

# Manually check config file
cat ~/.oci/config

# List configuration profiles
oci setup repair-file-permissions --file ~/.oci/config

# Show API key fingerprint
oci iam user list-api-keys --user-id <user-ocid>

# Check current identity
oci iam user get --user-id $(oci iam user list --query 'data[0].id' --raw-output)
```

---

## Profile & Tenancies

```bash
# Use default profile (DEFAULT in ~/.oci/config)
oci iam compartment list

# Use alternative profile
oci iam compartment list --profile PROD

# Show Tenancy OCID
oci iam tenancy get --tenancy-id <tenancy-ocid>

# Show all regions
oci iam region list

# Subscribed regions for the tenancy
oci iam region-subscription list --tenancy-id <tenancy-ocid>

# Set region for a session
export OCI_CLI_REGION=eu-frankfurt-1
```

---

## IAM – Compartments & Policies

```bash
# List all compartments (root)
oci iam compartment list --all

# Create compartment
oci iam compartment create \
  --compartment-id <parent-ocid> \
  --name "my-compartment" \
  --description "Description"

# List groups
oci iam group list --all

# Add user to a group
oci iam group add-user \
  --group-id <group-ocid> \
  --user-id <user-ocid>

# List policies
oci iam policy list --compartment-id <compartment-ocid>

# Create policy
oci iam policy create \
  --compartment-id <compartment-ocid> \
  --name "my-policy" \
  --description "Access to Object Storage" \
  --statements '["Allow group Admins to manage object-family in compartment MyCompartment"]'
```

---

## Compute – Instances

```bash
# List instances
oci compute instance list \
  --compartment-id <compartment-ocid> \
  --output table

# Show instance details
oci compute instance get --instance-id <instance-ocid>

# Start instance
oci compute instance action \
  --instance-id <instance-ocid> \
  --action START

# Stop instance
oci compute instance action \
  --instance-id <instance-ocid> \
  --action STOP

# Restart instance
oci compute instance action \
  --instance-id <instance-ocid> \
  --action SOFTRESET

# Terminate instance
oci compute instance terminate \
  --instance-id <instance-ocid>

# List available shapes
oci compute shape list --compartment-id <compartment-ocid>

# List images (Oracle images)
oci compute image list \
  --compartment-id <compartment-ocid> \
  --operating-system "Oracle Linux" \
  --output table

# SSH connection via bastion (Instance Console Connection)
oci compute instance-console-connection create \
  --instance-id <instance-ocid> \
  --public-key-file ~/.ssh/id_rsa.pub
```

---

## VCN – Virtual Cloud Network

```bash
# List VCNs
oci network vcn list --compartment-id <compartment-ocid>

# Create VCN
oci network vcn create \
  --compartment-id <compartment-ocid> \
  --cidr-block "10.0.0.0/16" \
  --display-name "my-vcn"

# List subnets
oci network subnet list --compartment-id <compartment-ocid>

# Create subnet
oci network subnet create \
  --compartment-id <compartment-ocid> \
  --vcn-id <vcn-ocid> \
  --cidr-block "10.0.1.0/24" \
  --display-name "public-subnet"

# Show security lists
oci network security-list list --compartment-id <compartment-ocid>

# Create internet gateway
oci network internet-gateway create \
  --compartment-id <compartment-ocid> \
  --vcn-id <vcn-ocid> \
  --is-enabled true \
  --display-name "my-igw"

# List load balancers
oci lb load-balancer list --compartment-id <compartment-ocid>
```

---

## Object Storage

```bash
# List buckets
oci os bucket list --compartment-id <compartment-ocid>

# Create bucket
oci os bucket create \
  --compartment-id <compartment-ocid> \
  --name "my-bucket" \
  --namespace <namespace>

# Show namespace
oci os ns get

# List objects
oci os object list --bucket-name "my-bucket"

# Upload file
oci os object put \
  --bucket-name "my-bucket" \
  --file ./local-file.txt \
  --name "path/in/bucket/file.txt"

# Download file
oci os object get \
  --bucket-name "my-bucket" \
  --name "path/in/bucket/file.txt" \
  --file ./downloaded.txt

# Delete object
oci os object delete \
  --bucket-name "my-bucket" \
  --name "path/in/bucket/file.txt"

# Bulk upload a directory
oci os object bulk-upload \
  --bucket-name "my-bucket" \
  --src-dir ./my-directory/

# Create Pre-Authenticated Request (PAR)
oci os preauth-request create \
  --bucket-name "my-bucket" \
  --name "my-par" \
  --access-type ObjectRead \
  --time-expires "2026-12-31T23:59:59Z"
```

---

## Database – Autonomous Database (ADB)

```bash
# List Autonomous Databases
oci db autonomous-database list --compartment-id <compartment-ocid>

# Create ADB (ATP)
oci db autonomous-database create \
  --compartment-id <compartment-ocid> \
  --db-name "MYATP" \
  --display-name "My ATP" \
  --cpu-core-count 1 \
  --data-storage-size-in-tbs 1 \
  --admin-password "SecurePass#123" \
  --db-workload ATP

# Start ADB
oci db autonomous-database start --autonomous-database-id <adb-ocid>

# Stop ADB
oci db autonomous-database stop --autonomous-database-id <adb-ocid>

# Download wallet (for connection)
oci db autonomous-database generate-wallet \
  --autonomous-database-id <adb-ocid> \
  --password "WalletPass#1" \
  --file wallet.zip
```

---

## Container Engine (OKE – Kubernetes)

```bash
# List clusters
oci ce cluster list --compartment-id <compartment-ocid>

# Create cluster
oci ce cluster create \
  --compartment-id <compartment-ocid> \
  --name "my-oke-cluster" \
  --vcn-id <vcn-ocid> \
  --kubernetes-version "v1.29.1"

# Load kubeconfig for OKE cluster
oci ce cluster create-kubeconfig \
  --cluster-id <cluster-ocid> \
  --file ~/.kube/config \
  --region eu-frankfurt-1 \
  --token-version 2.0.0

# List node pools
oci ce node-pool list --compartment-id <compartment-ocid>

# Create node pool
oci ce node-pool create \
  --cluster-id <cluster-ocid> \
  --compartment-id <compartment-ocid> \
  --name "worker-pool" \
  --node-shape "VM.Standard.E4.Flex" \
  --kubernetes-version "v1.29.1"
```

---

## Container Registry (OCIR)

```bash
# List repositories
oci artifacts container repository list --compartment-id <compartment-ocid>

# Docker login to OCIR
docker login <region-key>.ocir.io \
  -u "<tenancy-namespace>/<username>" \
  -p "<auth-token>"

# Tag image for OCIR
docker tag my-image:1.0 \
  fra.ocir.io/<namespace>/my-repo/my-image:1.0

# Push image
docker push fra.ocir.io/<namespace>/my-repo/my-image:1.0

# Create auth token (for registry login)
oci iam auth-token create \
  --user-id <user-ocid> \
  --description "OCIR Token"
```

---

## Resource Manager (Terraform)

```bash
# List stacks
oci resource-manager stack list --compartment-id <compartment-ocid>

# Create stack from ZIP
oci resource-manager stack create \
  --compartment-id <compartment-ocid> \
  --display-name "my-stack" \
  --config-source config-source='{"configSourceType":"ZIP_UPLOAD","zipFileBase64Encoded":"'$(base64 terraform.zip)'"}'

# Run plan
oci resource-manager job create-plan-job \
  --stack-id <stack-ocid>

# Run apply
oci resource-manager job create-apply-job \
  --stack-id <stack-ocid> \
  --execution-plan-strategy FROM_LATEST_JOB_OUTPUTS

# Show job log
oci resource-manager job get-job-logs --job-id <job-ocid>
```

---

## Tips & Tricks

```bash
# Output as JSON (default)
oci iam compartment list --output json

# Output as table
oci iam compartment list --output table

# Apply JMESPath query to output
oci compute instance list \
  --compartment-id <compartment-ocid> \
  --query 'data[*].{"Name":"display-name","State":"lifecycle-state"}' \
  --output table

# Output a specific value only (raw)
oci iam compartment list \
  --query 'data[?name==`MyCompartment`].id | [0]' \
  --raw-output

# Enable debug logging
oci --debug iam compartment list ...

# Extend CLI configuration (~/.oci/oci_cli_rc)
echo "[OCI_CLI_SETTINGS]
default_profile=DEFAULT" >> ~/.oci/oci_cli_rc

# Automatic pagination for large result sets
oci iam compartment list --all
```
