# Kubernetes (kubectl) Cheat Sheet

## Installation & Setup

```bash
# Install kubectl (macOS)
brew install kubectl

# Check version
kubectl version --client

# Set up shell completion
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
echo 'complete -F __start_kubectl k' >> ~/.zshrc

# Show kubeconfig
kubectl config view

# Show current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context my-cluster

# Set namespace permanently
kubectl config set-context --current --namespace=my-namespace

# Merge multiple kubeconfig files
KUBECONFIG=~/.kube/config:~/.kube/prod-config kubectl config view --merge --flatten > ~/.kube/merged-config
```

---

## Pods

```bash
# All pods in current namespace
kubectl get pods
kubectl get pods -o wide          # with node info and IP
kubectl get pods -A               # all namespaces
kubectl get pods --watch          # live updates

# Show pod details
kubectl describe pod <pod-name>

# Show pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>   # specific container
kubectl logs <pod-name> --previous            # previous crashed container
kubectl logs -f <pod-name>                    # follow/live logs
kubectl logs --tail=100 <pod-name>            # last 100 lines

# Log into pod (shell)
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -c <container> -- /bin/sh

# Run a single command in pod
kubectl exec <pod-name> -- env

# Delete pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --grace-period=0 --force   # immediately

# Start a temporary debug pod
kubectl run debug --image=busybox --restart=Never -it --rm -- /bin/sh

# Port-forward to a pod
kubectl port-forward pod/<pod-name> 8080:80

# Copy file to/from pod
kubectl cp <pod-name>:/path/file.txt ./local.txt
kubectl cp ./local.txt <pod-name>:/path/file.txt
```

---

## Deployments

```bash
# List deployments
kubectl get deployments
kubectl get deploy -o wide

# Create deployment
kubectl create deployment nginx --image=nginx:alpine --replicas=3

# Create deployment from YAML
kubectl apply -f deployment.yaml

# Update deployment (image)
kubectl set image deployment/my-deploy \
  container-name=nginx:1.25

# Check rollout status
kubectl rollout status deployment/my-deploy

# Show rollout history
kubectl rollout history deployment/my-deploy

# Rollback (to previous version)
kubectl rollout undo deployment/my-deploy

# Rollback to specific revision
kubectl rollout undo deployment/my-deploy --to-revision=2

# Scale
kubectl scale deployment my-deploy --replicas=5

# Autoscaler (HPA)
kubectl autoscale deployment my-deploy \
  --min=2 --max=10 --cpu-percent=70

# Pause / resume deployment
kubectl rollout pause deployment/my-deploy
kubectl rollout resume deployment/my-deploy

# Delete deployment
kubectl delete deployment my-deploy
```

---

## Services

```bash
# List services
kubectl get services
kubectl get svc

# Create service (ClusterIP)
kubectl expose deployment my-deploy \
  --port=80 --target-port=8080

# Create service of type LoadBalancer
kubectl expose deployment my-deploy \
  --type=LoadBalancer --port=80

# Service of type NodePort
kubectl expose deployment my-deploy \
  --type=NodePort --port=80

# Service details
kubectl describe service my-service

# Show endpoints
kubectl get endpoints my-service

# Delete service
kubectl delete service my-service

# Port-forward to a service
kubectl port-forward service/my-service 8080:80
```

---

## Namespaces

```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace my-namespace

# Work in namespace (-n flag)
kubectl get pods -n my-namespace
kubectl get all -n my-namespace

# Delete namespace (deletes all resources in it!)
kubectl delete namespace my-namespace

# Set resource quota for namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
  namespace: my-namespace
spec:
  hard:
    pods: "20"
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
EOF
```

---

## ConfigMaps & Secrets

```bash
# Create ConfigMap
kubectl create configmap my-config \
  --from-literal=DB_HOST=localhost \
  --from-literal=DB_PORT=5432

# Create ConfigMap from file
kubectl create configmap my-config --from-file=config.properties

# Show ConfigMap
kubectl get configmap my-config -o yaml

# Create secret
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=geheim123

# Create TLS secret
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Decode secret
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d

# Show all secrets
kubectl get secrets
```

---

## Ingress

```bash
# List ingress resources
kubectl get ingress
kubectl get ing -A

# Create ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.beispiel.de
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
EOF

# Delete ingress
kubectl delete ingress my-ingress
```

---

## Nodes

