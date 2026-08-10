# GitHub Cheat Sheet

## GitHub CLI (`gh`) – Installation & Login

```bash
# Installation (macOS)
brew install gh

# Authentifizieren
gh auth login

# Status prüfen
gh auth status

# Token erneuern
gh auth refresh
```

---

## Repositories

```bash
# Repo klonen
gh repo clone user/repo

# Neues Repo erstellen (interaktiv)
gh repo create

# Neues privates Repo direkt
gh repo create mein-repo --private

# Repo forken
gh repo fork user/repo

# Repo-Infos anzeigen
gh repo view user/repo

# Repo im Browser öffnen
gh repo view --web

# Repos auflisten
gh repo list user --limit 20
```

---

## Pull Requests

```bash
# PR erstellen (interaktiv)
gh pr create

# PR mit Titel und Body direkt erstellen
gh pr create --title "feat: neues Feature" --body "Beschreibung..." --base main

# PR als Draft erstellen
gh pr create --draft

# Alle offenen PRs anzeigen
gh pr list

# PRs gefiltert (z. B. assigned to me)
gh pr list --assignee @me

# PR-Details anzeigen
gh pr view 42

# PR im Browser öffnen
gh pr view 42 --web

# PR auschecken (Branch lokal wechseln)
gh pr checkout 42

# PR mergen
gh pr merge 42 --merge
gh pr merge 42 --squash
gh pr merge 42 --rebase

# PR schließen
gh pr close 42

# PR-Status (CI-Checks)
gh pr checks 42

# PR-Review anfordern
gh pr edit 42 --add-reviewer kollege
```

---

## Issues

```bash
# Alle offenen Issues anzeigen
gh issue list

# Issue erstellen
gh issue create --title "Bug: Fehler beim Login" --body "Schritte zur Reproduktion..."

# Issue mit Label und Assignee
gh issue create --title "Aufgabe" --label "enhancement" --assignee @me

# Issue anzeigen
gh issue view 10

# Issue schließen
gh issue close 10

# Issue wieder öffnen
gh issue reopen 10

# Issues durchsuchen
gh issue list --search "login error"

# Issue kommentieren
gh issue comment 10 --body "Schau mal in Branch feature/fix-login"
```

---

## GitHub Actions (Workflows)

```bash
# Workflows auflisten
gh workflow list

# Workflow manuell auslösen
gh workflow run deploy.yml

# Workflow mit Input-Parameter
gh workflow run deploy.yml --field environment=production

# Laufende und vergangene Runs anzeigen
gh run list

# Run-Details anzeigen
gh run view 1234567890

# Logs eines Runs anzeigen
gh run view 1234567890 --log

# Run abbrechen
gh run cancel 1234567890

# Run im Browser öffnen
gh run view 1234567890 --web
```

---

## Releases

```bash
# Releases auflisten
gh release list

# Release anzeigen
gh release view v1.0.0

# Neues Release erstellen
gh release create v1.0.0 --title "v1.0.0" --notes "Changelog..."

# Release mit Artefakt hochladen
gh release create v1.0.0 ./dist/app-linux-amd64 --title "v1.0.0"

# Release als Draft
gh release create v1.0.0 --draft

# Prerelease
gh release create v1.1.0-rc1 --prerelease

# Release löschen
gh release delete v1.0.0
```

---

## Gists

```bash
# Gist aus Datei erstellen (öffentlich)
gh gist create mein-skript.sh --public

# Privates Gist
gh gist create mein-skript.sh

# Gists auflisten
gh gist list

# Gist anzeigen
gh gist view <gist-id>
```

---

## GitHub Actions – Workflow-Syntax (Kurzreferenz)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:          # manuell auslösbar

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.22"

      - name: Build
        run: go build ./...

      - name: Test
        run: go test ./...

  deploy:
    needs: build               # wartet auf build-Job
    runs-on: ubuntu-latest
    environment: production    # schützt Deployment mit Approval
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

---

## Secrets & Variablen (CLI)

```bash
# Secret setzen (Repo)
gh secret set API_KEY

# Secret aus Datei
gh secret set API_KEY < secret.txt

# Secret auflisten
gh secret list

# Secret löschen
gh secret delete API_KEY

# Env-Variable setzen
gh variable set ENV_NAME --body "production"
```

---

## Nützliche `gh` Tricks

```bash
# Aktuellen PR des Branches anzeigen
gh pr status

# Diff eines PRs anzeigen
gh pr diff 42

# Repo-Statistiken (Stars, Forks, Watchers)
gh repo view user/repo --json stargazerCount,forkCount

# GitHub API direkt ansprechen
gh api repos/user/repo/issues --jq '.[].title'

# GraphQL-Abfrage
gh api graphql -f query='{ viewer { login } }'

# Alias anlegen
gh alias set prs 'pr list --assignee @me'
gh prs
```
