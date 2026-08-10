# ArgoCD Cheat Sheet

## Installation & Setup

```bash
# ArgoCD CLI installieren (macOS)
brew install argocd

# Version prüfen
argocd version

# ArgoCD in Kubernetes installieren
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Initial-Passwort abrufen
argocd admin initial-password -n argocd
# oder:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# ArgoCD-Server per Port-Forward erreichbar machen
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# dann: https://localhost:8080

# Einloggen
argocd login localhost:8080 \
  --username admin \
  --password <passwort> \
  --insecure

# Passwort ändern
argocd account update-password \
  --current-password <alt> \
  --new-password <neu>

# In Kubernetes-Kontext einloggen (wenn im Cluster)
argocd login --core
```

---

## Anwendungen verwalten

```bash
# Alle Anwendungen auflisten
argocd app list

# Anwendungsdetails anzeigen
argocd app get meine-app

# Anwendung erstellen (aus Git-Repository)
argocd app create meine-app \
  --repo https://github.com/mein-org/mein-repo.git \
  --path helm/meine-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace produktion

# Anwendung mit Helm-Values erstellen
argocd app create meine-app \
  --repo https://github.com/mein-org/mein-repo.git \
  --path helm/meine-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace produktion \
  --helm-set replicaCount=3 \
  --helm-set image.tag=v1.2.0

# Anwendung mit Helm-Values-Datei
argocd app create meine-app \
  --repo https://github.com/mein-org/mein-repo.git \
  --path helm/meine-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace produktion \
  --values values-prod.yaml

# Auto-Sync aktivieren
argocd app set meine-app \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Auto-Sync deaktivieren
argocd app set meine-app --sync-policy none

# Anwendung synchronisieren (Deploy)
argocd app sync meine-app

# Sync mit Prune (veraltete Ressourcen löschen)
argocd app sync meine-app --prune

# Sync erzwingen
argocd app sync meine-app --force

# Sync-Status live verfolgen
argocd app wait meine-app --sync --health

# Anwendung löschen (mit Ressourcen)
argocd app delete meine-app
# ohne Ressourcen löschen:
argocd app delete meine-app --cascade=false
```

---

## Sync-Status & Health

```bash
# App-Status prüfen
argocd app get meine-app

# Alle Apps mit Status
argocd app list -o wide

# OutOfSync-Apps anzeigen
argocd app list | grep OutOfSync

# Diff zwischen Git und Live-Zustand
argocd app diff meine-app

# Diff für spezifische Ressource
argocd app diff meine-app --resource apps:Deployment:mein-deploy

# Ressourcen einer App auflisten
argocd app resources meine-app

# App-Logs anzeigen (Pod-Logs)
argocd app logs meine-app
argocd app logs meine-app --container app

# Historische Deployments
argocd app history meine-app

# Rollback auf vorherige Version
argocd app rollback meine-app <revision-id>
argocd app rollback meine-app 0   # letzte Version
```

---

## Projekte

```bash
# Projekte auflisten
argocd proj list

# Projekt-Details anzeigen
argocd proj get mein-projekt

# Projekt erstellen
argocd proj create mein-projekt \
  --description "Produktions-Apps" \
  --src https://github.com/mein-org/mein-repo.git \
  --dest https://kubernetes.default.svc,produktion

# Source-Repository hinzufügen
argocd proj add-source mein-projekt \
  https://github.com/mein-org/weiteres-repo.git

# Destination hinzufügen
argocd proj add-destination mein-projekt \
  https://kubernetes.default.svc staging

# Cluster-Ressource-Whitelist setzen
argocd proj allow-cluster-resource mein-projekt \
  "" Namespace

# Namespaced-Ressourcen blacklisten
argocd proj deny-namespace-resource mein-projekt \
  "" LimitRange

# Projekt löschen
argocd proj delete mein-projekt
```

---

## Cluster & Repositories

