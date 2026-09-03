# =============================================================================
# Terraform + OpenTofu — Shell Completion
# Requires: terraform (brew install terraform)
#           tofu      (brew install opentofu)
# =============================================================================

if command -v terraform > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
    complete -C terraform terraform
  elif [ -n "$BASH_VERSION" ]; then
    complete -C terraform terraform
  fi
fi

if command -v tofu > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
    complete -C tofu tofu
  elif [ -n "$BASH_VERSION" ]; then
    complete -C tofu tofu
  fi
fi
