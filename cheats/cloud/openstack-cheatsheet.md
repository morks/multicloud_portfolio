# OpenStack CLI Cheat Sheet

> Generic OpenStack reference for self-hosted, private cloud, and any OpenStack-compatible environment.
> Covers the unified `openstack` client (python-openstackclient) and individual service CLIs.
> For Telekom / Open Telekom Cloud (OTC) specifics see `ctc-cheatsheet.md`.

## Installation & Setup

```bash
# Install the unified OpenStack client
pip install python-openstackclient

# Install individual service clients (optional extras)
pip install python-cinderclient    # Block Storage (Cinder)
pip install python-neutronclient   # Networking (Neutron)
pip install python-heatclient      # Orchestration (Heat)
pip install python-designateclient # DNS (Designate)
pip install python-manilaclient    # Shared File Systems (Manila)
pip install python-ironicclient    # Bare Metal (Ironic)
pip install python-swiftclient     # Object Storage (Swift)

# Install all at once
pip install python-openstackclient python-cinderclient \
  python-neutronclient python-heatclient python-designateclient \
  python-manilaclient python-ironicclient python-swiftclient

# Verify installation
openstack --version

# Source an openrc.sh file downloaded from the Horizon dashboard
source ~/Downloads/my-project-openrc.sh

# Or point to a specific cloud in clouds.yaml
export OS_CLOUD=my-cloud

# List the service catalog (verify connectivity and auth)
openstack catalog list
```

### clouds.yaml format

```yaml
# ~/.config/openstack/clouds.yaml  (or /etc/openstack/clouds.yaml)
clouds:
  my-cloud:
    auth:
      auth_url: https://keystone.example.com:5000/v3
      project_name: my-project
      project_domain_name: Default
      username: my-user
      password: secret
      user_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3

  my-cloud-admin:
    auth:
      auth_url: https://keystone.example.com:5000/v3
      project_name: admin
      project_domain_name: Default
      username: admin
      password: supersecret
      user_domain_name: Default
    region_name: RegionOne
    interface: internal
    identity_api_version: 3
```

```bash
# Select cloud from clouds.yaml at runtime
openstack --os-cloud my-cloud server list

# Or export for the session
export OS_CLOUD=my-cloud
```

---

## Authentication & Identity (Keystone)

```bash
# Issue a token (verify that auth works)
openstack token issue

# Show token details as JSON
openstack token issue -f json | jq .

# Revoke a token
openstack token revoke <token-id>

# --- Projects ---
# List all projects visible to the current user
openstack project list

# Show details of a specific project
openstack project show my-project

# Create a project
openstack project create --domain Default --description "Dev workload" my-project

# Enable / disable a project
openstack project set --enable my-project
openstack project set --disable my-project

# Delete a project
openstack project delete my-project

# --- Users ---
# List users (requires admin rights)
openstack user list

# Create a user
openstack user create \
  --domain Default \
  --password changeme \
  --email user@example.com \
  my-user

# Set / change password
openstack user set --password newpassword my-user

# Delete a user
openstack user delete my-user

# --- Roles ---
# List all roles
openstack role list

# Assign a role to a user in a project
openstack role add --project my-project --user my-user member

# List role assignments
openstack role assignment list --project my-project --names

# Remove a role
openstack role remove --project my-project --user my-user member

# --- Domains ---
openstack domain list
openstack domain create my-domain
openstack domain show Default

# --- Application Credentials ---
# Create an application credential (non-interactive service auth)
openstack application credential create \
  --secret mysecret \
  --expiration "2027-01-01T00:00:00" \
  my-app-cred

# List application credentials
openstack application credential list

# Delete an application credential
openstack application credential delete my-app-cred

# --- EC2 Credentials (S3-compatible access) ---
openstack ec2 credentials create
openstack ec2 credentials list
openstack ec2 credentials show <access-key>
openstack ec2 credentials delete <access-key>
```

---

## Compute (Nova)

