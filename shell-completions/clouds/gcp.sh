# =============================================================================
# Google Cloud SDK — Shell Completion
# Requires: gcloud (Google Cloud SDK)
# =============================================================================

if command -v gcloud > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    # SDK includes zsh completion via an include file
    _gcloud_inc="$(gcloud info --format='value(installation.sdk_root)' 2>/dev/null)/completion.zsh.inc"
    if [ -f "$_gcloud_inc" ]; then
      source "$_gcloud_inc"
    else
      # Homebrew cask path fallback
      _gcloud_inc_brew="$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
      [ -f "$_gcloud_inc_brew" ] && source "$_gcloud_inc_brew"
      unset _gcloud_inc_brew
    fi
    unset _gcloud_inc
  elif [ -n "$BASH_VERSION" ]; then
    _gcloud_inc="$(gcloud info --format='value(installation.sdk_root)' 2>/dev/null)/completion.bash.inc"
    if [ -f "$_gcloud_inc" ]; then
      source "$_gcloud_inc"
    else
      _gcloud_inc_brew="$(brew --prefix)/share/google-cloud-sdk/completion.bash.inc"
      [ -f "$_gcloud_inc_brew" ] && source "$_gcloud_inc_brew"
      unset _gcloud_inc_brew
    fi
    unset _gcloud_inc
  fi
fi
