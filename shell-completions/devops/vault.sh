# =============================================================================
# HashiCorp Vault — Shell Completion
# Requires: vault (brew install vault)
# =============================================================================

if command -v vault > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
    complete -C vault vault
  elif [ -n "$BASH_VERSION" ]; then
    complete -C vault vault
  fi
fi
