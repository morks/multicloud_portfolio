# =============================================================================
# Oracle Cloud CLI — Shell Completion
# Requires: oci (pip install oci-cli)
# =============================================================================

if command -v oci > /dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    # OCI CLI ships a bash-compatible autocomplete script
    _oci_complete="${HOME}/lib/oracle-cli/lib/python3.11/site-packages/oci_cli/bin/oci_autocomplete.sh"
    if [ ! -f "$_oci_complete" ]; then
      # Try common alternative locations
      _oci_complete="$(pip show oci-cli 2>/dev/null | awk '/^Location/{print $2}')/oci_cli/bin/oci_autocomplete.sh"
    fi
    if [ -f "$_oci_complete" ]; then
      autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
      source "$_oci_complete"
    fi
    unset _oci_complete
  elif [ -n "$BASH_VERSION" ]; then
    _oci_complete="${HOME}/lib/oracle-cli/lib/python3.11/site-packages/oci_cli/bin/oci_autocomplete.sh"
    if [ ! -f "$_oci_complete" ]; then
      _oci_complete="$(pip show oci-cli 2>/dev/null | awk '/^Location/{print $2}')/oci_cli/bin/oci_autocomplete.sh"
    fi
    [ -f "$_oci_complete" ] && source "$_oci_complete"
    unset _oci_complete
  fi
fi
