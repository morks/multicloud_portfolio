# =============================================================================
# Kubernetes Extras — Shell Completion
# kubectx / kubens: brew install kubectx
# stern:            brew install stern
# k9s:              no native shell completion (TUI tool)
# =============================================================================

# kubectx — switch Kubernetes contexts
if command -v kubectx > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    # Homebrew installs zsh completion automatically via site-functions
    # Manual fallback: load from brew completions dir
    if command -v brew > /dev/null 2>&1; then
      _kubectx_comp="$(brew --prefix)/share/zsh/site-functions/_kubectx"
      [ -f "$_kubectx_comp" ] && source "$_kubectx_comp" 2>/dev/null || true
      unset _kubectx_comp
    fi
  elif [ -n "$BASH_VERSION" ]; then
    if command -v brew > /dev/null 2>&1; then
      _kubectx_comp="$(brew --prefix)/etc/bash_completion.d/kubectx"
      [ -f "$_kubectx_comp" ] && source "$_kubectx_comp" 2>/dev/null || true
      unset _kubectx_comp
    fi
  fi
fi

# kubens — switch Kubernetes namespaces (ships with kubectx)
if command -v kubens > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    if command -v brew > /dev/null 2>&1; then
      _kubens_comp="$(brew --prefix)/share/zsh/site-functions/_kubens"
      [ -f "$_kubens_comp" ] && source "$_kubens_comp" 2>/dev/null || true
      unset _kubens_comp
    fi
  elif [ -n "$BASH_VERSION" ]; then
    if command -v brew > /dev/null 2>&1; then
      _kubens_comp="$(brew --prefix)/etc/bash_completion.d/kubens"
      [ -f "$_kubens_comp" ] && source "$_kubens_comp" 2>/dev/null || true
      unset _kubens_comp
    fi
  fi
fi

# stern — multi-pod log tailing
if command -v stern > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(stern --completion zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(stern --completion bash)" 2>/dev/null || true
  fi
fi

# k9s — terminal UI (no shell completion; included here for documentation)
# k9s is a TUI — launch it with just `k9s`