```bash
# Cluster auflisten
argocd cluster list

# Cluster hinzufügen (aus aktuellem kubeconfig-Kontext)
argocd cluster add mein-kontext-name
argocd cluster add mein-kontext-name --name "Prod-Cluster"

# Cluster entfernen
argocd cluster rm https://mein-cluster-api:6443

# Repositories auflisten
argocd repo list

# Git-Repository hinzufügen (HTTPS mit Token)
argocd repo add https://github.com/mein-org/mein-repo.git \
  --username mein-user \
  --password <token>

# Git-Repository mit SSH-Key hinzufügen
argocd repo add git@github.com:mein-org/mein-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa

# Helm-Repository hinzufügen
argocd repo add https://charts.bitnami.com/bitnami \
  --type helm \
  --name bitnami

# OCI-Helm-Repository
argocd repo add registry.beispiel.de \
  --type helm \
  --name meine-oci-registry \
  --enable-oci \
  --username mein-user \
  --password <token>

# Repository entfernen
argocd repo rm https://github.com/mein-org/mein-repo.git
```

---

## Benutzer & RBAC

```bash
# Benutzer auflisten
argocd account list

# Eigenen Account-Status anzeigen
argocd account get --account mein-user

# Token für Benutzer erstellen
argocd account generate-token --account ci-user

# Token mit Ablaufzeit (24h)
argocd account generate-token \
  --account ci-user \
  --expires-in 24h

# Passwort für Benutzer setzen
argocd account update-password \
  --account mein-user \
  --new-password <neues-passwort>

# Admin-Passwort zurücksetzen
kubectl -n argocd patch secret argocd-secret \
  -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'

# RBAC-Policy (in argocd-rbac-cm ConfigMap)
# p, role:developer, applications, sync, */*, allow
# p, role:developer, applications, get, */*, allow
# g, mein-user, role:developer
```

---

## ApplicationSets

```bash
# ApplicationSets auflisten
argocd appset list

# ApplicationSet erstellen (Liste)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: meine-apps
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - cluster: dev
        url: https://dev.k8s.beispiel.de
      - cluster: prod
        url: https://prod.k8s.beispiel.de
  template:
    metadata:
      name: '{{cluster}}-meine-app'
    spec:
      project: mein-projekt
      source:
        repoURL: https://github.com/mein-org/mein-repo.git
        path: helm/meine-app
        targetRevision: HEAD
      destination:
        server: '{{url}}'
        namespace: meine-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
EOF

# ApplicationSet löschen
argocd appset delete meine-apps
```

---

## App of Apps Muster

```yaml
# Root-App (verwaltet andere ArgoCD-Apps)
# apps/templates/child-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ .Values.name }}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: {{ .Values.project }}
  source:
    repoURL: {{ .Values.repoURL }}
    path: {{ .Values.path }}
    targetRevision: {{ .Values.targetRevision | default "HEAD" }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ .Values.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## CLI-Kontext & Mehrere ArgoCD-Server

```bash
# Aktuellen Kontext anzeigen
argocd context

# Zu anderem Server wechseln
argocd context prod-argocd

# Login zu zweitem Server
argocd login argocd.prod.beispiel.de \
  --username admin \
  --password <passwort> \
  --name prod-argocd

# Alle konfigurierten Kontexte
cat ~/.argocd/config | grep -A2 servers
```

---

## Notfall & Troubleshooting

```bash
# ArgoCD-Server neu starten
kubectl rollout restart deployment argocd-server -n argocd

# Sync-Waves und Hooks in Annotations
# argocd.argoproj.io/sync-wave: "0"        # Reihenfolge
# argocd.argoproj.io/hook: PreSync         # Hook-Typ
# argocd.argoproj.io/hook-delete-policy: HookSucceeded

# Ressource aus ArgoCD-Verwaltung ausschließen
argocd app patch-resource meine-app \
  --kind Deployment \
  --resource-name mein-deploy \
  --patch '{"metadata":{"annotations":{"argocd.argoproj.io/managed": "false"}}}' \
  --patch-type application/merge-patch+json

# App-Controller-Logs
kubectl logs -n argocd \
  -l app.kubernetes.io/name=argocd-application-controller \
  -f

# Server-Logs
kubectl logs -n argocd \
  -l app.kubernetes.io/name=argocd-server \
  -f

# Alle ArgoCD-Pods
kubectl get pods -n argocd

# ArgoCD-Version im Cluster
kubectl -n argocd get deploy argocd-server \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```
