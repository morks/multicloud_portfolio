# =============================================================================
# OpenStack CLI + OTC (Telekom Cloud) — Shell Completion
# Requires: openstack (pip install python-openstackclient)
#           otc     (pip install python-otcextensions)
# Both use argcomplete for completion.
# =============================================================================

_register_argcomplete() {
  local _cmd="$1"
  if command -v "$_cmd" > /dev/null 2>&1 && command -v register-python-argcomplete > /dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
      autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
    fi
    eval "$(register-python-argcomplete "$_cmd")" 2>/dev/null || true
  fi
}

_register_argcomplete openstack
_register_argcomplete otc

unset -f _register_argcomplete 2>/dev/null || true
