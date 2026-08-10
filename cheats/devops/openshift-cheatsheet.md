# OpenShift / OKD Cheat Sheet

## Installation & Setup

```bash
# Install oc CLI (macOS)
brew install openshift-cli

# Install oc CLI (Linux binary)
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
sudo mv oc /usr/local/bin/

# Check version
oc version

# Set up shell completion (zsh)
echo 'source <(oc completion zsh)' >> ~/.zshrc
echo 'alias oc=oc' >> ~/.zshrc

# Log in with token
oc login https://api.my-cluster.example.com:6443 --token=sha256~abc123

# Log in with username and password
oc login https://api.my-cluster.example.com:6443 -u developer -p password

# Log in via browser (OAuth web flow)
oc login --web https://api.my-cluster.example.com:6443

# Show current user
oc whoami

# Show current token
oc whoami --show-token

# Show server URL
oc whoami --show-server

# Show cluster info
oc cluster-info

# Show current project and overall status
oc status

# Show kubeconfig
oc config view

# List all contexts
oc config get-contexts

# Switch context
oc config use-context my-cluster-context

# Log out
oc logout
```

---

## Projects (Namespaces)

```bash
# Create a new project
oc new-project my-project --description="My app project" --display-name="My App"

# List all projects (you have access to)
oc projects

# Show current project
oc project

# Switch to a different project
oc project my-project

# Get projects (machine-readable)
oc get projects

# Describe a project
oc describe project my-project

# Delete a project (and all its resources!)
oc delete project my-project

# Request a project (via project request template)
oc new-project my-project

# Show resource quota for current project
oc get resourcequota

# Describe resource quota
oc describe resourcequota -n my-project

# Show limit ranges
oc get limitrange
oc describe limitrange -n my-project

# Create a resource quota
oc apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-quota
  namespace: my-project
spec:
  hard:
    pods: "20"
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
EOF

# Create a limit range
oc apply -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: my-limits
  namespace: my-project
spec:
  limits:
  - type: Container
    default:
      cpu: 500m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
EOF

# Show project request template (cluster-wide)
oc get template -n openshift project-request -o yaml

# Process and apply a project request template
oc process -n openshift project-request \
  -p PROJECT_NAME=my-project \
  -p PROJECT_DISPLAYNAME="My App" | oc apply -f -
```

---

## Deploying Applications

```bash
# Deploy from a container image
oc new-app nginx:latest --name=my-app

# Deploy from a Git repository (S2I auto-detect)
oc new-app https://github.com/my-org/my-app.git --name=my-app

# Deploy from Git with specific branch
oc new-app https://github.com/my-org/my-app.git#main --name=my-app

# Deploy from Git with explicit builder image (S2I)
oc new-app python:3.11~https://github.com/my-org/my-app.git --name=my-app

# Deploy from a Dockerfile in a Git repo
oc new-app --strategy=docker https://github.com/my-org/my-app.git --name=my-app

# Deploy from an OpenShift template
oc new-app --template=mysql-persistent \
  -p MYSQL_USER=dbuser \
  -p MYSQL_PASSWORD=secret \
  -p MYSQL_DATABASE=mydb

# Deploy from a local directory
oc new-app . --name=my-app

# Create resources from YAML file
oc create -f my-app.yaml

# Apply (create or update) resources from YAML
oc apply -f my-app.yaml
oc apply -f ./manifests/             # apply entire directory

# Trigger a new build and deployment manually
oc start-build my-app

# Check DeploymentConfig rollout status
oc rollout status dc/my-app

# Roll out the latest DeploymentConfig
oc rollout latest dc/my-app

# Show rollout history
oc rollout history dc/my-app

# Undo last rollout (DeploymentConfig)
oc rollout undo dc/my-app

# Rollback to specific revision
oc rollout undo dc/my-app --to-revision=3

# Check Deployment (Kubernetes-native) rollout status
oc rollout status deployment/my-app

# Undo last Deployment rollout
oc rollout undo deployment/my-app

# Update the container image in a DeploymentConfig
oc set image dc/my-app my-app=image-registry.openshift-image-registry.svc:5000/my-project/my-app:v2

# Update the container image in a Deployment
oc set image deployment/my-app my-app=nginx:1.25

# Set environment variables
oc set env dc/my-app DB_HOST=my-db DB_PORT=5432

# Set environment variable from a Secret
oc set env dc/my-app --from=secret/my-secret

# Set resource requests/limits
oc set resources dc/my-app \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=100m,memory=128Mi

# Dry-run apply
oc apply -f my-app.yaml --dry-run=client
```