```bash
# --- Instances ---
# List running instances
openstack server list

# List all instances with extra details (host, flavor, image)
openstack server list --long

# Show details of a specific instance
openstack server show my-instance

# Create an instance (minimal)
openstack server create \
  --image ubuntu-22.04 \
  --flavor m1.small \
  --network my-network \
  --key-name my-keypair \
  my-instance

# Create with security group, user-data and availability zone
openstack server create \
  --image ubuntu-22.04 \
  --flavor m1.medium \
  --network my-network \
  --key-name my-keypair \
  --security-group my-sg \
  --availability-zone nova-az1 \
  --user-data cloud-init.yaml \
  my-instance

# Create multiple instances at once
openstack server create \
  --image ubuntu-22.04 \
  --flavor m1.small \
  --network my-network \
  --min 3 --max 3 \
  my-instance

# Start / stop / reboot an instance
openstack server start my-instance
openstack server stop my-instance
openstack server reboot my-instance             # soft reboot
openstack server reboot --hard my-instance      # hard reset

# Delete an instance
openstack server delete my-instance

# --- Lifecycle: resize, migrate, shelve ---
# Resize to a different flavor
openstack server resize --flavor m1.large my-instance
openstack server resize confirm my-instance     # confirm after verification
openstack server resize revert my-instance      # roll back

# Cold migrate (moves to a different host, instance stops)
openstack server migrate my-instance
openstack server migrate --host compute02 my-instance

# Live migrate (instance keeps running)
openstack server migrate --live-migration my-instance
openstack server migrate --live-migration --host compute03 my-instance

# Shelve (free compute resources, keep disk)
openstack server shelve my-instance
openstack server unshelve my-instance

# --- Console access ---
# Get VNC console URL
openstack console url show --type novnc my-instance

# Get SPICE console URL
openstack console url show --type spice-html5 my-instance

# Read the serial console log
openstack console log show my-instance
openstack console log show --lines 50 my-instance

# --- Instance metadata ---
openstack server set --property env=prod --property owner=ops my-instance
openstack server unset --property env my-instance

# --- Keypairs ---
openstack keypair list
openstack keypair create my-keypair > my-keypair.pem
chmod 400 my-keypair.pem
openstack keypair create --public-key ~/.ssh/id_ed25519.pub my-keypair
openstack keypair show my-keypair
openstack keypair delete my-keypair

# --- Flavors ---
openstack flavor list
openstack flavor list --public
openstack flavor show m1.medium
openstack flavor create \
  --vcpus 4 --ram 8192 --disk 50 \
  --public \
  m1.custom

# --- Server Groups (affinity / anti-affinity) ---
openstack server group create --policy anti-affinity my-server-group
openstack server group list
openstack server group show my-server-group
openstack server create \
  --hint group=<server-group-id> \
  --image ubuntu-22.04 --flavor m1.small --network my-network \
  my-instance
openstack server group delete my-server-group

# --- Hypervisors ---
openstack hypervisor list
openstack hypervisor show compute01
openstack hypervisor stats show

# --- Host Aggregates ---
openstack aggregate list
openstack aggregate create --zone my-az my-aggregate
openstack aggregate add host my-aggregate compute01
openstack aggregate set --property ssd=true my-aggregate
openstack aggregate show my-aggregate
openstack aggregate delete my-aggregate
```

---

## Images (Glance)

```bash
# List images
openstack image list
openstack image list --status active
openstack image list --private

# Show image details
openstack image show ubuntu-22.04

# Upload a local image file
openstack image create \
  --file ubuntu-22.04-server-cloudimg-amd64.img \
  --disk-format qcow2 \
  --container-format bare \
  --public \
  ubuntu-22.04

# Upload with properties
openstack image create \
  --file debian-12.qcow2 \
  --disk-format qcow2 \
  --container-format bare \
  --min-disk 10 \
  --min-ram 512 \
  --property hw_firmware_type=uefi \
  --property os_type=linux \
  --public \
  debian-12

# Download an image to a local file
openstack image save --file downloaded.qcow2 <image-id>

# Set image properties after upload
openstack image set --property os_distro=ubuntu my-image
openstack image set --protected my-image        # prevent accidental deletion
openstack image set --unprotected my-image

# Deactivate / reactivate an image
openstack image set --deactivate my-image
openstack image set --activate my-image

# Delete an image
openstack image delete my-image

# --- Sharing images across projects ---
# Share an image with another project
openstack image add project my-image <target-project-id>

# Accept a shared image (run in the target project)
openstack image set --accept <image-id>

# List members of an image
openstack image member list my-image

# Remove a project from image members
openstack image remove project my-image <target-project-id>
```

---

## Networking (Neutron)

