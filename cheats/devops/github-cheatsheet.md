# GitHub Cheat Sheet

## GitHub CLI (`gh`) – Installation & Login

```bash
# Installation (macOS)
brew install gh

# Authenticate
gh auth login

# Check status
gh auth status

# Refresh token
gh auth refresh
```

---

## Repositories

```bash
# Clone repo
gh repo clone user/repo

# Create new repo (interactive)
gh repo create

# Create new private repo directly
gh repo create my-repo --private

# Fork repo
gh repo fork user/repo

# Show repo info
gh repo view user/repo

# Open repo in browser
gh repo view --web

# List repos
gh repo list user --limit 20
```

---

## Pull Requests

```bash
# Create PR (interactive)
gh pr create

# Create PR with title and body directly
gh pr create --title "feat: new feature" --body "Description..." --base main

# Create PR as draft
gh pr create --draft

# Show all open PRs
gh pr list

# Filtered PRs (e.g. assigned to me)
gh pr list --assignee @me

# Show PR details
gh pr view 42

# Open PR in browser
gh pr view 42 --web

# Check out PR (switch branch locally)
gh pr checkout 42

# Merge PR
gh pr merge 42 --merge
gh pr merge 42 --squash
gh pr merge 42 --rebase

# Close PR
gh pr close 42

# PR status (CI checks)
gh pr checks 42

# Request PR review
gh pr edit 42 --add-reviewer colleague
```

---

## Issues

```bash
# Show all open issues
gh issue list

# Create issue
gh issue create --title "Bug: error on login" --body "Steps to reproduce..."

# Issue with label and assignee
gh issue create --title "Task" --label "enhancement" --assignee @me

# Show issue
gh issue view 10

# Close issue
gh issue close 10

# Reopen issue
gh issue reopen 10

# Search issues
gh issue list --search "login error"

# Comment on issue
gh issue comment 10 --body "Check out branch feature/fix-login"
```

---

## GitHub Actions (Workflows)

```bash
# List workflows
gh workflow list

# Trigger workflow manually
gh workflow run deploy.yml

# Workflow with input parameter
gh workflow run deploy.yml --field environment=production

# Show running and past runs
gh run list

# Show run details
gh run view 1234567890

# Show logs for a run
gh run view 1234567890 --log

# Cancel run
gh run cancel 1234567890

# Open run in browser
gh run view 1234567890 --web
```

---

## Releases

```bash
# List releases
gh release list

# Show release
gh release view v1.0.0

# Create new release
gh release create v1.0.0 --title "v1.0.0" --notes "Changelog..."

# Create release with artifact upload
gh release create v1.0.0 ./dist/app-linux-amd64 --title "v1.0.0"

# Release as draft
gh release create v1.0.0 --draft

# Prerelease
gh release create v1.1.0-rc1 --prerelease

# Delete release
gh release delete v1.0.0
```

---

## Gists

```bash
# Create gist from file (public)
gh gist create my-script.sh --public

# Private gist
gh gist create my-script.sh

# List gists
gh gist list

# Show gist
gh gist view <gist-id>
```

---

## GitHub Actions – Workflow Syntax (Quick Reference)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:          # trigger manually

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.22"

      - name: Build
        run: go build ./...

      - name: Test
        run: go test ./...

  deploy:
    needs: build               # waits for build job
    runs-on: ubuntu-latest
    environment: production    # protects deployment with approval
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

---

## Secrets & Variables (CLI)

```bash
# Set secret (repo)
gh secret set API_KEY

# Secret from file
gh secret set API_KEY < secret.txt

# List secrets
gh secret list

# Delete secret
gh secret delete API_KEY

# Set env variable
gh variable set ENV_NAME --body "production"
```

---

## Useful `gh` Tricks

```bash
# Show current PR for the branch
gh pr status

# Show diff of a PR
gh pr diff 42

# Repo statistics (stars, forks, watchers)
gh repo view user/repo --json stargazerCount,forkCount

# Call GitHub API directly
gh api repos/user/repo/issues --jq '.[].title'

# GraphQL query
gh api graphql -f query='{ viewer { login } }'

# Create alias
gh alias set prs 'pr list --assignee @me'
gh prs
```
