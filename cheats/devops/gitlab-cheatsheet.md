# GitLab Cheat Sheet

## GitLab CLI (`glab`) – Installation & Login

```bash
# Installation (macOS)
brew install glab

# Authentifizieren (GitLab.com)
glab auth login

# Gegen Self-Hosted GitLab authentifizieren
glab auth login --hostname gitlab.meinefirma.de

# Status prüfen
glab auth status
```

---

## Repositories / Projekte

```bash
# Repo klonen
glab repo clone gruppe/projekt

# Neues Projekt erstellen
glab repo create mein-projekt --private

# Projekt forken
glab repo fork gruppe/projekt

# Projekt-Infos anzeigen
glab repo view gruppe/projekt

# Im Browser öffnen
glab repo view --web
```

---

## Merge Requests (MR)

```bash
# MR erstellen (interaktiv)
glab mr create

# MR direkt mit Titel
glab mr create --title "feat: neues Feature" --description "Beschreibung..." --target-branch main

# MR als Draft
glab mr create --draft

# Alle offenen MRs anzeigen
glab mr list

# MR-Details anzeigen
glab mr view 42

# MR auschecken
glab mr checkout 42

# MR mergen
glab mr merge 42
glab mr merge 42 --squash
glab mr merge 42 --rebase

# MR schließen
glab mr close 42

# MR-Status (Pipeline-Checks)
glab mr checks 42

# Reviewer hinzufügen
glab mr update 42 --reviewer kollege
```

---

## Issues

```bash
# Alle offenen Issues anzeigen
glab issue list

# Issue erstellen
glab issue create --title "Bug: Fehler beim Login" --description "Schritte zur Reproduktion..."

# Issue mit Label und Assignee
glab issue create --title "Aufgabe" --label "enhancement" --assignee @me

# Issue anzeigen
glab issue view 10

# Issue schließen
glab issue close 10

# Issue wieder öffnen
glab issue reopen 10

# Issue kommentieren
glab issue note 10 --message "Schau mal in Branch feature/fix-login"
```

---

## CI/CD Pipelines

```bash
# Letzte Pipelines anzeigen
glab ci list

# Pipeline-Details anzeigen
glab ci view

# Pipeline für aktuellen Branch starten
glab ci run

# Pipeline-Log eines Jobs anzeigen
glab ci trace

# Pipeline abbrechen
glab ci cancel

# Pipeline im Browser öffnen
glab ci view --web

# Job-Artefakte herunterladen
glab ci artifact <job-name>
```

---

## GitLab CI/CD – `.gitlab-ci.yml` Kurzreferenz

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  GO_VERSION: "1.22"

# Wiederverwendbares Template
.base:
  image: golang:${GO_VERSION}
  before_script:
    - go env

build:
  extends: .base
  stage: build
  script:
    - go build ./...
  artifacts:
    paths:
      - bin/
    expire_in: 1 hour

test:
  extends: .base
  stage: test
  script:
    - go test -v ./...
  coverage: '/coverage: \d+\.\d+%/'

deploy-staging:
  stage: deploy
  script:
    - ./deploy.sh staging
  environment:
    name: staging
    url: https://staging.meinapp.de
  only:
    - develop

deploy-prod:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://meinapp.de
  when: manual                  # manuelles Auslösen
  only:
    - main
```

---

## Wichtige CI/CD Schlüsselwörter

| Schlüsselwort | Beschreibung |
|---|---|
| `stages` | Reihenfolge der Stages |
| `image` | Docker-Image für den Job |
| `script` | Befehle im Job |
| `before_script` | Vor jedem Job ausführen |
| `after_script` | Nach jedem Job ausführen |
| `artifacts` | Dateien zwischen Jobs weitergeben |
| `cache` | Dependencies cachen |
| `only` / `except` | Branch-Filter (veraltet) |
| `rules` | Moderne Job-Bedingungen |
| `needs` | Job-Abhängigkeiten (DAG) |
| `when` | `always`, `on_failure`, `manual` |
| `environment` | Deployment-Umgebung definieren |
| `include` | Externe YAML-Dateien einbinden |
| `extends` | Template-Vererbung |

---

## Environments & Deployments

```yaml
# Environment mit Auto-Stop
deploy-review:
  script:
    - ./deploy-review.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.meinapp.de
    on_stop: stop-review
    auto_stop_in: 1 week

stop-review:
  script:
    - ./teardown-review.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

---

## Vordefinierte CI/CD Variablen (Auswahl)

```bash
CI_COMMIT_BRANCH       # Branch-Name
CI_COMMIT_SHA          # Vollständiger Commit-Hash
CI_COMMIT_SHORT_SHA    # Kurzer Commit-Hash
CI_COMMIT_TAG          # Tag-Name (wenn Pipeline durch Tag)
CI_PIPELINE_ID         # Pipeline-ID
CI_JOB_ID              # Job-ID
CI_PROJECT_PATH        # gruppe/projekt
CI_PROJECT_URL         # Projekt-URL
CI_REGISTRY            # Docker-Registry-URL
CI_REGISTRY_IMAGE      # Image-Pfad im Registry
CI_REGISTRY_USER       # Registry-Login
CI_REGISTRY_PASSWORD   # Registry-Passwort
GITLAB_USER_EMAIL      # E-Mail des auslösenden Users
```

---

## Container Registry

```bash
# In GitLab Registry einloggen
docker login registry.gitlab.com -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD

# Image bauen und pushen (in CI)
docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

# Images in der Registry auflisten
glab api projects/:id/registry/repositories

# Image-Tags anzeigen
glab api projects/:id/registry/repositories/:repo_id/tags
```

---

## Secrets & CI/CD Variablen (CLI)

```bash
# Variable setzen (Projekt-Ebene)
glab variable set API_KEY --value "mein-geheimnis"

# Variable als geschützt + maskiert
glab variable set API_KEY --value "mein-geheimnis" --protected --masked

# Variablen auflisten
glab variable list

# Variable löschen
glab variable delete API_KEY
```

---

## Nützliche `glab` Tricks

```bash
# Status des aktuellen Branches (MR + Pipeline)
glab mr status

# Diff eines MRs anzeigen
glab mr diff 42

# GitLab API direkt ansprechen
glab api projects/:id/issues --jq '.[].title'

# Alias anlegen
glab alias set mrs 'mr list --assignee @me'
glab mrs
```
