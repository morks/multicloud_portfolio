# =============================================================================
# AWS CLI — Shell Completion
# Requires: aws CLI v2 (aws_completer included in the install)
# =============================================================================

if command -v aws_completer > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
    complete -C aws_completer aws
  elif [ -n "$BASH_VERSION" ]; then
    complete -C aws_completer aws
  fi
fi
