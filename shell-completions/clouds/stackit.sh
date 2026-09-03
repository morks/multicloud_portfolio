# =============================================================================
# STACKIT CLI — Shell Completion
# Requires: stackit CLI (https://github.com/stackitcloud/stackit-cli)
# =============================================================================

if command -v stackit > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(stackit completion zsh)" 2>/dev/null || true
    # Enable compdef if not already loaded
    (( ${+functions[compdef]} )) || { autoload -Uz compinit && compinit 2>/dev/null || true }
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(stackit completion bash)" 2>/dev/null || true
  fi
fi
