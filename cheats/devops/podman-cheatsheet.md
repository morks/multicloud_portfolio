# Podman Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS via Homebrew)
brew install podman

# Initialize the Podman machine (macOS – runs a lightweight VM)
podman machine init

# Start the Podman machine
podman machine start

# Stop the Podman machine
podman machine stop

# Remove the Podman machine
podman machine rm

# List Podman machines
podman machine list

# Check Podman version
podman --version
podman version          # detailed client/server info

# Show system information
podman info

# Rootless setup on Linux (user namespace mapping)
# Ensure /etc/subuid and /etc/subgid have entries for your user
grep $USER /etc/subuid /etc/subgid

# Migrate storage after Podman upgrade (rootless)
podman system migrate

# Enable socket activation for Docker-compatible API (Linux)
systemctl --user enable --now podman.socket

# Verify socket is active
systemctl --user status podman.socket

# Point DOCKER_HOST to Podman socket (for Docker-compatible tools)
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

---

## Images

```bash
# Pull image from registry
podman pull nginx:alpine
podman pull docker.io/library/golang:1.22

# List local images
podman images
podman image ls

# Build image from Containerfile or Dockerfile (current directory)
podman build -t my-app:1.0.0 .

# Build with a specific file name
podman build -f Containerfile.prod -t my-app:prod .

# Pass build arguments
podman build --build-arg GO_VERSION=1.22 -t my-app .

# Tag image
podman tag my-app:1.0.0 registry.example.com/my-app:1.0.0

# Push image to registry
podman push registry.example.com/my-app:1.0.0

# Remove image
podman rmi my-app:1.0.0

# Force remove (even if containers depend on it)
podman rmi -f my-app:1.0.0

# Remove all unused images
podman image prune

# Remove all images not referenced by a container
podman image prune -a

# Inspect image metadata
podman image inspect nginx:alpine

# Search registries for an image
podman search nginx
podman search --filter=is-official nginx

# Show image layer history
podman history my-app:1.0.0

# Save image to a tar archive
podman save -o my-app.tar my-app:1.0.0

# Load image from a tar archive
podman load -i my-app.tar

# Sign an image (requires GPG key setup)
podman image sign --sign-by user@example.com docker://registry.example.com/my-app:1.0.0

# Verify a signed image
podman image verify docker://registry.example.com/my-app:1.0.0
```

---

## Containers

```bash
# Run a container (foreground, auto-remove on exit)
podman run --rm nginx:alpine

# Run in background (detached)
podman run -d --name my-container nginx:alpine

# Interactive shell
podman run -it --rm ubuntu:22.04 bash

# Port mapping (host:container)
podman run -d -p 8080:80 --name my-app nginx:alpine

# Bind mount (host path:container path)
podman run -d -v $(pwd)/html:/usr/share/nginx/html:ro --name my-app nginx:alpine

# Named volume
podman run -d -v my-data:/var/lib/postgresql/data --name my-db postgres:16

# Pass environment variables
podman run -d -e DB_HOST=localhost -e DB_PORT=5432 --name my-app my-app:1.0.0

# Pass env file
podman run -d --env-file .env --name my-app my-app:1.0.0

# Run as specific user
podman run -d --user 1001:1001 --name my-app my-app:1.0.0

# Attach to a specific network
podman run -d --network my-net --name my-app my-app:1.0.0

# Resource limits
podman run -d --memory="512m" --cpus="1.0" --name my-app my-app:1.0.0

# List running containers
podman ps

# List all containers (including stopped)
podman ps -a

# Start / stop / restart a container
podman start my-container
podman stop my-container
podman restart my-container

# Kill container with signal
podman kill --signal SIGTERM my-container

# Remove a stopped container
podman rm my-container

# Force remove (even if running)
podman rm -f my-container

# Execute a command in a running container
podman exec -it my-container bash
podman exec -it my-container sh      # for Alpine-based images

# Stream logs
podman logs -f my-container

# Show last 50 log lines
podman logs --tail 50 my-container

# Inspect container metadata
podman inspect my-container

# Copy file from container to host
podman cp my-container:/etc/nginx/nginx.conf ./nginx.conf

# Copy file from host into container
podman cp ./nginx.conf my-container:/etc/nginx/nginx.conf

# Show live resource usage stats
podman stats

# Show stats for a specific container
podman stats my-container

# Show processes running inside a container
podman top my-container
```

---

## Pods

```bash
# Create a pod
podman pod create --name my-pod

# Create a pod with port mapping
podman pod create --name my-pod -p 8080:80

# List pods
podman pod ps
podman pod list

# Start / stop / restart a pod
podman pod start my-pod
podman pod stop my-pod
podman pod restart my-pod

# Remove a pod (and all its containers)
podman pod rm my-pod

# Force remove a running pod
podman pod rm -f my-pod

# Inspect pod details
podman pod inspect my-pod

# Add a container to an existing pod
podman run -d --pod my-pod --name my-app my-app:1.0.0
podman run -d --pod my-pod --name my-db postgres:16

# Show containers inside a pod
podman pod inspect my-pod --format '{{.Containers}}'

# The infra container handles networking for the pod (auto-created)
# Disable infra container (advanced, loses shared network)
podman pod create --name my-pod --infra=false

# Containers in the same pod share localhost
# Example: app on :8080 can reach db on localhost:5432

# Generate Kubernetes YAML from a pod
podman generate kube my-pod > my-pod.yaml

# Export all pods as Kubernetes YAML
podman generate kube --service my-pod > my-pod-with-service.yaml
```

