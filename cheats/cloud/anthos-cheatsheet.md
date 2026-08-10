# Anthos Cheat Sheet (Google Cloud)

## Installation & Setup

```bash
# Install Anthos components via gcloud
gcloud components install anthos-auth kubectl anthoscli

# Update all installed components
gcloud components update

# Check installed component versions
gcloud version
kubectl version --client
anthoscli version

# Enable required APIs for Anthos
gcloud services enable anthos.googleapis.com \
  container.googleapis.com \
  gkehub.googleapis.com \
  anthosconfigmanagement.googleapis.com \
  meshconfig.googleapis.com \
  --project my-project

# Verify enabled APIs
gcloud services list --enabled --filter="name:anthos" --project my-project

# Enable the Hub / Fleet API
gcloud services enable gkehub.googleapis.com --project my-project
```

---

## Fleet & Cluster Registration

```bash
# Register a GKE cluster to the fleet
gcloud container fleet memberships register my-cluster \
  --gke-cluster europe-west3-a/my-cluster \
  --enable-workload-identity \
  --project my-project

# Register an external (non-GKE) cluster
gcloud container fleet memberships register my-external-cluster \
  --context my-kube-context \
  --kubeconfig ~/.kube/config \
  --service-account-key-file sa-key.json \
  --project my-project

# List all fleet memberships
gcloud container fleet memberships list --project my-project

# Describe a specific membership
gcloud container fleet memberships describe my-cluster \
  --project my-project

# Delete a membership (unregister cluster)
gcloud container fleet memberships delete my-cluster \
  --project my-project

# Get credentials for a registered cluster via Connect Gateway
gcloud container fleet memberships get-credentials my-cluster \
  --project my-project

# List memberships via legacy hub command
gcloud container hub memberships list --project my-project

# Generate a gateway kubeconfig token (Connect Gateway)
gcloud container fleet memberships generate-gateway-rbac \
  --membership=my-cluster \
  --role=clusterrole/cluster-admin \
  --users=user@example.com \
  --project my-project \
  --kubeconfig ~/.kube/config \
  --context my-cluster \
  --apply
```

---

## Anthos Config Management (ACM)

```bash
# Enable the ACM feature on the fleet
gcloud container fleet config-management enable --project my-project

# Apply ACM configuration to a cluster
gcloud container fleet config-management apply \
  --membership my-cluster \
  --config acm-config.yaml \
  --project my-project

# Example acm-config.yaml structure (Config Sync + Policy Controller)
# applySpecVersion: 1
# spec:
#   configSync:
#     enabled: true
#     sourceFormat: hierarchy
#     syncRepo: https://github.com/my-org/my-config-repo
#     syncBranch: main
#     secretType: none
#   policyController:
#     enabled: true
#     referentialRulesEnabled: true

# Describe ACM status for a membership
gcloud container fleet config-management describe \
  --membership my-cluster \
  --project my-project

# Show ACM sync status across all memberships
gcloud container fleet config-management status --project my-project

# Install nomos CLI (Config Sync tool)
gsutil cp gs://config-management-release/latest/linux_amd64/nomos nomos
chmod +x nomos && sudo mv nomos /usr/local/bin/

# Validate local config repo with nomos
nomos vet --path ./my-config-repo

# Check sync status of a cluster
nomos status --contexts my-cluster-context

# Manually trigger a sync (if using GitOps)
nomos sync --contexts my-cluster-context

# View detailed Config Sync object status
kubectl get rootsyncs,reposyncs -A
kubectl describe rootsync root-sync -n config-management-system

# List Policy Controller constraint templates
kubectl get constrainttemplates
```

---

## Anthos Service Mesh (ASM)

```bash
# Download asmcli
curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.17 \
  -o asmcli && chmod +x asmcli

# Validate prerequisites before installing ASM
./asmcli validate \
  --project_id my-project \
  --cluster_name my-cluster \
  --cluster_location europe-west3-a \
  --fleet_id my-project

# Install ASM on a GKE cluster (managed control plane)
./asmcli install \
  --project_id my-project \
  --cluster_name my-cluster \
  --cluster_location europe-west3-a \
  --fleet_id my-project \
  --managed \
  --enable_all

# Enable sidecar injection for a namespace
kubectl label namespace my-namespace istio-injection=enabled

# Check injection label
kubectl get namespace my-namespace --show-labels

# View proxy status across all pods
istioctl proxy-status

# Analyze mesh configuration for issues
istioctl analyze --namespace my-namespace

# Open Kiali dashboard (service mesh observability)
istioctl dashboard kiali

# Open Jaeger tracing dashboard
istioctl dashboard jaeger

# Open Grafana metrics dashboard
istioctl dashboard grafana

# Create an Istio Gateway resource
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: my-gateway
  namespace: my-namespace
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "my-app.example.com"
EOF

# Create a VirtualService for traffic routing
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-virtualservice
  namespace: my-namespace
spec:
  hosts:
  - my-service
  http:
  - route:
    - destination:
        host: my-service
        subset: v1
      weight: 90
    - destination:
        host: my-service
        subset: v2
      weight: 10
EOF

# Create a DestinationRule with mTLS
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: my-destinationrule
  namespace: my-namespace
spec:
  host: my-service
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF

# Enforce strict mTLS for the entire mesh
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF
```

