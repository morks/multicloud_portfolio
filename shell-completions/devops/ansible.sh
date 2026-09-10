# =============================================================================
# Ansible — Shell Completion & Aliases
# Requires: ansible (pip install ansible)
#
# Ansible uses argcomplete for tab completion.
# Setup (one-time):
#   pip install argcomplete
#   activate-global-python-argcomplete   # system-wide (requires sudo on some systems)
#   # OR per-shell (zsh):
#   eval "$(register-python-argcomplete ansible)"
#   eval "$(register-python-argcomplete ansible-playbook)"
#   eval "$(register-python-argcomplete ansible-galaxy)"
# =============================================================================

if command -v ansible > /dev/null 2>&1; then
  # Enable argcomplete if register-python-argcomplete is available
  if command -v register-python-argcomplete > /dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
      autoload -Uz bashcompinit && bashcompinit 2>/dev/null || true
    fi
    eval "$(register-python-argcomplete ansible)" 2>/dev/null || true
    eval "$(register-python-argcomplete ansible-playbook)" 2>/dev/null || true
    eval "$(register-python-argcomplete ansible-galaxy)" 2>/dev/null || true
    eval "$(register-python-argcomplete ansible-vault)" 2>/dev/null || true
    eval "$(register-python-argcomplete ansible-inventory)" 2>/dev/null || true
  fi

  # Useful aliases
  alias ap='ansible-playbook'                    # run a playbook
  alias av='ansible-vault'                       # manage encrypted files
  alias ai='ansible-inventory'                   # inspect inventory
  alias ag='ansible-galaxy'                      # install roles/collections
  alias acheck='ansible-playbook --check --diff' # dry-run with diff output
fi