---

## Volumes & Bind Mounts

```bash
# Create a named volume
podman volume create my-data

# List volumes
podman volume ls

# Inspect a volume
podman volume inspect my-data

# Remove a volume
podman volume rm my-data

# Remove all unused volumes
podman volume prune

# Use a named volume in a container
podman run -d -v my-data:/app/data --name my-app my-app:1.0.0

# Bind mount (absolute path on host)
podman run -d -v /home/user/config:/app/config --name my-app my-app:1.0.0

# Read-only bind mount
podman run -d -v /home/user/config:/app/config:ro --name my-app my-app:1.0.0

# SELinux label – shared between multiple containers (:z)
podman run -d -v /home/user/data:/app/data:z --name my-app my-app:1.0.0

# SELinux label – private/unshared (:Z)
podman run -d -v /home/user/data:/app/data:Z --name my-app my-app:1.0.0

# Preserve host UID/GID mapping in rootless mode
podman run -d -v /home/user/data:/app/data:U --name my-app my-app:1.0.0
```

---

## Networks

```bash
# List networks
podman network ls

# Create a user-defined bridge network
podman network create my-net

# Create network with custom subnet
podman network create --subnet 192.168.100.0/24 my-net

# Inspect a network
podman network inspect my-net

# Remove a network
podman network rm my-net

# Remove all unused networks
podman network prune

# Connect a running container to a network
podman network connect my-net my-container

# Disconnect a container from a network
podman network disconnect my-net my-container

# Host network (shares host network stack, rootful only)
podman run -d --network=host --name my-app my-app:1.0.0

# No networking
podman run -d --network=none --name my-app my-app:1.0.0

# slirp4netns – default rootless networking driver
podman run -d --network=slirp4netns --name my-app my-app:1.0.0

# DNS resolution within user-defined networks (automatic)
# Containers on the same network resolve each other by name
podman run -d --network my-net --name my-db postgres:16
podman run -d --network my-net --name my-app \
  -e DB_HOST=my-db my-app:1.0.0    # my-db resolves via DNS
```

---

## Podman Compose

```bash
# Install podman-compose (Python-based)
pip3 install podman-compose

# Or via Homebrew (macOS)
brew install podman-compose

# Start services (foreground)
podman-compose up

# Start in background
podman-compose up -d

# Stop and remove containers
podman-compose down

# Stop and remove containers plus volumes
podman-compose down -v

# Show status
podman-compose ps

# View logs
podman-compose logs
podman-compose logs -f my-app        # follow specific service

# Build images without starting
podman-compose build

# Rebuild and start
podman-compose up -d --build

# Run a one-off command in a service
podman-compose run --rm my-app sh

# docker-compose.yml is fully compatible; no file changes needed
# podman-compose reads docker-compose.yml by default
```

---

## Generate Kubernetes YAML

```bash
# Generate Kubernetes Pod YAML from a running Podman pod
podman generate kube my-pod > my-pod.yaml

# Generate YAML including a Service resource
podman generate kube --service my-pod > my-pod-with-service.yaml

# Generate YAML from a single container (not in a pod)
podman generate kube my-container > my-container.yaml

# Deploy resources from a Kubernetes YAML file
podman play kube my-pod.yaml

# Deploy and start in background
podman play kube --start my-pod.yaml

# Tear down resources created by play kube
podman play kube --down my-pod.yaml

# Roundtrip example: pod → YAML → deploy
podman pod create --name my-pod -p 8080:80
podman run -d --pod my-pod --name my-app nginx:alpine
podman generate kube my-pod > my-pod.yaml
podman play kube --down my-pod.yaml   # tear down
podman play kube my-pod.yaml          # redeploy from YAML

# Generate systemd units for a container
podman generate systemd --new --name my-container > ~/.config/systemd/user/my-container.service
```

---

## Systemd Integration

```bash
# Generate a systemd service unit for a container
podman generate systemd --new --name my-container \
  > ~/.config/systemd/user/container-my-container.service

# Generate systemd service units for an entire pod
podman generate systemd --new --name my-pod \
  > ~/.config/systemd/user/pod-my-pod.service

# Reload systemd and enable the unit
systemctl --user daemon-reload
systemctl --user enable --now container-my-container.service

# Check status
systemctl --user status container-my-container.service

# View logs via journald
journalctl --user -u container-my-container.service -f

# Podman auto-update (update containers from registry automatically)
# Requires io.containers.autoupdate=registry label on container
podman run -d \
  --label io.containers.autoupdate=registry \
  --name my-app my-app:1.0.0

# Trigger auto-update manually
podman auto-update

# Quadlet – declarative systemd integration (Podman 4.4+)
# Place .container files in /etc/containers/systemd/ (rootful)
# or ~/.config/containers/systemd/ (rootless)

# Example: ~/.config/containers/systemd/my-app.container
cat > ~/.config/containers/systemd/my-app.container << 'EOF'
[Unit]
Description=My Application Container

[Container]
Image=my-app:1.0.0
PublishPort=8080:80
Volume=my-data:/app/data
Environment=APP_ENV=production

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF

# Generate and start the Quadlet unit
systemctl --user daemon-reload
systemctl --user enable --now my-app.service

# Example: ~/.config/containers/systemd/my-pod.pod (Quadlet pod)
cat > ~/.config/containers/systemd/my-pod.pod << 'EOF'
[Pod]
PublishPort=8080:80
EOF
```