---

## Multi-Cluster Ingress & Services

```bash
# Enable Multi-Cluster Ingress on the fleet
gcloud container fleet ingress enable \
  --config-membership=projects/my-project/locations/global/memberships/my-cluster \
  --project my-project

# Verify Multi-Cluster Ingress feature status
gcloud container fleet ingress describe --project my-project

# Enable required APIs for Multi-Cluster Services
gcloud services enable multiclusterservicediscovery.googleapis.com \
  --project my-project

# Enable Multi-Cluster Services (MCS) on the fleet
gcloud container fleet multi-cluster-services enable --project my-project

# Apply a MultiClusterIngress resource (config cluster)
kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: MultiClusterIngress
metadata:
  name: my-mci
  namespace: my-namespace
  annotations:
    networking.gke.io/static-ip: "34.x.x.x"
spec:
  template:
    spec:
      backend:
        serviceName: my-mcs
        servicePort: 80
EOF

# Apply a MultiClusterService resource
kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: MultiClusterService
metadata:
  name: my-mcs
  namespace: my-namespace
spec:
  template:
    spec:
      selector:
        app: my-app
      ports:
      - name: http
        protocol: TCP
        port: 80
        targetPort: 8080
EOF

# Create a BackendConfig for health checks
kubectl apply -f - <<EOF
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backendconfig
  namespace: my-namespace
spec:
  healthCheck:
    requestPath: /healthz
    port: 8080
EOF

# List MultiClusterIngress and MultiClusterService resources
kubectl get multiclusteringress,multiclusterservice -n my-namespace
```

---

## Policy Controller

```bash
# Enable Policy Controller via ACM config (see ACM section)
# Alternatively apply via gcloud
gcloud container fleet config-management apply \
  --membership my-cluster \
  --config policy-controller-config.yaml \
  --project my-project

# List all installed constraint templates
kubectl get constrainttemplates

# Describe a specific constraint template
kubectl describe constrainttemplate k8srequiredlabels

# Create a ConstraintTemplate (OPA Rego)
kubectl apply -f - <<EOF
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
EOF

# Create a Constraint (enforce the template)
kubectl apply -f - <<EOF
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-app-label
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    labels: ["app", "env"]
EOF

# List all active constraints
kubectl get constraints

# Check constraint violations (audit mode)
kubectl describe k8srequiredlabels require-app-label

# Switch constraint to audit mode (no blocking)
kubectl patch k8srequiredlabels require-app-label \
  --type=merge \
  -p '{"spec":{"enforcementAction":"dryrun"}}'

# Install Policy Controller library policies
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper-library/master/library/general/requiredlabels/template.yaml
```

---

## Anthos on Bare Metal / VMware

```bash
# Download bmctl tool (Bare Metal)
gsutil cp gs://anthos-baremetal-release/bmctl/1.15.0/linux-amd64/bmctl bmctl
chmod +x bmctl && sudo mv bmctl /usr/local/bin/

# Create a bare metal cluster config
bmctl create config \
  --cluster-name my-bm-cluster \
  --project-id my-project \
  --output my-bm-cluster.yaml

# Check prerequisites before creating a cluster
bmctl check cluster \
  --cluster-name my-bm-cluster \
  --admin-cluster-kubeconfig ~/.kube/config

# Create the bare metal cluster
bmctl create cluster \
  --cluster-name my-bm-cluster

# Reset / delete a bare metal cluster
bmctl reset cluster \
  --cluster-name my-bm-cluster \
  --kubeconfig bmctl-workspace/my-bm-cluster/my-bm-cluster-kubeconfig

# Upgrade a bare metal cluster
bmctl upgrade cluster \
  --cluster-name my-bm-cluster \
  --kubeconfig bmctl-workspace/my-bm-cluster/my-bm-cluster-kubeconfig

# For Anthos on VMware – download gkectl
gsutil cp gs://gke-on-prem-release/gkectl/1.15.0/linux/gkectl gkectl
chmod +x gkectl && sudo mv gkectl /usr/local/bin/

# Prepare vSphere credentials file (govc env)
export GOVC_URL=vcenter.example.com
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=my-password
export GOVC_INSECURE=true

# Create Anthos on VMware config
gkectl create-config --config my-vsphere-cluster.yaml

# Check prerequisites for VMware cluster
gkectl check-config --config my-vsphere-cluster.yaml

# Create VMware cluster
gkectl create admin --config my-vsphere-cluster.yaml

# Upgrade VMware cluster
gkectl upgrade admin --config my-vsphere-cluster.yaml \
  --kubeconfig kubeconfig
```

