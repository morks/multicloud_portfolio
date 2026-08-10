# GitLab Cheat Sheet

## GitLab CLI (`glab`) – Installation & Login

```bash
# Installation (macOS)
brew install glab

# Authenticate (GitLab.com)
glab auth login

# Authenticate against self-hosted GitLab
glab auth login --hostname gitlab.meinefirma.de

# Check status
glab auth status
```

---

## Repositories / Projects

```bash
# Clone repo
glab repo clone gruppe/projekt

# Create new project
glab repo create my-project --private

# Fork project
glab repo fork gruppe/projekt

# Show project info
glab repo view gruppe/projekt

# Open in browser
glab repo view --web
```

---

## Merge Requests (MR)

```bash
# Create MR (interactive)
glab mr create

# Create MR directly with title
glab mr create --title "feat: new feature" --description "Description..." --target-branch main

# MR as draft
glab mr create --draft

# Show all open MRs
glab mr list

# Show MR details
glab mr view 42

# Check out MR
glab mr checkout 42

# Merge MR
glab mr merge 42
glab mr merge 42 --squash
glab mr merge 42 --rebase

# Close MR
glab mr close 42

# MR status (pipeline checks)
glab mr checks 42

# Add reviewer
glab mr update 42 --reviewer colleague
```

---

## Issues

```bash
# Show all open issues
glab issue list

# Create issue
glab issue create --title "Bug: error on login" --description "Steps to reproduce..."

# Issue with label and assignee
glab issue create --title "Task" --label "enhancement" --assignee @me

# Show issue
glab issue view 10

# Close issue
glab issue close 10

# Reopen issue
glab issue reopen 10

# Comment on issue
glab issue note 10 --message "Check out branch feature/fix-login"
```

---

## CI/CD Pipelines

```bash
# Show recent pipelines
glab ci list

# Show pipeline details
glab ci view

# Start pipeline for current branch
glab ci run

# Show pipeline log for a job
glab ci trace

# Cancel pipeline
glab ci cancel

# Open pipeline in browser
glab ci view --web

# Download job artifacts
glab ci artifact <job-name>
```

---

## GitLab CI/CD – `.gitlab-ci.yml` Quick Reference

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  GO_VERSION: "1.22"

# Reusable template
.base:
  image: golang:${GO_VERSION}
  before_script:
    - go env

build:
  extends: .base
  stage: build
  script:
    - go build ./...
  artifacts:
    paths:
      - bin/
    expire_in: 1 hour

test:
  extends: .base
  stage: test
  script:
    - go test -v ./...
  coverage: '/coverage: \d+\.\d+%/'

deploy-staging:
  stage: deploy
  script:
    - ./deploy.sh staging
  environment:
    name: staging
    url: https://staging.meinapp.de
  only:
    - develop

deploy-prod:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://meinapp.de
  when: manual                  # manual trigger
  only:
    - main
```

---

## Important CI/CD Keywords

| Keyword | Description |
|---|---|
| `stages` | Order of stages |
| `image` | Docker image for the job |
| `script` | Commands in the job |
| `before_script` | Run before each job |
| `after_script` | Run after each job |
| `artifacts` | Pass files between jobs |
| `cache` | Cache dependencies |
| `only` / `except` | Branch filters (deprecated) |
| `rules` | Modern job conditions |
| `needs` | Job dependencies (DAG) |
| `when` | `always`, `on_failure`, `manual` |
| `environment` | Define deployment environment |
| `include` | Include external YAML files |
| `extends` | Template inheritance |

---

## Environments & Deployments

```yaml
# Environment with auto-stop
deploy-review:
  script:
    - ./deploy-review.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.meinapp.de
    on_stop: stop-review
    auto_stop_in: 1 week

stop-review:
  script:
    - ./teardown-review.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

---

## Predefined CI/CD Variables (Selection)

```bash
CI_COMMIT_BRANCH       # Branch name
CI_COMMIT_SHA          # Full commit hash
CI_COMMIT_SHORT_SHA    # Short commit hash
CI_COMMIT_TAG          # Tag name (when pipeline triggered by tag)
CI_PIPELINE_ID         # Pipeline ID
CI_JOB_ID              # Job ID
CI_PROJECT_PATH        # group/project
CI_PROJECT_URL         # Project URL
CI_REGISTRY            # Docker registry URL
CI_REGISTRY_IMAGE      # Image path in registry
CI_REGISTRY_USER       # Registry login
CI_REGISTRY_PASSWORD   # Registry password
GITLAB_USER_EMAIL      # Email of the triggering user
```

---

## Container Registry

```bash
# Log in to GitLab registry
docker login registry.gitlab.com -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD

# Build and push image (in CI)
docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

# List images in the registry
glab api projects/:id/registry/repositories

# Show image tags
glab api projects/:id/registry/repositories/:repo_id/tags
```

---

## Secrets & CI/CD Variables (CLI)

```bash
# Set variable (project level)
glab variable set API_KEY --value "my-secret"

# Variable as protected + masked
glab variable set API_KEY --value "my-secret" --protected --masked

# List variables
glab variable list

# Delete variable
glab variable delete API_KEY
```

---

## Useful `glab` Tricks

```bash
# Status of current branch (MR + pipeline)
glab mr status

# Show diff of an MR
glab mr diff 42

# Call GitLab API directly
glab api projects/:id/issues --jq '.[].title'

# Create alias
glab alias set mrs 'mr list --assignee @me'
glab mrs
```
