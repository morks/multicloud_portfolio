# =============================================================================
# FluxCD CLI — Shell Completion
# Requires: flux (brew install fluxcd/tap/flux)
# =============================================================================

if command -v flux > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(flux completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(flux completion bash)" 2>/dev/null || true
  fi
fi