---

## Builds & ImageStreams

```bash
# Create a new BuildConfig (S2I from Git)
oc new-build python:3.11~https://github.com/my-org/my-app.git --name=my-app

# Create a new BuildConfig from a Dockerfile
oc new-build --strategy=docker \
  https://github.com/my-org/my-app.git --name=my-app

# Start a build manually
oc start-build my-app

# Start a build from local source directory
oc start-build my-app --from-dir=.

# Start a build and follow the logs
oc start-build my-app --follow

# Cancel a running build
oc cancel-build my-app-3

# Show build logs
oc logs build/my-app-3
oc logs -f bc/my-app             # follow latest build

# List builds
oc get builds
oc get builds -n my-project

# Describe a BuildConfig
oc describe bc/my-app

# Get BuildConfig YAML
oc get bc/my-app -o yaml

# Delete a BuildConfig
oc delete bc/my-app

# List ImageStreams
oc get imagestreams
oc get is

# Describe an ImageStream
oc describe is/my-app

# Tag an image into an ImageStream
oc tag my-project/my-app:latest my-project/my-app:stable

# Tag an external image into an ImageStream
oc tag docker.io/nginx:latest my-project/nginx:latest

# Import an image from an external registry
oc import-image my-app:v2 \
  --from=docker.io/my-org/my-app:v2 \
  --confirm

# Import all tags from an external registry
oc import-image my-app \
  --from=docker.io/my-org/my-app \
  --all --confirm

# Get image stream tags
oc get istag

# Trigger a build when an ImageStream tag changes (set trigger)
oc set triggers bc/my-app --from-image=my-project/base-image:latest

# BuildConfig with Docker strategy (manifest)
oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: my-app
  namespace: my-project
spec:
  source:
    type: Git
    git:
      uri: https://github.com/my-org/my-app.git
      ref: main
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
  output:
    to:
      kind: ImageStreamTag
      name: my-app:latest
  triggers:
  - type: GitHub
    github:
      secret: my-webhook-secret
  - type: ImageChange
EOF
```

---

## Routes & Networking

```bash
# Expose a service as a Route (HTTP)
oc expose svc/my-app

# Expose with custom hostname
oc expose svc/my-app --hostname=my-app.apps.my-cluster.example.com

# Create an edge-terminated TLS Route (TLS terminated at router)
oc create route edge my-app-tls \
  --service=my-app \
  --hostname=my-app.apps.my-cluster.example.com \
  --cert=tls.crt \
  --key=tls.key

# Create a passthrough Route (TLS passed to pod)
oc create route passthrough my-app-tls \
  --service=my-app \
  --hostname=my-app.apps.my-cluster.example.com

# Create a re-encrypt Route (TLS re-encrypted between router and pod)
oc create route reencrypt my-app-tls \
  --service=my-app \
  --hostname=my-app.apps.my-cluster.example.com \
  --cert=tls.crt \
  --key=tls.key \
  --dest-ca-cert=backend-ca.crt

# List all Routes
oc get routes
oc get routes -A                # all namespaces

# Describe a Route
oc describe route/my-app

# Delete a Route
oc delete route my-app

# Add Route annotations (timeout, rate limit, HSTS)
oc annotate route my-app \
  haproxy.router.openshift.io/timeout=60s

oc annotate route my-app \
  haproxy.router.openshift.io/rate-limit-connections=true \
  haproxy.router.openshift.io/rate-limit-connections.rate-http=100

oc annotate route my-app \
  haproxy.router.openshift.io/hsts_header="max-age=31536000;includeSubDomains;preload"

# Show HAProxy router pods
oc get pods -n openshift-ingress

# Describe the IngressController (router)
oc describe ingresscontroller default -n openshift-ingress-operator

# Manage the router via adm (classic)
oc adm router --dry-run

# Port-forward to a pod (no Route required)
oc port-forward pod/my-app-1-abcde 8080:8080

# Port-forward to a service
oc port-forward svc/my-app 8080:80
```

---

