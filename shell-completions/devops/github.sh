# =============================================================================
# GitHub CLI (gh) + GitLab CLI (glab) — Shell Completion
# Requires: gh   (brew install gh)
#           glab (brew install glab)
# =============================================================================

if command -v gh > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(gh completion -s zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(gh completion -s bash)" 2>/dev/null || true
  fi
fi

if command -v glab > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(glab completion -s zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(glab completion -s bash)" 2>/dev/null || true
  fi
fi
