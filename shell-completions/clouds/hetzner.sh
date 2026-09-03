# =============================================================================
# Hetzner Cloud CLI — Shell Completion
# Requires: hcloud (brew install hcloud)
# =============================================================================

if command -v hcloud > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(hcloud completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(hcloud completion bash)" 2>/dev/null || true
  fi
fi
