# =============================================================================
# Podman — Shell Completion & Aliases
# Requires: podman (brew install podman)
# =============================================================================

if command -v podman > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(podman completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(podman completion bash)" 2>/dev/null || true
  fi

  # Useful aliases
  alias pd='podman'                       # short alias
  alias pdps='podman ps'                  # list running containers
  alias pdpsa='podman ps -a'             # list all containers (incl. stopped)
  alias pdimg='podman images'            # list local images
  alias pdrm='podman rm'                 # remove container
  alias pdrmi='podman rmi'              # remove image
  alias pdlogs='podman logs -f'          # follow container logs
  alias pdexec='podman exec -it'         # exec interactive shell in container
fi