---

## Identity & Access

```bash
# Configure Connect Gateway for kubectl access to registered clusters
gcloud container fleet memberships get-credentials my-cluster \
  --project my-project

# Grant cluster access via Connect Gateway RBAC
gcloud container fleet memberships generate-gateway-rbac \
  --membership my-cluster \
  --role clusterrole/cluster-admin \
  --users user@example.com \
  --project my-project \
  --kubeconfig ~/.kube/config \
  --context my-cluster \
  --apply

# Enable Workload Identity on a GKE cluster
gcloud container clusters update my-cluster \
  --zone europe-west3-a \
  --workload-pool=my-project.svc.id.goog

# Create a Kubernetes service account and bind it to a GCP SA
kubectl create serviceaccount my-ksa -n my-namespace

gcloud iam service-accounts add-iam-policy-binding \
  my-gsa@my-project.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:my-project.svc.id.goog[my-namespace/my-ksa]"

kubectl annotate serviceaccount my-ksa \
  --namespace my-namespace \
  iam.gke.io/gcp-service-account=my-gsa@my-project.iam.gserviceaccount.com

# Grant a service account permission to impersonate another SA
gcloud iam service-accounts add-iam-policy-binding \
  target-sa@my-project.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountTokenCreator \
  --member "serviceAccount:my-sa@my-project.iam.gserviceaccount.com"

# Apply fleet-level RBAC (ClusterRole binding across all member clusters)
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fleet-admin-binding
subjects:
- kind: User
  name: user@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# List IAM policy bindings for the fleet project
gcloud projects get-iam-policy my-project \
  --format="table(bindings.role,bindings.members)"
```

---

## Monitoring & Logging

```bash
# Verify Cloud Monitoring is enabled for GKE cluster
gcloud container clusters describe my-cluster \
  --zone europe-west3-a \
  --format="value(monitoringConfig)"

# Enable Cloud Monitoring and Logging on existing cluster
gcloud container clusters update my-cluster \
  --zone europe-west3-a \
  --monitoring=SYSTEM,WORKLOAD \
  --logging=SYSTEM,WORKLOAD

# View Anthos-related logs in Cloud Logging
gcloud logging read \
  'resource.type="k8s_cluster" AND resource.labels.cluster_name="my-cluster"' \
  --limit 50 \
  --project my-project

# View Config Management sync logs
gcloud logging read \
  'resource.type="k8s_container" AND resource.labels.container_name="reconciler"' \
  --limit 30 \
  --project my-project

# Check istio-proxy access logs (ASM)
kubectl logs -n my-namespace my-pod -c istio-proxy --tail=100

# Analyze mesh config issues across all namespaces
istioctl analyze --all-namespaces

# View proxy config for a specific pod
istioctl proxy-config cluster my-pod.my-namespace

# Check control plane health (ASM managed)
kubectl get controlplanerevision -n istio-system

# View SLO status via ASM in Console
# Navigate: Cloud Console → Anthos → Service Mesh → Services → SLOs

# Create a log-based metric for policy violations
gcloud logging metrics create anthos-policy-violations \
  --description="Gatekeeper policy violations" \
  --log-filter='resource.type="k8s_cluster" AND jsonPayload.message:"violation"'

# View metrics in Cloud Monitoring
gcloud monitoring dashboards list --project my-project
```

---

## Tips & Tricks

```bash
# Check ACM sync status across all registered clusters
gcloud container fleet config-management status --project my-project

# Dry-run an ACM config change before applying
gcloud container fleet config-management apply \
  --membership my-cluster \
  --config acm-config.yaml \
  --project my-project \
  --dry-run

# List all fleet features and their states
gcloud container fleet features list --project my-project

# Toggle a fleet feature off
gcloud container fleet config-management disable --project my-project

# Query all memberships with a specific condition
gcloud container fleet memberships list \
  --filter="state.code=READY" \
  --project my-project

# List memberships with their associated GKE clusters
gcloud container fleet memberships list \
  --format="table(name,endpoint.gkeCluster.resourceLink)" \
  --project my-project

# Check nomos status for multiple clusters at once
nomos status --contexts my-cluster-1,my-cluster-2

# Validate an entire config repo without a cluster connection
nomos vet --path ./my-config-repo --source-format hierarchy

# Force-resync Config Sync root sync
kubectl annotate rootsync root-sync \
  -n config-management-system \
  configsync.gke.io/sync-token=$(date +%s) \
  --overwrite

# Check Anthos license / feature entitlements
gcloud projects get-iam-policy my-project \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/anthos" \
  --format="table(bindings.role,bindings.members)"

# Get a quick overview of all Anthos components
gcloud container fleet features describe configmanagement --project my-project
gcloud container fleet features describe servicemesh --project my-project
gcloud container fleet features describe policycontroller --project my-project
gcloud container fleet features describe multiclusteringress --project my-project
```
