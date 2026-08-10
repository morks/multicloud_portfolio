# Docker Cheat Sheet

## Installation & Konfiguration

```bash
# Installation (macOS via Homebrew)
brew install --cask docker

# Docker Desktop starten
open -a Docker

# Version prüfen
docker --version
docker info

# Docker ohne sudo (Linux)
sudo usermod -aG docker $USER
```

---

## Images

```bash
# Image aus Registry pullen
docker pull nginx:alpine
docker pull golang:1.22

# Lokale Images auflisten
docker images
docker image ls

# Image bauen aus Dockerfile (im aktuellen Verzeichnis)
docker build -t mein-app:1.0.0 .

# Mit bestimmtem Dockerfile
docker build -f Dockerfile.prod -t mein-app:prod .

# Build-Argument übergeben
docker build --build-arg GO_VERSION=1.22 -t mein-app .

# Image taggen
docker tag mein-app:1.0.0 registry.beispiel.de/mein-app:1.0.0

# Image pushen
docker push registry.beispiel.de/mein-app:1.0.0

# Image löschen
docker rmi mein-app:1.0.0

# Nicht verwendete Images aufräumen
docker image prune
docker image prune -a        # alle ungenutzten Images
```

---

## Container starten & verwalten

```bash
# Container starten (Vordergrund)
docker run nginx:alpine

# Im Hintergrund starten (detached)
docker run -d nginx:alpine

# Port-Weiterleitung (Host:Container)
docker run -d -p 8080:80 nginx:alpine

# Mit Namen
docker run -d --name mein-nginx -p 8080:80 nginx:alpine

# Umgebungsvariablen übergeben
docker run -d -e DB_HOST=localhost -e DB_PORT=5432 mein-app

# Env-Datei übergeben
docker run -d --env-file .env mein-app

# Volume mounten
docker run -d -v $(pwd)/data:/var/lib/postgresql/data postgres:16

# Named Volume
docker run -d -v pgdata:/var/lib/postgresql/data postgres:16

# Interaktive Shell starten
docker run -it ubuntu:22.04 bash

# Container nach Beenden automatisch löschen
docker run --rm mein-app

# Ressourcen begrenzen
docker run -d --memory="512m" --cpus="1.0" mein-app

# Container mit Restart-Policy
docker run -d --restart unless-stopped nginx:alpine
```

---

## Container inspizieren & verwalten

```bash
# Laufende Container anzeigen
docker ps

# Alle Container (auch gestoppte)
docker ps -a

# Logs anzeigen
docker logs mein-nginx
docker logs -f mein-nginx          # follow (stream)
docker logs --tail 100 mein-nginx  # letzte 100 Zeilen

# Container stoppen / starten / neustarten
docker stop mein-nginx
docker start mein-nginx
docker restart mein-nginx

# Container löschen
docker rm mein-nginx
docker rm -f mein-nginx            # erzwingen (auch wenn laufend)

# Shell in laufendem Container öffnen
docker exec -it mein-nginx bash
docker exec -it mein-nginx sh      # für Alpine

# Befehl in Container ausführen
docker exec mein-nginx nginx -t

# Container-Details anzeigen
docker inspect mein-nginx

# Ressourcen-Nutzung anzeigen
docker stats
docker stats mein-nginx

# Prozesse im Container
docker top mein-nginx

# Port-Mappings anzeigen
docker port mein-nginx

# Dateien aus Container kopieren
docker cp mein-nginx:/etc/nginx/nginx.conf ./nginx.conf

# Dateien in Container kopieren
docker cp ./nginx.conf mein-nginx:/etc/nginx/nginx.conf
```

---

## Dockerfile Referenz