```bash
# --- Networks ---
openstack network list
openstack network show my-network
openstack network create --share my-network
openstack network create \
  --provider-network-type vxlan \
  my-vxlan-network
openstack network delete my-network

# Create a provider network (admin only)
openstack network create \
  --external \
  --provider-network-type vlan \
  --provider-physical-network physnet1 \
  --provider-segment 100 \
  my-provider-network

# --- Subnets ---
openstack subnet list
openstack subnet show my-subnet
openstack subnet create \
  --network my-network \
  --subnet-range 10.0.1.0/24 \
  --gateway 10.0.1.1 \
  --dns-nameserver 8.8.8.8 \
  --dns-nameserver 8.8.4.4 \
  my-subnet
openstack subnet set --dns-nameserver 1.1.1.1 my-subnet
openstack subnet delete my-subnet

# --- Routers ---
openstack router list
openstack router create my-router
openstack router set --external-gateway my-provider-network my-router
openstack router add subnet my-router my-subnet
openstack router remove subnet my-router my-subnet
openstack router delete my-router

# --- Ports ---
openstack port list
openstack port list --network my-network
openstack port show <port-id>
openstack port create \
  --network my-network \
  --fixed-ip subnet=my-subnet,ip-address=10.0.1.50 \
  my-port
openstack port set --no-security-group --disable-port-security my-port
openstack port delete my-port

# --- Floating IPs ---
openstack floating ip list
openstack floating ip create my-provider-network
openstack floating ip show <floating-ip>
openstack server add floating ip my-instance <floating-ip>
openstack server remove floating ip my-instance <floating-ip>
openstack floating ip delete <floating-ip>

# --- Security Groups & Rules ---
openstack security group list
openstack security group create --description "Web + SSH" my-sg
openstack security group rule list my-sg

# Allow SSH from anywhere
openstack security group rule create \
  --protocol tcp --dst-port 22 \
  --remote-ip 0.0.0.0/0 \
  my-sg

# Allow HTTPS from a specific CIDR
openstack security group rule create \
  --protocol tcp --dst-port 443 \
  --remote-ip 10.0.0.0/8 \
  my-sg

# Allow ICMP (ping)
openstack security group rule create \
  --protocol icmp \
  my-sg

# Allow all traffic from another security group
openstack security group rule create \
  --protocol tcp \
  --remote-group my-sg \
  my-sg

openstack security group rule delete <rule-id>
openstack security group delete my-sg

# --- Load Balancers (Octavia) ---
openstack loadbalancer list
openstack loadbalancer create \
  --name my-lb \
  --vip-subnet-id my-subnet
openstack loadbalancer show my-lb

# Create listener
openstack loadbalancer listener create \
  --name my-listener \
  --protocol HTTP --protocol-port 80 \
  my-lb

# Create pool
openstack loadbalancer pool create \
  --name my-pool \
  --lb-algorithm ROUND_ROBIN \
  --listener my-listener \
  --protocol HTTP

# Add members to pool
openstack loadbalancer member create \
  --subnet-id my-subnet \
  --address 10.0.1.10 \
  --protocol-port 8080 \
  my-pool

# Create health monitor
openstack loadbalancer healthmonitor create \
  --delay 5 --timeout 3 --max-retries 3 \
  --type HTTP --url-path /healthz \
  my-pool

openstack loadbalancer delete --cascade my-lb

# --- Trunk Ports ---
openstack network trunk create \
  --parent-port my-port \
  my-trunk
openstack network trunk set \
  --subport port=<subport-id>,segmentation-type=vlan,segmentation-id=100 \
  my-trunk
openstack network trunk list

# --- QoS Policies ---
openstack network qos policy create my-qos
openstack network qos rule create \
  --type bandwidth-limit \
  --max-kbps 10000 --max-burst-kbps 15000 \
  --egress \
  my-qos
openstack port set --qos-policy my-qos my-port

# --- Network Agents ---
openstack network agent list
openstack network agent show <agent-id>
```

---

## Block Storage (Cinder)

