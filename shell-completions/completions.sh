# =============================================================================
# Multi-Cloud Portfolio — Shell Auto-Completions
# =============================================================================
# Source this file in your ~/.zshrc or ~/.bashrc:
#   source ~/tools/multicloud_portfolio/shell-completions/completions.sh
#
# Design principles:
#   - Guard per tool: missing CLIs are silently skipped
#   - Shell-detection: ZSH_VERSION / BASH_VERSION controls the code path
#   - OS-agnostic: Homebrew paths resolved via `brew --prefix`; Linux fallback
#   - Idempotent: safe to source multiple times
# =============================================================================

# Resolve directory of this script (works when sourced in bash and zsh)
if [ -n "$ZSH_VERSION" ]; then
  _MC_DIR="${${(%):-%x}:A:h}"
elif [ -n "$BASH_VERSION" ]; then
  _MC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  return 0  # unknown shell — bail out silently
fi

# Source all cloud and devops completion files
for _mc_file in "$_MC_DIR"/clouds/*.sh "$_MC_DIR"/devops/*.sh; do
  [ -f "$_mc_file" ] && source "$_mc_file"
done

unset _MC_DIR _mc_file