```dockerfile
# Basis-Image
FROM golang:1.22-alpine AS builder

# Maintainer (Label)
LABEL maintainer="max@example.com"
LABEL version="1.0"

# Arbeitsverzeichnis setzen
WORKDIR /app

# Dateien kopieren (Layer-Cache nutzen!)
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build-Argument
ARG VERSION=dev
RUN go build -ldflags "-X main.version=${VERSION}" -o app .

# --- Finales Image (Multi-Stage) ---
FROM alpine:3.19

# Zertifikate für HTTPS
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Nur Binary aus Builder kopieren
COPY --from=builder /app/app .

# Non-root User anlegen
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Port dokumentieren (nur informativ)
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Startbefehl
ENTRYPOINT ["./app"]
CMD ["--port", "8080"]
```

---

## .dockerignore

```
# .dockerignore
.git
.gitignore
*.md
Dockerfile*
docker-compose*
.env
.env.*
node_modules
dist
bin
*.test
*.log
```

---

## Volumes

```bash
# Named Volume erstellen
docker volume create pgdata

# Volumes auflisten
docker volume ls

# Volume-Details anzeigen
docker volume inspect pgdata

# Volume löschen
docker volume rm pgdata

# Ungenutzte Volumes aufräumen
docker volume prune
```

---

## Netzwerke

```bash
# Netzwerke anzeigen
docker network ls

# Netzwerk erstellen
docker network create mein-netz

# Container mit Netzwerk verbinden
docker network connect mein-netz mein-container

# Container vom Netzwerk trennen
docker network disconnect mein-netz mein-container

# Netzwerk löschen
docker network rm mein-netz

# Ungenutzte Netzwerke aufräumen
docker network prune
```

---

## Docker Compose

```bash
# Services starten (Vordergrund)
docker compose up

# Im Hintergrund starten
docker compose up -d

# Neu bauen und starten
docker compose up -d --build

# Services stoppen
docker compose down

# Stoppen und Volumes löschen
docker compose down -v

# Status anzeigen
docker compose ps

# Logs anzeigen
docker compose logs
docker compose logs -f app          # einzelner Service

# Einzelnen Service neustarten
docker compose restart app

# Befehl in Service ausführen
docker compose exec app sh

# Nur bestimmten Service starten
docker compose up -d db
```

---

## docker-compose.yml Beispiel

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      args:
        VERSION: "1.0.0"
    image: mein-app:1.0.0
    container_name: mein-app
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    networks:
      - backend
    volumes:
      - ./uploads:/app/uploads

  db:
    image: postgres:16-alpine
    container_name: mein-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: meinedb
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "dbuser"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

volumes:
  pgdata:

networks:
  backend:
    driver: bridge

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

---

## Registry & Login

```bash
# Docker Hub einloggen
docker login

# Andere Registry
docker login registry.beispiel.de

# GitHub Container Registry
docker login ghcr.io -u USERNAME --password-stdin <<< $GITHUB_TOKEN

# GitLab Registry
docker login registry.gitlab.com -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD

# Ausloggen
docker logout registry.beispiel.de
```

---

## Aufräumen (System bereinigen)

```bash
# Gestoppte Container löschen
docker container prune

# Nicht verwendete Images löschen
docker image prune -a

# Ungenutzte Volumes löschen
docker volume prune

# Ungenutzte Netzwerke löschen
docker network prune

# Alles auf einmal (Vorsicht!)
docker system prune

# Alles inklusive Volumes (Vorsicht!)
docker system prune -a --volumes

# Speicherplatz-Übersicht
docker system df
```

---

## Nützliche Tricks

```bash
# Letzten Container-Fehler ansehen
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"

# Image-Größe analysieren (Dive-Tool)
brew install dive
dive mein-app:1.0.0

# Container-IP herausfinden
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mein-container

# Alle Container stoppen
docker stop $(docker ps -q)

# Alle Container löschen
docker rm $(docker ps -aq)

# Image-History anzeigen (Layer-Analyse)
docker history mein-app:1.0.0

# Multi-Arch Image bauen (BuildKit)
docker buildx build --platform linux/amd64,linux/arm64 -t mein-app:multi --push .
```