## Pods, Deployments & Scaling

```bash
# List pods in current project
oc get pods
oc get pods -o wide              # with node and IP info
oc get pods -A                   # all namespaces
oc get pods --watch              # live updates

# Describe a pod
oc describe pod my-app-1-abcde

# Delete a pod
oc delete pod my-app-1-abcde
oc delete pod my-app-1-abcde --grace-period=0 --force   # immediately

# Show pod logs
oc logs my-app-1-abcde
oc logs -f my-app-1-abcde                         # follow
oc logs --tail=100 my-app-1-abcde                 # last 100 lines
oc logs my-app-1-abcde -c my-container            # specific container
oc logs --previous my-app-1-abcde                 # previous (crashed) container

# Open a shell in a pod
oc rsh my-app-1-abcde

# Execute a command in a pod
oc exec my-app-1-abcde -- env
oc exec -it my-app-1-abcde -- /bin/bash

# Copy files to/from a pod
oc cp my-app-1-abcde:/tmp/data.txt ./data.txt
oc cp ./config.yaml my-app-1-abcde:/app/config.yaml

# Scale a DeploymentConfig
oc scale dc/my-app --replicas=3

# Scale a Deployment
oc scale deployment/my-app --replicas=3

# Autoscale (HPA)
oc autoscale dc/my-app --min=2 --max=10 --cpu-percent=70
oc autoscale deployment/my-app --min=2 --max=10 --cpu-percent=70

# Pause and resume a rollout
oc rollout pause dc/my-app
oc rollout resume dc/my-app

# Debug a running deployment (opens shell in copy of pod)
oc debug deployment/my-app

# Debug a node (privileged shell)
oc debug node/my-worker-node-1

# Start a temporary debug pod
oc run debug-pod --image=busybox --restart=Never -it --rm -- /bin/sh

# Set resource requests and limits on a pod spec
oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: my-project
spec:
  containers:
  - name: my-app
    image: my-app:latest
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF
```

---

## Security Context Constraints (SCC)

```bash
# List all SCCs (cluster-wide)
oc get scc

# Describe a specific SCC
oc describe scc restricted-v2
oc describe scc anyuid
oc describe scc privileged

# Show which SCC a pod is running under
oc get pod my-app-1-abcde -o jsonpath='{.metadata.annotations.openshift\.io/scc}'

# Add SCC to a service account
oc adm policy add-scc-to-user anyuid -z my-service-account -n my-project

# Add SCC to a specific user
oc adm policy add-scc-to-user privileged developer

# Add SCC to a group
oc adm policy add-scc-to-group anyuid system:serviceaccounts:my-project

# Remove SCC from a service account
oc adm policy remove-scc-from-user anyuid -z my-service-account -n my-project

# List SCCs granted to a service account
oc adm policy scc-subject-review -z my-service-account -n my-project

# Review which SCC would be used for a pod spec
oc adm policy scc-review -f my-pod.yaml

# Create a service account and assign SCC
oc create sa my-service-account -n my-project
oc adm policy add-scc-to-user anyuid -z my-service-account -n my-project

# Reference service account in a Deployment
oc set serviceaccount deployment/my-app my-service-account

# securityContext in a pod manifest (run as specific UID)
oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: my-project
spec:
  serviceAccountName: my-service-account
  securityContext:
    runAsUser: 1001
    runAsGroup: 1001
    fsGroup: 1001
  containers:
  - name: my-app
    image: my-app:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
EOF
```

---

## RBAC & Users

