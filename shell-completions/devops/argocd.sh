# =============================================================================
# ArgoCD CLI — Shell Completion
# Requires: argocd (brew install argocd)
# =============================================================================

if command -v argocd > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(argocd completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(argocd completion bash)" 2>/dev/null || true
  fi
fi
