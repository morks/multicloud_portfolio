# Docker Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS via Homebrew)
brew install --cask docker

# Start Docker Desktop
open -a Docker

# Check version
docker --version
docker info

# Docker without sudo (Linux)
sudo usermod -aG docker $USER
```

---

## Images

```bash
# Pull image from registry
docker pull nginx:alpine
docker pull golang:1.22

# List local images
docker images
docker image ls

# Build image from Dockerfile (in current directory)
docker build -t my-app:1.0.0 .

# With specific Dockerfile
docker build -f Dockerfile.prod -t my-app:prod .

# Pass build argument
docker build --build-arg GO_VERSION=1.22 -t my-app .

# Tag image
docker tag my-app:1.0.0 registry.beispiel.de/my-app:1.0.0

# Push image
docker push registry.beispiel.de/my-app:1.0.0

# Delete image
docker rmi my-app:1.0.0

# Clean up unused images
docker image prune
docker image prune -a        # all unused images
```

---

## Starting & Managing Containers

```bash
# Start container (foreground)
docker run nginx:alpine

# Start in background (detached)
docker run -d nginx:alpine

# Port forwarding (Host:Container)
docker run -d -p 8080:80 nginx:alpine

# With name
docker run -d --name my-nginx -p 8080:80 nginx:alpine

# Pass environment variables
docker run -d -e DB_HOST=localhost -e DB_PORT=5432 my-app

# Pass env file
docker run -d --env-file .env my-app

# Mount volume
docker run -d -v $(pwd)/data:/var/lib/postgresql/data postgres:16

# Named Volume
docker run -d -v pgdata:/var/lib/postgresql/data postgres:16

# Start interactive shell
docker run -it ubuntu:22.04 bash

# Automatically delete container after exit
docker run --rm my-app

# Limit resources
docker run -d --memory="512m" --cpus="1.0" my-app

# Container with restart policy
docker run -d --restart unless-stopped nginx:alpine
```

---

## Inspecting & Managing Containers

```bash
# Show running containers
docker ps

# All containers (including stopped)
docker ps -a

# Show logs
docker logs my-nginx
docker logs -f my-nginx          # follow (stream)
docker logs --tail 100 my-nginx  # last 100 lines

# Stop / start / restart container
docker stop my-nginx
docker start my-nginx
docker restart my-nginx

# Delete container
docker rm my-nginx
docker rm -f my-nginx            # force (even if running)

# Open shell in running container
docker exec -it my-nginx bash
docker exec -it my-nginx sh      # for Alpine

# Execute command in container
docker exec my-nginx nginx -t

# Show container details
docker inspect my-nginx

# Show resource usage
docker stats
docker stats my-nginx

# Processes in container
docker top my-nginx

# Show port mappings
docker port my-nginx

# Copy files from container
docker cp my-nginx:/etc/nginx/nginx.conf ./nginx.conf

# Copy files into container
docker cp ./nginx.conf my-nginx:/etc/nginx/nginx.conf
```

---

## Dockerfile Reference

```dockerfile
# Base image
FROM golang:1.22-alpine AS builder

# Maintainer (Label)
LABEL maintainer="max@example.com"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Copy files (use layer cache!)
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build argument
ARG VERSION=dev
RUN go build -ldflags "-X main.version=${VERSION}" -o app .

# --- Final image (Multi-Stage) ---
FROM alpine:3.19

# Certificates for HTTPS
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy only binary from builder
COPY --from=builder /app/app .

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Document port (informational only)
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Start command
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
# Create named volume
docker volume create pgdata

# List volumes
docker volume ls

# Show volume details
docker volume inspect pgdata

# Delete volume
docker volume rm pgdata

# Clean up unused volumes
docker volume prune
```

---

## Networks

```bash
# Show networks
docker network ls

# Create network
docker network create my-net

# Connect container to network
docker network connect my-net my-container

# Disconnect container from network
docker network disconnect my-net my-container

# Delete network
docker network rm my-net

# Clean up unused networks
docker network prune
```

---

## Docker Compose

```bash
# Start services (foreground)
docker compose up

# Start in background
docker compose up -d

# Rebuild and start
docker compose up -d --build

# Stop services
docker compose down

# Stop and delete volumes
docker compose down -v

# Show status
docker compose ps

# Show logs
docker compose logs
docker compose logs -f app          # single service

# Restart single service
docker compose restart app

# Execute command in service
docker compose exec app sh

# Start only specific service
docker compose up -d db
```

---

## docker-compose.yml Example

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      args:
        VERSION: "1.0.0"
    image: my-app:1.0.0
    container_name: my-app
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
    container_name: my-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: mydb
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
# Log in to Docker Hub
docker login

# Other registry
docker login registry.beispiel.de

# GitHub Container Registry
docker login ghcr.io -u USERNAME --password-stdin <<< $GITHUB_TOKEN

# GitLab Registry
docker login registry.gitlab.com -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD

# Log out
docker logout registry.beispiel.de
```

---

## System Cleanup

```bash
# Delete stopped containers
docker container prune

# Delete unused images
docker image prune -a

# Delete unused volumes
docker volume prune

# Delete unused networks
docker network prune

# Everything at once (caution!)
docker system prune

# Everything including volumes (caution!)
docker system prune -a --volumes

# Disk space overview
docker system df
```

---

## Useful Tricks

```bash
# View last container error
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"

# Analyze image size (Dive tool)
brew install dive
dive my-app:1.0.0

# Find container IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-container

# Stop all containers
docker stop $(docker ps -q)

# Delete all containers
docker rm $(docker ps -aq)

# Show image history (layer analysis)
docker history my-app:1.0.0

# Build multi-arch image (BuildKit)
docker buildx build --platform linux/amd64,linux/arm64 -t my-app:multi --push .
```
