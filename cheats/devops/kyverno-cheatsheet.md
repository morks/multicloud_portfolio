# Kyverno Cheat Sheet

## Installation & Setup

```bash
# Add Kyverno Helm repo
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno (standalone mode – suitable for most clusters)
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace

# Install in HA mode (production)
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set admissionController.replicas=3 \
  --set backgroundController.replicas=2 \
  --set cleanupController.replicas=2 \
  --set reportsController.replicas=2

# Verify webhook is registered
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno

# Verify pods are running
kubectl get pods -n kyverno

# Install Kyverno CLI (macOS)
brew install kyverno

# Or download binary
curl -fsSL https://github.com/kyverno/kyverno/releases/latest/download/kyverno-cli_$(uname -s)_$(uname -m).tar.gz \
  | tar xz && sudo mv kyverno /usr/local/bin/
```

---

## Policy Basics

```bash
# ClusterPolicy  – cluster-scoped, applies to all namespaces
# Policy         – namespace-scoped, applies only to its own namespace

# Minimal ClusterPolicy skeleton
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: my-policy
spec:
  validationFailureAction: Audit    # Audit (log only) or Enforce (block)
  background: true                  # also evaluate existing resources
  rules:
    - name: my-rule
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - "*"           # all namespaces
      exclude:
        any:
        - resources:
            namespaces:
              - kyverno       # exclude operator namespace
      validate:               # or: mutate / generate / verifyImages
        message: "Violation message shown to the user"
        pattern:
          spec:
            containers:
            - name: "*"
              resources:
                limits:
                  memory: "?*"    # must be set
EOF

# List all policies
kubectl get clusterpolicy
kubectl get policy -A
```

---

## Validation Policies

```bash
# Require specific labels on all Pods
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-team-label
      match:
        any:
        - resources:
            kinds: [Pod]
      validate:
        message: "Pod must have label 'team'"
        pattern:
          metadata:
            labels:
              team: "?*"
EOF

# Restrict image registries (only allow internal registry)
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-registries
spec:
  validationFailureAction: Enforce
  rules:
    - name: validate-registries
      match:
        any:
        - resources:
            kinds: [Pod]
      validate:
        message: "Images must be from registry.example.com"
        pattern:
          spec:
            containers:
            - image: "registry.example.com/*"
EOF

# Require resource limits on all containers
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Audit
  rules:
    - name: check-limits
      match:
        any:
        - resources:
            kinds: [Pod]
      validate:
        message: "CPU and memory limits are required"
        pattern:
          spec:
            containers:
            - resources:
                limits:
                  cpu: "?*"
                  memory: "?*"
EOF
```

---

## Mutation Policies

```bash
# Add default labels to all Pods
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-labels
spec:
  rules:
    - name: add-managed-by
      match:
        any:
        - resources:
            kinds: [Pod]
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(managed-by): "platform-team"   # only set if label is absent
EOF

# Set default resource limits if not specified
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: set-default-limits
spec:
  rules:
    - name: set-limits
      match:
        any:
        - resources:
            kinds: [Pod]
      mutate:
        patchStrategicMerge:
          spec:
            containers:
            - (name): "*"
              resources:
                limits:
                  +(cpu): "500m"
                  +(memory): "256Mi"
EOF
```

---

## Generation Policies

```bash
# Auto-create a default NetworkPolicy in every new namespace
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-networkpolicy
spec:
  rules:
    - name: default-deny
      match:
        any:
        - resources:
            kinds: [Namespace]
      generate:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny-ingress
        namespace: "{{request.object.metadata.name}}"
        synchronize: true     # keep in sync, delete if policy is deleted
        data:
          spec:
            podSelector: {}
            policyTypes:
            - Ingress
EOF

# Auto-copy a ConfigMap into every new namespace
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: copy-configmap
spec:
  rules:
    - name: copy-registry-config
      match:
        any:
        - resources:
            kinds: [Namespace]
      generate:
        apiVersion: v1
        kind: ConfigMap
        name: registry-config
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        clone:
          namespace: default    # source namespace
          name: registry-config # source ConfigMap name
EOF
```

---

## Audit vs Enforce Mode

```bash
# validationFailureAction controls behavior:
#   Audit   – allow the request, log violation in PolicyReport
#   Enforce – block the request, return error to the user

# Check current mode of a policy
kubectl get clusterpolicy require-labels \
  -o jsonpath='{.spec.validationFailureAction}'

# Switch a policy from Audit to Enforce
kubectl patch clusterpolicy require-labels \
  --type=merge \
  -p '{"spec":{"validationFailureAction":"Enforce"}}'

# Check PolicyReport for audit violations in a namespace
kubectl get policyreport -n my-namespace
kubectl describe policyreport -n my-namespace

# Check ClusterPolicyReport for cluster-scoped resources
kubectl get clusterpolicyreport
```

---

## Kyverno CLI

```bash
# Apply a policy against a local resource file (dry-run)
kyverno apply ./my-policy.yaml --resource ./my-pod.yaml

# Apply a policy against all resources of a kind in a directory
kyverno apply ./policies/ --resource ./manifests/

# Run policy tests (requires a kyverno-test.yaml in the directory)
kyverno test ./tests/

# Evaluate a JMESPath expression against a live resource
kyverno jp query -i <(kubectl get pod my-pod -n my-ns -o json) \
  "spec.containers[0].image"

# Generate a ClusterPolicy from admission controller logs (experimental)
# Useful for building policies from existing workload behavior
kyverno generate --resource my-pod.yaml
```

---

## Policy Reports

```bash
# List PolicyReports per namespace (audit results)
kubectl get policyreport -A

# Show violations in a specific namespace
kubectl get policyreport -n my-namespace -o yaml | \
  grep -A5 "result: fail"

# Filter only FAIL results with jq
kubectl get policyreport -n my-namespace -o json | \
  jq '.items[].results[] | select(.result == "fail")'

# List ClusterPolicyReports (cluster-scoped resources)
kubectl get clusterpolicyreport

# Watch for new violations in real time
watch kubectl get policyreport -A

# Delete all PolicyReports (they are regenerated automatically)
kubectl delete policyreport --all -A
```

---

## Further Resources

| Resource | Link | Description |
|----------|------|-------------|
| **Official Docs** | [kyverno.io/docs](https://kyverno.io/docs/) | Kyverno documentation — installation, policy writing, mutation, generation, image verification, and CLI reference. |
| **Kyverno GitHub** | [github.com/kyverno/kyverno](https://github.com/kyverno/kyverno) | Source code, releases, issue tracker, and community discussions for Kyverno. |
| **Kyverno Policies Library** | [kyverno.io/policies](https://kyverno.io/policies/) | Official library of ready-to-use Kyverno policies — security baselines, best practices, and Pod Security Standards. |
| **Artifact Hub (policies)** | [artifacthub.io – Kyverno](https://artifacthub.io/packages/search?kind=13) | Community-contributed Kyverno policy packages on Artifact Hub. |
