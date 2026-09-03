# =============================================================================
# Azure CLI — Shell Completion
# Requires: az CLI (installed via brew or pip)
# =============================================================================

if command -v az > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    # Homebrew path (macOS)
    if command -v brew > /dev/null 2>&1; then
      _az_completion="$(brew --prefix)/etc/bash_completion.d/az"
      if [ -f "$_az_completion" ]; then
        autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
        source "$_az_completion"
      fi
      unset _az_completion
    fi
    # Fallback: argcomplete (pip install)
    if command -v register-python-argcomplete > /dev/null 2>&1; then
      autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
      eval "$(register-python-argcomplete az)" 2>/dev/null || true
    fi
  elif [ -n "$BASH_VERSION" ]; then
    if command -v brew > /dev/null 2>&1; then
      _az_completion="$(brew --prefix)/etc/bash_completion.d/az"
      [ -f "$_az_completion" ] && source "$_az_completion"
      unset _az_completion
    fi
    if command -v register-python-argcomplete > /dev/null 2>&1; then
      eval "$(register-python-argcomplete az)" 2>/dev/null || true
    fi
  fi
fi