```bash
# List all roles in current project
oc get roles
oc get clusterroles | grep -v system

# List role bindings
oc get rolebinding -n my-project
oc get clusterrolebinding

# Add a built-in role to a user in a project
oc adm policy add-role-to-user admin developer -n my-project
oc adm policy add-role-to-user view tester -n my-project
oc adm policy add-role-to-user edit developer -n my-project

# Add a role to a group
oc adm policy add-role-to-group view my-team -n my-project

# Remove a role from a user
oc adm policy remove-role-from-user admin developer -n my-project

# Add cluster-admin to a user
oc adm policy add-cluster-role-to-user cluster-admin admin-user

# Check what a user can do (who-can)
oc adm policy who-can get pods -n my-project
oc adm policy who-can create deployments -n my-project

# Create a custom ClusterRole
oc create clusterrole pod-reader \
  --verb=get,list,watch \
  --resource=pods

# Create a RoleBinding
oc create rolebinding dev-pod-reader \
  --clusterrole=pod-reader \
  --user=developer \
  --namespace=my-project

# Create a ClusterRoleBinding
oc create clusterrolebinding admin-binding \
  --clusterrole=cluster-admin \
  --user=admin@example.com

# List users
oc get users
oc get identity

# Create an HTPasswd OAuth identity provider entry
htpasswd -B -c /tmp/htpasswd developer
htpasswd -B /tmp/htpasswd tester

# Create secret from HTPasswd file
oc create secret generic htpasswd-secret \
  --from-file=htpasswd=/tmp/htpasswd \
  -n openshift-config

# Patch the OAuth cluster config to use HTPasswd
oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd-secret
EOF

# Sync LDAP groups
oc adm groups sync --sync-config=ldap-sync.yaml --confirm

# List groups
oc get groups

# Add user to a group
oc adm groups add-users my-team developer tester
```

---

## Operators & OLM

```bash
# List installed Operators (ClusterServiceVersions)
oc get csv -A
oc get csv -n my-project

# Describe a CSV
oc describe csv my-operator.v1.2.3 -n my-project

# List Subscriptions (installed operator channels)
oc get subscription -A
oc describe subscription my-operator -n openshift-operators

# List InstallPlans
oc get installplan -A

# Approve a manual InstallPlan
oc patch installplan install-abcde \
  -n my-project \
  --type merge \
  -p '{"spec":{"approved":true}}'

# List OperatorGroups
oc get operatorgroup -A

# Create an OperatorGroup for a single namespace
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: my-operator-group
  namespace: my-project
spec:
  targetNamespaces:
  - my-project
EOF

# Create a Subscription to install an Operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-operator
  namespace: my-project
spec:
  channel: stable
  name: my-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF

# List CatalogSources
oc get catalogsource -A
oc get catalogsource -n openshift-marketplace

# Describe a CatalogSource
oc describe catalogsource redhat-operators -n openshift-marketplace

# Add a custom CatalogSource
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/my-org/my-operator-index:latest
  displayName: My Operator Catalog
  publisher: My Org
  updateStrategy:
    registryPoll:
      interval: 30m
EOF

# operator-sdk basics (local development)
operator-sdk init --domain=example.com --repo=github.com/my-org/my-operator
operator-sdk create api --group=app --version=v1alpha1 --kind=MyApp --resource --controller
operator-sdk run bundle quay.io/my-org/my-operator-bundle:v0.1.0 -n my-project

# List all available operator packages in a catalog
oc get packagemanifest -n openshift-marketplace
```

---

## Node & Cluster Management

```bash
# List all nodes
oc get nodes
oc get nodes -o wide

# Describe a node
oc describe node my-worker-node-1

# Show node logs (via adm)
oc adm node-logs my-worker-node-1 --unit=kubelet
oc adm node-logs my-worker-node-1 --unit=crio

# Show resource usage across nodes
oc adm top nodes
oc adm top pods -A

# Cordon a node (no new pods)
oc adm cordon my-worker-node-1

# Drain a node (evict pods, then cordon)
oc adm drain my-worker-node-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force

# Re-enable a node
oc adm uncordon my-worker-node-1

# List ClusterOperators and their status
oc get clusteroperator
oc get co                          # short alias

# Describe a ClusterOperator
oc describe co authentication

# Show current ClusterVersion (upgrade status)
oc get clusterversion
oc describe clusterversion

# Check available updates
oc adm upgrade

# Start a cluster upgrade
oc adm upgrade --to=4.14.5
oc adm upgrade --to-latest=true

# List MachineConfigPools
oc get mcp
oc describe mcp worker

# List MachineSets (cloud provider node groups)
oc get machineset -n openshift-machine-api
oc scale machineset my-machineset -n openshift-machine-api --replicas=3

# List Machines
oc get machine -n openshift-machine-api

# Backup etcd (run on a control-plane node via debug)
oc debug node/my-master-node-1
# inside the debug pod:
chroot /host
/usr/local/bin/cluster-backup.sh /home/core/assets/backup

# List MachineConfigs
oc get machineconfig
oc describe mc 99-worker-custom-config
```

---

## Storage

