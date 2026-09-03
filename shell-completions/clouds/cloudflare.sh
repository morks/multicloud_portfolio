# =============================================================================
# Cloudflare — Shell Completion
# wrangler: supports `wrangler completion` (Workers CLI)
# flarectl: no native completion support
# =============================================================================

if command -v wrangler > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(wrangler completion)" 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(wrangler completion)" 2>/dev/null || true
  fi
fi