```bash
# --- Volumes ---
openstack volume list
openstack volume show my-volume
openstack volume create --size 50 my-volume

# Create with type and availability zone
openstack volume create \
  --size 100 \
  --type ceph-ssd \
  --availability-zone nova-az1 \
  --description "App data disk" \
  my-volume

# Create a bootable volume from an image
openstack volume create \
  --size 30 \
  --image ubuntu-22.04 \
  --bootable \
  my-boot-volume

# Boot an instance directly from a volume
openstack server create \
  --volume my-boot-volume \
  --flavor m1.medium \
  --network my-network \
  --key-name my-keypair \
  my-instance

# Attach / detach a volume
openstack server add volume my-instance my-volume
openstack server remove volume my-instance my-volume

# Extend a volume (must be detached or in-use depending on backend)
openstack volume set --size 200 my-volume

# Set volume to bootable / non-bootable
openstack volume set --bootable my-volume
openstack volume set --non-bootable my-volume

# Delete a volume
openstack volume delete my-volume

# --- Volume Types ---
openstack volume type list
openstack volume type show ceph-ssd
openstack volume type create \
  --property volume_backend_name=ceph_ssd \
  ceph-ssd
openstack volume type delete ceph-ssd

# --- Snapshots ---
openstack volume snapshot list
openstack volume snapshot create --volume my-volume my-snapshot
openstack volume snapshot show my-snapshot
openstack volume create --snapshot my-snapshot --size 50 my-restored-volume
openstack volume snapshot delete my-snapshot

# --- Backups ---
openstack volume backup list
openstack volume backup create --name my-backup my-volume
openstack volume backup restore my-backup my-restored-volume
openstack volume backup delete my-backup

# --- Volume Transfers (between projects) ---
openstack volume transfer request create my-volume
# (sends transfer ID + auth key to recipient)
openstack volume transfer request list
openstack volume transfer request accept <transfer-id> --auth-key <auth-key>
openstack volume transfer request delete <transfer-id>
```

---

## Object Storage (Swift)

```bash
# Show account statistics
swift stat

# --- Containers ---
openstack container list
openstack container create my-container
swift stat my-container
openstack container show my-container
openstack container delete my-container      # must be empty

# --- Objects ---
openstack object list my-container
openstack object create my-container local-file.txt
openstack object show my-container local-file.txt
openstack object save my-container local-file.txt   # download to cwd
openstack object save --file /tmp/downloaded.txt my-container local-file.txt
openstack object delete my-container local-file.txt

# --- Bulk operations with swift CLI ---
# Upload an entire directory
swift upload my-container /path/to/local/dir/

# Download all objects in a container
swift download my-container

# Upload multiple files with a prefix
swift upload my-container *.log --object-name logs/

# --- Metadata ---
swift post my-container --meta "Project:blue" --meta "Env:prod"
swift post my-container my-object.txt --meta "Author:ops-team"
swift stat my-container my-object.txt

# --- Access Control (ACLs) ---
# Make container publicly readable
swift post -r '.r:*' my-container

# Grant read access to a specific account
swift post -r '<account>:<user>' my-container

# Grant write access
swift post -w '<account>:<user>' my-container

# --- Temp URLs (time-limited public links) ---
# Set the temp-URL key on the account (one-time admin setup)
swift post -m "Temp-URL-Key:my-secret-key"

# Generate a GET temp URL valid for 3600 seconds
swift tempurl GET 3600 /v1/<account>/my-container/my-object.txt my-secret-key

# --- Large Objects ---
# Static Large Object (SLO) – recommended
swift upload my-container large-file.iso --use-slo --segment-size 500M

# Dynamic Large Object (DLO) – older method
swift upload my-container large-file.iso --segment-size 500M
```

---

## Orchestration (Heat)

```bash
# --- Stacks ---
openstack stack list
openstack stack show my-stack

# Create a stack from a template
openstack stack create \
  --template my-template.yaml \
  --parameter key_name=my-keypair \
  --parameter flavor=m1.medium \
  my-stack

# Create with an environment file
openstack stack create \
  --template my-template.yaml \
  --environment my-env.yaml \
  my-stack

# Preview a stack (dry-run, shows what would be created)
openstack stack preview \
  --template my-template.yaml \
  my-stack

# Update a running stack
openstack stack update \
  --template my-template.yaml \
  --existing \
  my-stack

# Cancel an in-progress update
openstack stack cancel my-stack

# Suspend / resume a stack
openstack stack suspend my-stack
openstack stack resume my-stack

# Delete a stack
openstack stack delete my-stack
openstack stack delete --yes my-stack        # skip confirmation

# --- Outputs, Events, Resources ---
openstack stack output list my-stack
openstack stack output show my-stack <output-key>

openstack stack event list my-stack
openstack stack event list --nested-depth 2 my-stack

openstack stack resource list my-stack
openstack stack resource show my-stack <resource-name>

# --- Template validation ---
openstack orchestration template validate --template my-template.yaml

# --- Environment ---
openstack stack environment show my-stack

# Minimal HOT template structure
cat <<'EOF'
heat_template_version: 2021-04-16

description: Example HOT template

parameters:
  key_name:
    type: string
    description: SSH key name
  flavor:
    type: string
    default: m1.small

resources:
  my_instance:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: key_name }
      image: ubuntu-22.04
      flavor: { get_param: flavor }
      networks:
        - network: my-network

outputs:
  instance_ip:
    value: { get_attr: [my_instance, first_address] }
EOF
```