```bash
# List PersistentVolumes (cluster-wide)
oc get pv
oc describe pv my-pv

# List PersistentVolumeClaims
oc get pvc
oc get pvc -A                    # all namespaces

# Describe a PVC
oc describe pvc my-pvc

# List StorageClasses
oc get storageclass
oc get sc

# Create a PVC
oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: my-project
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp3-csi
  resources:
    requests:
      storage: 20Gi
EOF

# Mount a volume into a DeploymentConfig
oc set volume dc/my-app \
  --add \
  --name=my-data \
  --type=persistentVolumeClaim \
  --claim-name=my-pvc \
  --mount-path=/data

# Mount a ConfigMap as a volume
oc set volume dc/my-app \
  --add \
  --name=my-config \
  --type=configmap \
  --configmap-name=my-config \
  --mount-path=/etc/config

# Mount a Secret as a volume
oc set volume dc/my-app \
  --add \
  --name=my-secret \
  --type=secret \
  --secret-name=my-secret \
  --mount-path=/etc/secrets

# List volumes on a DeploymentConfig
oc get dc/my-app -o jsonpath='{.spec.template.spec.volumes}'

# OpenShift Data Foundation (ODF) — list storage systems
oc get storagecluster -n openshift-storage
oc get cephcluster -n openshift-storage

# ODF storage classes typically available after install
oc get sc | grep -E 'ocs|ceph|odf'

# Configure image registry to use persistent storage
oc patch configs.imageregistry.operator.openshift.io cluster \
  --type merge \
  -p '{"spec":{"storage":{"pvc":{"claim":""}}, "managementState":"Managed"}}'

# Check image registry status
oc get configs.imageregistry.operator.openshift.io cluster -o yaml
```

---

## Tips & Tricks

```bash
# Explain any OpenShift resource type
oc explain pod.spec.containers
oc explain route.spec
oc explain buildconfig.spec.strategy

# List all available API resources
oc api-resources
oc api-resources | grep openshift

# Get all resources in the current project
oc get all -n my-project

# Export resource as YAML (for backup or migration)
oc get deployment my-app -o yaml > my-app-backup.yaml
oc get dc my-app -o yaml > my-app-dc-backup.yaml

# Edit a resource in your default editor
oc edit dc/my-app
oc edit deployment/my-app

# Patch a resource
oc patch dc/my-app \
  --type merge \
  -p '{"spec":{"replicas":3}}'

# Show events (sorted, for troubleshooting)
oc get events --sort-by='.lastTimestamp'
oc get events -n my-project --watch

# Use label selectors
oc get pods -l app=my-app,env=prod
oc delete pods -l app=my-app

# Process a template with parameters
oc process -f my-template.yaml \
  -p APP_NAME=my-app \
  -p IMAGE_TAG=v2 | oc apply -f -

# Process a built-in template from the openshift namespace
oc process openshift//mysql-persistent \
  -p MYSQL_USER=dbuser \
  -p MYSQL_PASSWORD=secret | oc apply -f -

# List available templates
oc get templates -n openshift

# Collect must-gather data (full cluster diagnostics)
oc adm must-gather
oc adm must-gather --image=registry.redhat.io/openshift4/ose-must-gather:latest

# Collect targeted diagnostic data for one resource
oc adm inspect clusteroperator/authentication
oc adm inspect ns/my-project

# Debug a crashed deployment
oc debug deployment/my-app
oc debug dc/my-app --as-root

# Debug a node with a privileged shell
oc debug node/my-worker-node-1

# Useful aliases in ~/.zshrc
alias kk='oc'
alias kkgp='oc get pods'
alias kkgs='oc get svc'
alias kkgd='oc get deployments'
alias kkaf='oc apply -f'
alias kklog='oc logs -f'
alias kkex='oc exec -it'
alias kkrsh='oc rsh'

# Switch between multiple clusters / contexts
oc config get-contexts
oc config use-context my-prod-cluster
oc config use-context my-dev-cluster

# Set a default namespace/project for a context
oc config set-context --current --namespace=my-project

# Merge kubeconfigs from multiple clusters
KUBECONFIG=~/.kube/config:~/.kube/prod-config \
  oc config view --merge --flatten > ~/.kube/merged-config
export KUBECONFIG=~/.kube/merged-config
```
