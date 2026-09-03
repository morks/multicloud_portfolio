# 🐚 Shell Auto-Completions

Tab-completion for **all CLIs** covered by this portfolio — one `source` line in your rc file, and `git pull` keeps it up to date automatically.

---

## Supported Tools

### ☁️ Cloud CLIs

| File | Tools |
|---|---|
| `clouds/aws.sh` | `aws` (via `aws_completer`) |
| `clouds/azure.sh` | `az` (argcomplete / brew) |
| `clouds/gcp.sh` | `gcloud` (SDK built-in) |
| `clouds/oci.sh` | `oci` (autocomplete script) |
| `clouds/openstack.sh` | `openstack`, `otc` (argcomplete) |
| `clouds/stackit.sh` | `stackit` (built-in completion) |
| `clouds/hetzner.sh` | `hcloud` (built-in completion) |
| `clouds/cloudflare.sh` | `wrangler` (built-in completion) |

### 🛠️ DevOps Tools

| File | Tools |
|---|---|
| `devops/kubectl.sh` | `kubectl`, `k` alias, `oc` (OpenShift) |
| `devops/helm.sh` | `helm` |
| `devops/terraform.sh` | `terraform`, `tofu` (OpenTofu) |
| `devops/argocd.sh` | `argocd` |
| `devops/flux.sh` | `flux` |
| `devops/vault.sh` | `vault` |
| `devops/github.sh` | `gh`, `glab` |
| `devops/extras.sh` | `kubectx`, `kubens`, `stern`, `k9s` |

---

## Setup

```bash
# 1. Clone the repo once
git clone https://github.com/morks/multicloud_portfolio.git ~/tools/multicloud_portfolio

# 2. Add one line to your shell rc file
#    For Zsh:
echo 'source ~/tools/multicloud_portfolio/shell-completions/completions.sh' >> ~/.zshrc

#    For Bash:
echo 'source ~/tools/multicloud_portfolio/shell-completions/completions.sh' >> ~/.bashrc

# 3. Reload your shell
source ~/.zshrc   # or: source ~/.bashrc

# 4. Verify — try tab-completion for any installed CLI
aws <TAB>
kubectl <TAB>
helm <TAB>
```

## Keeping Completions Up To Date

```bash
cd ~/tools/multicloud_portfolio && git pull
# No further action needed — completions reload with your next shell session
```

---

## Design Notes

- **Zero noise**: Tools not installed on your system are silently skipped — no errors, no warnings.
- **Shell-aware**: Each script detects `$ZSH_VERSION` / `$BASH_VERSION` and uses the right completion API.
- **OS-agnostic**: Homebrew paths are resolved via `$(brew --prefix)` with Linux paths as fallback.
- **Idempotent**: Sourcing `completions.sh` multiple times is safe.
- **No shebang**: All files are meant to be *sourced*, not executed directly.

---

## Troubleshooting

### Completion not working after setup

```bash
# Confirm the file is being sourced
grep 'completions.sh' ~/.zshrc ~/.bashrc 2>/dev/null

# Reload manually
source ~/tools/multicloud_portfolio/shell-completions/completions.sh

# Check if the CLI is installed
command -v aws && echo "aws found" || echo "aws not installed"
```

### Zsh: `compinit` warnings

If you see warnings about insecure directories, add this **before** the source line in `~/.zshrc`:

```zsh
autoload -Uz compinit && compinit
```

### AWS completion is slow

The `aws_completer` can be slow on first invocation. This is normal — subsequent calls use the cache.
