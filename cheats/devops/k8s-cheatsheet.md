# Kubernetes (kubectl) Cheat Sheet

## Installation & Konfiguration

```bash
# kubectl installieren (macOS)
brew install kubectl

# Version prüfen
kubectl version --client

# Shell-Completion einrichten
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
echo 'alias k=kubectl' >> ~/.zshrc
echo 'complete -F __start_kubectl k' >> ~/.zshrc

# kubeconfig anzeigen
kubectl config view

# Aktuellen Kontext anzeigen
kubectl config current-context

# Alle Kontexte auflisten
kubectl config get-contexts

# Kontext wechseln
kubectl config use-context mein-cluster

# Namespace dauerhaft setzen
kubectl config set-context --current --namespace=mein-namespace

# Mehrere kubeconfig-Dateien mergen
KUBECONFIG=~/.kube/config:~/.kube/prod-config kubectl config view --merge --flatten > ~/.kube/merged-config
```

---

## Pods

```bash
# Alle Pods im aktuellen Namespace
kubectl get pods
kubectl get pods -o wide          # mit Node-Info und IP
kubectl get pods -A               # alle Namespaces
kubectl get pods --watch          # Live-Updates

# Pod-Details anzeigen
kubectl describe pod <pod-name>

# Pod-Logs anzeigen
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>   # spezifischer Container
kubectl logs <pod-name> --previous            # vorheriger abgestürzter Container
kubectl logs -f <pod-name>                    # Follow/Live-Logs
kubectl logs --tail=100 <pod-name>            # letzte 100 Zeilen

# In Pod einloggen (Shell)
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -c <container> -- /bin/sh

# Einzel-Befehl in Pod ausführen
kubectl exec <pod-name> -- env

# Pod löschen
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --grace-period=0 --force   # sofort

# Temporären Debug-Pod starten
kubectl run debug --image=busybox --restart=Never -it --rm -- /bin/sh

# Port-Forward zu einem Pod
kubectl port-forward pod/<pod-name> 8080:80

# Datei in/aus Pod kopieren
kubectl cp <pod-name>:/pfad/datei.txt ./lokal.txt
kubectl cp ./lokal.txt <pod-name>:/pfad/datei.txt
```

---

## Deployments

```bash
# Deployments auflisten
kubectl get deployments
kubectl get deploy -o wide

# Deployment erstellen
kubectl create deployment nginx --image=nginx:alpine --replicas=3

# Deployment aus YAML anlegen
kubectl apply -f deployment.yaml

# Deployment aktualisieren (Image)
kubectl set image deployment/mein-deploy \
  container-name=nginx:1.25

# Rollout-Status prüfen
kubectl rollout status deployment/mein-deploy

# Rollout-History anzeigen
kubectl rollout history deployment/mein-deploy

# Rollback (auf vorherige Version)
kubectl rollout undo deployment/mein-deploy

# Rollback auf spezifische Revision
kubectl rollout undo deployment/mein-deploy --to-revision=2

# Skalieren
kubectl scale deployment mein-deploy --replicas=5

# Autoscaler (HPA)
kubectl autoscale deployment mein-deploy \
  --min=2 --max=10 --cpu-percent=70

# Deployment pausieren / fortsetzen
kubectl rollout pause deployment/mein-deploy
kubectl rollout resume deployment/mein-deploy

# Deployment löschen
kubectl delete deployment mein-deploy
```

---

## Services

```bash
# Services auflisten
kubectl get services
kubectl get svc

# Service erstellen (ClusterIP)
kubectl expose deployment mein-deploy \
  --port=80 --target-port=8080

# Service vom Typ LoadBalancer erstellen
kubectl expose deployment mein-deploy \
  --type=LoadBalancer --port=80

# Service vom Typ NodePort
kubectl expose deployment mein-deploy \
  --type=NodePort --port=80

# Service-Details
kubectl describe service mein-service

# Endpoints anzeigen
kubectl get endpoints mein-service

# Service löschen
kubectl delete service mein-service

# Port-Forward zu einem Service
kubectl port-forward service/mein-service 8080:80
```

---

## Namespaces

```bash
# Namespaces auflisten
kubectl get namespaces
kubectl get ns

# Namespace erstellen
kubectl create namespace mein-namespace

# Im Namespace arbeiten (-n Flag)
kubectl get pods -n mein-namespace
kubectl get all -n mein-namespace

# Namespace löschen (löscht alle Ressourcen darin!)
kubectl delete namespace mein-namespace

# Ressourcenquota für Namespace setzen
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
  namespace: mein-namespace
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
# ConfigMap erstellen
kubectl create configmap mein-config \
  --from-literal=DB_HOST=localhost \
  --from-literal=DB_PORT=5432

# ConfigMap aus Datei erstellen
kubectl create configmap mein-config --from-file=config.properties

# ConfigMap anzeigen
kubectl get configmap mein-config -o yaml

# Secret erstellen
kubectl create secret generic mein-secret \
  --from-literal=username=admin \
  --from-literal=password=geheim123

# Secret als TLS anlegen
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Secret decodieren
kubectl get secret mein-secret -o jsonpath='{.data.password}' | base64 -d

# Alle Secrets anzeigen
kubectl get secrets
```

---

## Ingress