```bash
# List nodes
kubectl get nodes
kubectl get nodes -o wide

# Show node details
kubectl describe node <node-name>

# Node resource usage (metrics-server required)
kubectl top nodes
kubectl top pods

# Cordon node (no new pods)
kubectl cordon <node-name>

# Drain node (move pods, then wait)
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data

# Re-enable node
kubectl uncordon <node-name>

# Set taints
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node-name> key=value:NoSchedule-

# Show / set labels
kubectl get nodes --show-labels
kubectl label node <node-name> env=production
```

---

## StatefulSets, DaemonSets & Jobs

```bash
# StatefulSets
kubectl get statefulsets
kubectl scale statefulset my-sts --replicas=3
kubectl rollout status statefulset/my-sts

# DaemonSets
kubectl get daemonsets -A
kubectl describe daemonset <name> -n kube-system

# Jobs
kubectl create job my-job --image=busybox -- echo "Fertig"
kubectl get jobs
kubectl logs job/my-job

# CronJob
kubectl create cronjob my-cron \
  --image=busybox \
  --schedule="0 * * * *" \
  -- /bin/sh -c "date"
kubectl get cronjobs
```

---

## RBAC – Roles & Permissions

```bash
# List roles
kubectl get roles -A
kubectl get clusterroles

# Create ClusterRole
kubectl create clusterrole pod-reader \
  --verb=get,list,watch \
  --resource=pods

# Create RoleBinding
kubectl create rolebinding dev-pod-reader \
  --clusterrole=pod-reader \
  --user=developer \
  --namespace=development

# ClusterRoleBinding
kubectl create clusterrolebinding admin-user \
  --clusterrole=cluster-admin \
  --user=admin@beispiel.de

# Create ServiceAccount
kubectl create serviceaccount my-sa

# Check permissions
kubectl auth can-i list pods
kubectl auth can-i create deployments --namespace=production
kubectl auth can-i --list                           # all own permissions
kubectl auth can-i list pods --as=developer         # check as another user
```

---

## PersistentVolumes & Storage

```bash
# List PersistentVolumes
kubectl get pv
kubectl get pvc -A                  # all PVCs

# Show StorageClass
kubectl get storageclass

# Create PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
EOF

# PVC details
kubectl describe pvc my-pvc
```

---

## General Resources

```bash
# All resources in a namespace
kubectl get all -n my-namespace

# Show all API resources
kubectl api-resources

# Export resource as YAML
kubectl get deployment my-deploy -o yaml > backup.yaml

# Edit resource (opens editor)
kubectl edit deployment my-deploy

# Update resource with patch
kubectl patch deployment my-deploy \
  -p '{"spec":{"replicas":3}}'

# Use label selector
kubectl get pods -l app=nginx,env=prod

# Annotate resource
kubectl annotate pod <pod-name> \
  description="Debug-Pod"

# Show events (troubleshooting)
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n my-namespace --watch

# Diff: local YAML vs. live configuration
kubectl diff -f deployment.yaml

# Dry-run
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --dry-run=server
```

---

## Debugging & Troubleshooting

```bash
# Explain pod status immediately
kubectl describe pod <pod-name> | grep -A5 Events

# Container restart reasons
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState}'

# Resource usage (metrics-server required)
kubectl top pods --sort-by=memory
kubectl top pods --containers

# Start network debug pod
kubectl run netdebug \
  --image=nicolaka/netshoot \
  --restart=Never -it --rm

# Test DNS resolution
kubectl run dns-test \
  --image=busybox --restart=Never -it --rm \
  -- nslookup kubernetes.default

# Node shell via privileged pod (emergency)
kubectl debug node/<node-name> \
  -it --image=ubuntu

# Ephemeral debug container (from K8s 1.23)
kubectl debug -it <pod-name> \
  --image=busybox \
  --target=<container-name>
```

---

## Useful Aliases & Tools

```bash
# Recommended aliases in ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'

# kubectx / kubens (quickly switch context & namespace)
brew install kubectx
kubectx             # interactively switch context
kubens              # interactively switch namespace

# k9s – terminal UI for Kubernetes
brew install k9s
k9s                 # launches interactive TUI

# stern – multi-pod log streaming
brew install stern
stern my-deploy   # logs of all pods in deployment

# kustomize
brew install kustomize
kustomize build ./overlays/prod | kubectl apply -f -
```