---

## DNS (Designate)

```bash
# --- Zones ---
openstack zone list
openstack zone show example.com.

# Create a primary zone
openstack zone create \
  --email admin@example.com \
  --ttl 3600 \
  --description "Primary zone" \
  example.com.

# Create a secondary zone (slave)
openstack zone create \
  --type SECONDARY \
  --masters 192.168.1.1 \
  secondary.example.com.

openstack zone delete example.com.

# --- Recordsets ---
openstack recordset list example.com.

# Create an A record
openstack recordset create \
  --type A --ttl 300 \
  --record 203.0.113.42 \
  example.com. www

# Create an MX record
openstack recordset create \
  --type MX --ttl 3600 \
  --record "10 mail.example.com." \
  example.com. @

# Create a CNAME record
openstack recordset create \
  --type CNAME --ttl 300 \
  --record www.example.com. \
  example.com. blog

# Show / update / delete a recordset
openstack recordset show example.com. <recordset-id>
openstack recordset set --ttl 600 example.com. <recordset-id>
openstack recordset delete example.com. <recordset-id>

# --- Zone Transfer (move a zone to another project) ---
openstack zone transfer request create \
  --target-project-id <project-id> \
  example.com.
openstack zone transfer accept create \
  --transfer-id <transfer-id> \
  --key <transfer-key>
```

---

## Bare Metal (Ironic)

```bash
# --- Nodes ---
openstack baremetal node list
openstack baremetal node show my-node

# Create a node
openstack baremetal node create \
  --driver ipmi \
  --driver-info ipmi_address=192.168.0.200 \
  --driver-info ipmi_username=admin \
  --driver-info ipmi_password=secret \
  --property memory_mb=65536 \
  --property cpus=32 \
  --property local_gb=480 \
  --name my-node

# Manage / provide a node (make it available for provisioning)
openstack baremetal node manage my-node
openstack baremetal node provide my-node

# Clean a node (wipe disks, run automated cleaning steps)
openstack baremetal node clean \
  --clean-steps '[{"interface":"deploy","step":"erase_devices_metadata","priority":10}]' \
  my-node

# Power control
openstack baremetal node power on my-node
openstack baremetal node power off my-node
openstack baremetal node reboot my-node

# Delete a node
openstack baremetal node delete my-node

# --- Ports (NIC) ---
openstack baremetal port list
openstack baremetal port create \
  --node my-node \
  --pxe-enabled true \
  aa:bb:cc:dd:ee:ff
openstack baremetal port show <port-id>
openstack baremetal port delete <port-id>

# --- Introspection (auto-discover hardware properties) ---
openstack baremetal introspection start my-node
openstack baremetal introspection status my-node
openstack baremetal introspection data save my-node
```

---

## Shared File Systems (Manila)

```bash
# --- Shares ---
openstack share list
openstack share show my-share

# Create an NFS share
openstack share create \
  --name my-share \
  --share-type cephfs-nfs \
  --description "Shared NFS volume" \
  NFS 100

# Create a CIFS share
openstack share create \
  --name my-cifs-share \
  --share-type default \
  CIFS 50

# Show export locations (mount paths)
openstack share show my-share | grep export_locations
openstack share export location list my-share

# Extend / shrink a share
openstack share resize --new-size 200 my-share

# Delete a share
openstack share delete my-share

# --- Access Rules ---
openstack share access list my-share

# Grant IP-based access (NFS)
openstack share access create \
  --access-type ip \
  --access-to 10.0.1.0/24 \
  --access-level rw \
  my-share

# Grant user-based access (CIFS)
openstack share access create \
  --access-type user \
  --access-to domain\\my-user \
  --access-level rw \
  my-cifs-share

openstack share access delete my-share <access-id>

# --- Snapshots ---
openstack share snapshot list
openstack share snapshot create --name my-snap my-share
openstack share create \
  --name my-share-from-snap \
  --snapshot-id <snapshot-id> \
  NFS 100
openstack share snapshot delete my-snap

# --- Share Types ---
openstack share type list
openstack share type show cephfs-nfs
openstack share type create \
  --extra-specs driver_handles_share_servers=False \
  my-share-type
openstack share type delete my-share-type
```

