# Git Cheat Sheet

## Installation & Konfiguration

```bash
# Installation (macOS)
brew install git

# Globale Identität setzen
git config --global user.name "Max Mustermann"
git config --global user.email "max@example.com"

# Standard-Editor setzen
git config --global core.editor "code --wait"   # VS Code
git config --global core.editor "vim"

# Standard-Branch-Name auf main setzen
git config --global init.defaultBranch main

# Alle globalen Einstellungen anzeigen
git config --global --list

# SSH-Key generieren
ssh-keygen -t ed25519 -C "max@example.com"
```

---

## Repository anlegen & klonen

```bash
# Neues Repo initialisieren
git init

# Vorhandenes Repo klonen
git clone https://github.com/user/repo.git

# Klonen in bestimmten Ordner
git clone https://github.com/user/repo.git mein-ordner

# Klonen eines einzelnen Branches
git clone --branch develop --single-branch https://github.com/user/repo.git
```

---

## Staging & Commits

```bash
# Änderungen anzeigen (unstaged)
git status
git diff

# Alle Änderungen stagen
git add .

# Einzelne Datei stagen
git add src/main.go

# Interaktiv stagen (Hunk-weise)
git add -p

# Commit erstellen
git commit -m "feat: neue Funktion hinzugefügt"

# Letzten Commit nachträglich bearbeiten (Nachricht oder Inhalt)
git commit --amend

# Leeren Commit erstellen (z. B. CI triggern)
git commit --allow-empty -m "ci: pipeline neu starten"
```

---

## Branches

```bash
# Alle Branches anzeigen (lokal + remote)
git branch -a

# Neuen Branch erstellen und wechseln
git switch -c feature/mein-feature

# Branch wechseln
git switch main

# Branch löschen (lokal)
git branch -d feature/mein-feature

# Branch mit Gewalt löschen
git branch -D feature/mein-feature

# Remote-Branch löschen
git push origin --delete feature/mein-feature

# Branch umbenennen
git branch -m alter-name neuer-name
```

---

## Merge & Rebase

```bash
# Branch in aktuellen Branch mergen
git merge feature/mein-feature

# Merge ohne Fast-Forward (erzeugt immer Merge-Commit)
git merge --no-ff feature/mein-feature

# Merge abbrechen
git merge --abort

# Rebase auf main
git rebase main

# Interaktiver Rebase (letzte 3 Commits umschreiben)
git rebase -i HEAD~3

# Rebase abbrechen
git rebase --abort

# Cherry-Pick: einzelnen Commit übernehmen
git cherry-pick <commit-sha>
```

---

## Remote

```bash
# Remotes anzeigen
git remote -v

# Remote hinzufügen
git remote add origin https://github.com/user/repo.git

# Remote umbenennen
git remote rename origin upstream

# Remote entfernen
git remote remove upstream

# Änderungen vom Remote holen (kein Merge)
git fetch origin

# Holen und mergen
git pull origin main

# Rebase-Pull (sauberere Historie)
git pull --rebase origin main

# Lokale Änderungen pushen
git push origin main

# Branch erstmalig pushen und Tracking setzen
git push -u origin feature/mein-feature

# Force Push (Vorsicht!)
git push --force-with-lease origin feature/mein-feature
```

---

## Log & Historie

```bash
# Kompakte Log-Übersicht
git log --oneline --graph --decorate --all

# Letzte 10 Commits
git log -10

# Commits eines Autors
git log --author="Max"

# Commits die eine Datei betreffen
git log -- src/main.go

# Diff zwischen zwei Branches
git diff main..feature/mein-feature

# Welcher Commit hat Zeile X eingeführt?
git blame src/main.go
```

---

## Rückgängig machen

```bash
# Datei aus Staging entfernen
git restore --staged src/main.go

# Lokale Änderungen einer Datei verwerfen
git restore src/main.go

# Letzten Commit rückgängig machen (Änderungen behalten)
git reset --soft HEAD~1

# Letzten Commit rückgängig machen (Änderungen verwerfen)
git reset --hard HEAD~1

# Einen Commit durch neuen "Revert-Commit" umkehren (sicher für geteilte Branches)
git revert <commit-sha>

# Alle lokalen Änderungen verwerfen
git checkout -- .
```

---

## Stash

```bash
# Aktuelle Änderungen zwischenspeichern
git stash

# Mit Beschreibung stashen
git stash push -m "WIP: Fehlerbehandlung"

# Stash-Liste anzeigen
git stash list

# Letzten Stash anwenden (behalten)
git stash apply

# Letzten Stash anwenden und löschen
git stash pop

# Bestimmten Stash anwenden
git stash apply stash@{2}

# Stash löschen
git stash drop stash@{0}

# Alle Stashes löschen
git stash clear
```

---

## Tags

```bash
# Alle Tags anzeigen
git tag

# Lightweight Tag erstellen
git tag v1.0.0

# Annotierter Tag (mit Nachricht)
git tag -a v1.0.0 -m "Release v1.0.0"

# Tag pushen
git push origin v1.0.0

# Alle Tags pushen
git push origin --tags

# Tag löschen (lokal + remote)
git tag -d v1.0.0
git push origin --delete v1.0.0
```

---

## .gitignore

```bash
# Datei aus Tracking entfernen (ohne zu löschen)
git rm --cached .env

# .gitignore-Muster testen
git check-ignore -v meine-datei.log

# Globale .gitignore setzen
git config --global core.excludesfile ~/.gitignore_global
```

---

## Nützliche Shortcuts

```bash
# Alle Branches die gemergt sind (aufräumen)
git branch --merged | grep -v "\*\|main\|master" | xargs git branch -d

# Reflog: jede Aktion der letzten Zeit
git reflog

# Datei aus einem anderen Branch übernehmen
git checkout other-branch -- path/to/file

# Submodule initialisieren und aktualisieren
git submodule update --init --recursive
```

---

## Conventional Commits (Empfehlung)

```
feat:     neues Feature
fix:      Bugfix
docs:     Dokumentation
style:    Formatierung, kein Logik-Änderung
refactor: Refactoring ohne Feature/Fix
test:     Tests hinzufügen/ändern
chore:    Build, Dependencies, Tooling
ci:       CI/CD-Konfiguration
perf:     Performance-Verbesserung
```
