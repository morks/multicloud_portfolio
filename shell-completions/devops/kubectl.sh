# =============================================================================
# kubectl + k alias + oc (OpenShift) — Shell Completion
# Requires: kubectl (brew install kubectl)
#           oc      (brew install openshift-cli)
# =============================================================================

if command -v kubectl > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(kubectl completion zsh)" 2>/dev/null || true
    # Short alias k with same completion
    alias k='kubectl'
    (( ${+functions[compdef]} )) && compdef k=kubectl 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(kubectl completion bash)" 2>/dev/null || true
    alias k='kubectl'
    complete -F __start_kubectl k 2>/dev/null || true
  fi
fi

# OpenShift CLI (oc)
if command -v oc > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(oc completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(oc completion bash)" 2>/dev/null || true
  fi
fi
