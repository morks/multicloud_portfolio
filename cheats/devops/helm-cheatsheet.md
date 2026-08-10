# Helm Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install helm

# Version prüfen
helm version

# Shell-Completion einrichten
echo 'source <(helm completion zsh)' >> ~/.zshrc

# Helm-Plugin-Verzeichnis
helm plugin list
helm env
```

---

## Repositories

```bash
# Repos auflisten
helm repo list

# Repo hinzufügen
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add cert-manager https://charts.jetstack.io
helm repo add argo https://argoproj.github.io/argo-helm

# Repos aktualisieren (Paketliste neu laden)
helm repo update

# Repo entfernen
helm repo remove stable

# Charts in einem Repo suchen
helm search repo bitnami
helm search repo bitnami/nginx

# Charts auf ArtifactHub suchen
helm search hub wordpress
```

---

## Charts installieren

```bash
# Chart installieren (automatischer Release-Name)
helm install bitnami/nginx --generate-name

# Chart mit Name installieren
helm install mein-nginx bitnami/nginx

# In bestimmten Namespace installieren
helm install mein-nginx bitnami/nginx \
  --namespace produktion \
  --create-namespace

# Mit Values überschreiben (--set)
helm install mein-nginx bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=LoadBalancer

# Mit values.yaml-Datei
helm install mein-nginx bitnami/nginx \
  -f meine-values.yaml

# Mehrere Values-Dateien (überschreiben von links nach rechts)
helm install mein-nginx bitnami/nginx \
  -f base-values.yaml \
  -f prod-values.yaml

# Spezifische Chart-Version installieren
helm install mein-nginx bitnami/nginx \
  --version 15.3.0

# Dry-Run (nur rendern, nicht installieren)
helm install mein-nginx bitnami/nginx \
  --dry-run --debug

# Atomic (automatischer Rollback bei Fehler)
helm install mein-nginx bitnami/nginx \
  --atomic --timeout 5m
```

---

## Releases verwalten

```bash
# Alle Releases auflisten
helm list
helm ls -A                  # alle Namespaces
helm ls -n produktion       # in bestimmtem Namespace

# Release-Status anzeigen
helm status mein-nginx

# Release-Details / generierte Manifeste
helm get all mein-nginx
helm get manifest mein-nginx
helm get values mein-nginx
helm get notes mein-nginx

# Release upgraden
helm upgrade mein-nginx bitnami/nginx \
  --set replicaCount=5

# Upgrade oder Install (kombiniert)
helm upgrade --install mein-nginx bitnami/nginx \
  -f values.yaml \
  --namespace produktion \
  --create-namespace

# Rollback auf vorherige Version
helm rollback mein-nginx

# Rollback auf spezifische Revision
helm rollback mein-nginx 2

# Release-History anzeigen
helm history mein-nginx

# Release deinstallieren
helm uninstall mein-nginx
helm uninstall mein-nginx -n produktion

# Release deinstallieren (History behalten)
helm uninstall mein-nginx --keep-history
```

---

## Charts erstellen

```bash
# Neues Chart-Gerüst erstellen
helm create mein-chart

# Chart-Struktur
# mein-chart/
# ├── Chart.yaml          # Metadaten
# ├── values.yaml         # Default-Werte
# ├── charts/             # Abhängigkeiten
# └── templates/          # Kubernetes-Manifeste
#     ├── deployment.yaml
#     ├── service.yaml
#     ├── ingress.yaml
#     ├── _helpers.tpl    # Hilfsmakros
#     └── NOTES.txt       # Post-Install Hinweise

# Chart validieren (Linting)
helm lint mein-chart

# Chart rendern (ohne Installieren)
helm template mein-release mein-chart
helm template mein-release mein-chart -f values.yaml

# Chart packen
helm package mein-chart

# Chart in lokaler Registry testen
helm install test-release ./mein-chart --dry-run
```

---

## Abhängigkeiten (Dependencies)

```bash
# Chart.yaml mit Abhängigkeiten
cat << 'EOF' > Chart.yaml
apiVersion: v2
name: meine-app
version: 1.0.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
EOF

# Abhängigkeiten herunterladen
helm dependency update mein-chart

# Abhängigkeiten auflisten
helm dependency list mein-chart

# Abhängigkeiten neu bauen (aus charts/ Dir)
helm dependency build mein-chart
```

---

## OCI-Registries (ab Helm 3.8)

```bash
# OCI-Registry-Login
helm registry login registry.beispiel.de \
  --username mein-user \
  --password mein-token

# Chart in OCI-Registry pushen
helm push mein-chart-1.0.0.tgz oci://registry.beispiel.de/charts

# Chart aus OCI-Registry installieren
helm install mein-release \
  oci://registry.beispiel.de/charts/mein-chart \
  --version 1.0.0

# OCI-Logout
helm registry logout registry.beispiel.de
```

---

## Plugins

```bash
# Nützliche Plugins installieren
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/jkroepke/helm-secrets
helm plugin install https://github.com/quintush/helm-unittest

# Diff zwischen installiertem Release und neuem Upgrade
helm diff upgrade mein-nginx bitnami/nginx -f values.yaml

# Secrets mit vals/sops verschlüsseln
helm secrets install mein-release ./mein-chart \
  -f secrets.yaml

# Unit-Tests ausführen
helm unittest mein-chart

# Alle Plugins auflisten
helm plugin list
```

---

## Templating – Go-Templates

```yaml
# values.yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

```yaml
# templates/deployment.yaml – Beispiel
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mein-chart.fullname" . }}
  labels:
    {{- include "mein-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "mein-chart.selectorLabels" . | nindent 6 }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
```

```bash
# Häufige Template-Funktionen
{{ .Values.key }}                        # Wert aus values.yaml
{{ .Release.Name }}                      # Release-Name
{{ .Release.Namespace }}                 # Namespace
{{ .Chart.Name }}                        # Chart-Name
{{ .Chart.Version }}                     # Chart-Version
{{ default "fallback" .Values.key }}     # Default-Wert
{{ required "Pflichtfeld!" .Values.key }}# Pflichtfeld
{{ toYaml .Values.obj | nindent 4 }}    # YAML-Ausgabe einrücken
{{ include "helper.name" . }}           # Hilfsmakro einbinden
{{- if .Values.ingress.enabled }}       # Bedingung
{{- range .Values.list }}               # Iteration
{{ . }}
{{- end }}
```

---

## Tipps & Best Practices

```bash
# Aktuell genutzte Chart-Version prüfen
helm show chart bitnami/nginx | grep version

# Alle Versionen eines Charts anzeigen
helm search repo bitnami/nginx --versions

# Chart-Dokumentation anzeigen
helm show readme bitnami/nginx
helm show values bitnami/nginx           # Default-Values

# Default-Values als Basis für eigenes values.yaml
helm show values bitnami/nginx > my-values.yaml

# Release-Manifest als Backup exportieren
helm get manifest mein-nginx > mein-nginx-backup.yaml

# Namespaces für alle Releases ausgeben
helm ls -A -o json | jq '.[] | {name, namespace, status}'

# Veraltete Charts finden
helm list -A -o json | \
  jq '.[] | select(.status != "deployed") | {name, status}'
```
