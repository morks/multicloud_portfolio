# =============================================================================
# GitLab CLI (glab) — Shell Completion & Aliases
# Requires: glab (brew install glab)
# =============================================================================

if command -v glab > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(glab completion --shell zsh)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(glab completion --shell bash)" 2>/dev/null || true
  fi

  # Useful aliases
  alias gmrs='glab mr list'               # list merge requests
  alias gci='glab ci view'               # view CI pipeline for current branch
  alias gpipe='glab pipeline list'       # list pipelines
  alias gissues='glab issue list'        # list issues
fi