---

## Tips & Tricks

```bash
# --- Output formats ---
openstack server list -f json    # JSON (pipe to jq)
openstack server list -f yaml    # YAML
openstack server list -f table   # default table
openstack server list -f csv     # CSV
openstack server list -f value -c ID -c Name  # plain values, selected cols

# Parse with jq
openstack server list -f json | jq '.[].Name'

# --- Multi-cloud / switching clouds ---
# Switch cloud inline
openstack --os-cloud my-cloud-admin project list

# Or export for the shell session
export OS_CLOUD=my-cloud

# --- Discover available commands ---
openstack command list
openstack command list | grep volume
openstack help server create

# --- Long / verbose output ---
openstack server list --long
openstack volume list --long

# --- Debug mode ---
openstack --debug server list      # print full HTTP requests/responses
OS_DEBUG=1 openstack server list   # alternative env var

# --- Micro-versions (Nova / Cinder) ---
# Force a specific API micro-version
OS_COMPUTE_API_VERSION=2.87 openstack server list
OS_VOLUME_API_VERSION=3.59 openstack volume list

# --- OSC plugin pattern (install extra command groups) ---
# Third-party services ship as OSC plugins; install and they extend `openstack`
pip install python-magnumclient       # Container Infra (Magnum)
pip install python-troveclient        # Database (Trove)
pip install python-senlinclient       # Clustering (Senlin)
pip install python-muranoclient       # App Catalog (Murano)
openstack coe cluster list            # Magnum after install

# --- Useful aliases ---
alias osl='openstack server list'
alias ovl='openstack volume list'
alias onl='openstack network list'
alias oimg='openstack image list'

# --- Check quota usage ---
openstack quota show
openstack quota show my-project
openstack limits show --absolute

# --- Availability Zones ---
openstack availability zone list
openstack availability zone list --compute
openstack availability zone list --volume
openstack availability zone list --network
```

---

## Quick Reference Card

| Resource          | List                          | Create                       | Show                        | Delete                       |
|-------------------|-------------------------------|------------------------------|-----------------------------|------------------------------|
| Server            | `openstack server list`       | `openstack server create`    | `openstack server show`     | `openstack server delete`    |
| Volume            | `openstack volume list`       | `openstack volume create`    | `openstack volume show`     | `openstack volume delete`    |
| Network           | `openstack network list`      | `openstack network create`   | `openstack network show`    | `openstack network delete`   |
| Subnet            | `openstack subnet list`       | `openstack subnet create`    | `openstack subnet show`     | `openstack subnet delete`    |
| Router            | `openstack router list`       | `openstack router create`    | `openstack router show`     | `openstack router delete`    |
| Floating IP       | `openstack floating ip list`  | `openstack floating ip create` | `openstack floating ip show` | `openstack floating ip delete` |
| Security Group    | `openstack security group list` | `openstack security group create` | `openstack security group show` | `openstack security group delete` |
| Image             | `openstack image list`        | `openstack image create`     | `openstack image show`      | `openstack image delete`     |
| Keypair           | `openstack keypair list`      | `openstack keypair create`   | `openstack keypair show`    | `openstack keypair delete`   |
| Flavor            | `openstack flavor list`       | `openstack flavor create`    | `openstack flavor show`     | `openstack flavor delete`    |
| Stack             | `openstack stack list`        | `openstack stack create`     | `openstack stack show`      | `openstack stack delete`     |
| Zone (DNS)        | `openstack zone list`         | `openstack zone create`      | `openstack zone show`       | `openstack zone delete`      |
| Share (Manila)    | `openstack share list`        | `openstack share create`     | `openstack share show`      | `openstack share delete`     |
| Baremetal Node    | `openstack baremetal node list` | `openstack baremetal node create` | `openstack baremetal node show` | `openstack baremetal node delete` |
