# =============================================================================
# Helm — Shell Completion
# Requires: helm (brew install helm)
# =============================================================================

if command -v helm > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(helm completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(helm completion bash)" 2>/dev/null || true
  fi
fi