```bash
# Ingress auflisten
kubectl get ingress
kubectl get ing -A

# Ingress anlegen
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mein-ingress
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
            name: mein-service
            port:
              number: 80
EOF

# Ingress löschen
kubectl delete ingress mein-ingress
```

---

## Nodes

```bash
# Nodes auflisten
kubectl get nodes
kubectl get nodes -o wide

# Node-Details anzeigen
kubectl describe node <node-name>

# Node-Ressourcenauslastung (Metrics-Server erforderlich)
kubectl top nodes
kubectl top pods

# Node cordonen (keine neuen Pods mehr)
kubectl cordon <node-name>

# Node drainen (Pods umziehen, dann warten)
kubectl drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data

# Node wieder aktivieren
kubectl uncordon <node-name>

# Taints setzen
kubectl taint nodes <node-name> key=value:NoSchedule

# Taint entfernen
kubectl taint nodes <node-name> key=value:NoSchedule-

# Labels anzeigen / setzen
kubectl get nodes --show-labels
kubectl label node <node-name> env=production
```

---

## StatefulSets, DaemonSets & Jobs

```bash
# StatefulSets
kubectl get statefulsets
kubectl scale statefulset mein-sts --replicas=3
kubectl rollout status statefulset/mein-sts

# DaemonSets
kubectl get daemonsets -A
kubectl describe daemonset <name> -n kube-system

# Jobs
kubectl create job mein-job --image=busybox -- echo "Fertig"
kubectl get jobs
kubectl logs job/mein-job

# CronJob
kubectl create cronjob mein-cron \
  --image=busybox \
  --schedule="0 * * * *" \
  -- /bin/sh -c "date"
kubectl get cronjobs
```

---

## RBAC – Rollen & Berechtigungen

```bash
# Rollen auflisten
kubectl get roles -A
kubectl get clusterroles

# ClusterRole erstellen
kubectl create clusterrole pod-reader \
  --verb=get,list,watch \
  --resource=pods

# RoleBinding erstellen
kubectl create rolebinding dev-pod-reader \
  --clusterrole=pod-reader \
  --user=developer \
  --namespace=development

# ClusterRoleBinding
kubectl create clusterrolebinding admin-user \
  --clusterrole=cluster-admin \
  --user=admin@beispiel.de

# ServiceAccount erstellen
kubectl create serviceaccount mein-sa

# Berechtigungen prüfen
kubectl auth can-i list pods
kubectl auth can-i create deployments --namespace=production
kubectl auth can-i --list                           # alle eigenen Rechte
kubectl auth can-i list pods --as=developer         # als anderer User prüfen
```

---

## PersistentVolumes & Storage

```bash
# PersistentVolumes auflisten
kubectl get pv
kubectl get pvc -A                  # alle PVCs

# StorageClass anzeigen
kubectl get storageclass

# PVC erstellen
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mein-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
EOF

# PVC-Details
kubectl describe pvc mein-pvc
```

---

## Ressourcen allgemein

```bash
# Alle Ressourcen in einem Namespace
kubectl get all -n mein-namespace

# Alle API-Ressourcen anzeigen
kubectl api-resources

# Ressource als YAML exportieren
kubectl get deployment mein-deploy -o yaml > backup.yaml

# Ressource bearbeiten (öffnet Editor)
kubectl edit deployment mein-deploy

# Ressource mit Patch aktualisieren
kubectl patch deployment mein-deploy \
  -p '{"spec":{"replicas":3}}'

# Label-Selektor nutzen
kubectl get pods -l app=nginx,env=prod

# Ressource annotieren
kubectl annotate pod <pod-name> \
  description="Debug-Pod"

# Events anzeigen (Fehlersuche)
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n mein-namespace --watch

# Diff: lokale YAML vs. live-Konfiguration
kubectl diff -f deployment.yaml

# Dry-Run
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --dry-run=server
```

---

## Debugging & Troubleshooting

```bash
# Pod-Status sofort erklären
kubectl describe pod <pod-name> | grep -A5 Events

# Container-Restart-Gründe
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState}'

# Ressourcenverbrauch (Metrics-Server nötig)
kubectl top pods --sort-by=memory
kubectl top pods --containers

# Network-Debug-Pod starten
kubectl run netdebug \
  --image=nicolaka/netshoot \
  --restart=Never -it --rm

# DNS-Auflösung testen
kubectl run dns-test \
  --image=busybox --restart=Never -it --rm \
  -- nslookup kubernetes.default

# Node-Shell via privilegiertem Pod (Notfall)
kubectl debug node/<node-name> \
  -it --image=ubuntu

# Ephemeral Debug-Container (ab K8s 1.23)
kubectl debug -it <pod-name> \
  --image=busybox \
  --target=<container-name>
```

---

## Nützliche Aliases & Tools

```bash
# Empfohlene Aliases in ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'

# kubectx / kubens (Kontext & Namespace schnell wechseln)
brew install kubectx
kubectx             # Kontext interaktiv wechseln
kubens              # Namespace interaktiv wechseln

# k9s – Terminal-UI für Kubernetes
brew install k9s
k9s                 # startet interaktive TUI

# stern – Multi-Pod Log-Streaming
brew install stern
stern mein-deploy   # Logs aller Pods im Deployment

# kustomize
brew install kustomize
kustomize build ./overlays/prod | kubectl apply -f -
```