---

## Podman vs Docker

| Feature | Podman | Docker |
|---|---|---|
| Daemon | No daemon (daemonless) | Requires dockerd daemon |
| Root | Rootless by default | Requires root (or docker group) |
| Pod support | Native (Kubernetes-compatible) | No native pod concept |
| Socket path (Linux) | `$XDG_RUNTIME_DIR/podman/podman.sock` | `/var/run/docker.sock` |
| Compose | `podman-compose` (separate install) | `docker compose` (plugin) |
| systemd integration | Native (Quadlet, generate systemd) | Limited |
| Image format | OCI-compliant | OCI-compliant |
| K8s YAML | `podman generate kube` / `play kube` | Not built-in |

```bash
# Use Podman as a drop-in Docker replacement
alias docker=podman

# Make the alias permanent
echo 'alias docker=podman' >> ~/.zshrc
source ~/.zshrc

# Docker socket compatibility (rootless, Linux)
# Tools expecting /var/run/docker.sock can use:
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock

# Or create a symlink (may require root)
sudo ln -s $XDG_RUNTIME_DIR/podman/podman.sock /var/run/docker.sock

# macOS: point Docker socket to Podman machine socket
export DOCKER_HOST=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
```

---

## Registry & Authentication

```bash
# Log in to Docker Hub
podman login docker.io

# Log in to a private registry
podman login registry.example.com

# Log in to GitHub Container Registry
echo $GITHUB_TOKEN | podman login ghcr.io -u USERNAME --password-stdin

# Log in to GitLab Registry
podman login registry.gitlab.com -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD

# Log out
podman logout registry.example.com

# Search a registry
podman search nginx
podman search --filter=is-official --limit 5 nginx

# Pull from a specific registry explicitly
podman pull docker.io/library/nginx:alpine
podman pull ghcr.io/my-org/my-app:latest

# Configure unqualified image search registries
# Edit /etc/containers/registries.conf or ~/.config/containers/registries.conf
cat /etc/containers/registries.conf

# Example registries.conf snippet
# [registries.search]
# registries = ["docker.io", "quay.io", "ghcr.io"]

# Configure a registry mirror
# [[registry]]
# prefix = "docker.io"
# location = "mirror.example.com"
# [[registry.mirror]]
# location = "docker.io"

# Show configured registries
podman info | grep -A10 registries
```

---

## Tips & Tricks

```bash
# Custom ps output format
podman ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# JSON output for scripting
podman ps --format json | jq '.[].Names'

# Log driver: send container logs to journald
podman run -d --log-driver journald --name my-app my-app:1.0.0

# Read journald logs for a container
journalctl CONTAINER_NAME=my-app -f

# Secrets management
podman secret create db-password ./db-password.txt

# List secrets
podman secret ls

# Inspect a secret (metadata only, not the value)
podman secret inspect db-password

# Use a secret in a container
podman run -d --secret db-password --name my-app my-app:1.0.0

# Remove a secret
podman secret rm db-password

# Rootless: preserve host UID in container (useful for bind mounts)
PODMAN_USERNS=keep-id podman run -d -v $(pwd)/data:/app/data --name my-app my-app:1.0.0

# Or with flag
podman run -d --userns=keep-id -v $(pwd)/data:/app/data --name my-app my-app:1.0.0

# Rootful vs Rootless comparison
# Rootless: runs as current user, no /var/run/docker.sock, better security
# Rootful:  full system access, required for --network=host, port < 1024
podman run --rm --user root nginx:alpine    # rootless: maps to your UID on host
sudo podman run --rm nginx:alpine           # rootful: runs as real root

# Disk usage overview
podman system df

# Show verbose disk usage
podman system df -v

# Clean up everything unused (images, containers, pods, volumes, networks)
podman system prune

# Clean up everything including volumes (caution!)
podman system prune -a --volumes

# Find container IP address
podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-container

# Stop all running containers
podman stop $(podman ps -q)

# Remove all stopped containers
podman rm $(podman ps -aq --filter status=exited)

# Pull and run with automatic architecture detection (multi-arch)
podman run --platform linux/amd64 --rm my-app:1.0.0

# Enable BuildKit-style builds (Buildah integration)
podman build --layers -t my-app:1.0.0 .

# Run Podman inside a container (rootful, for CI/CD)
podman run --privileged --rm quay.io/podman/stable podman run alpine echo "hello"
```
