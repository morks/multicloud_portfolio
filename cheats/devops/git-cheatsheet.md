# Git Cheat Sheet

## Installation & Setup

```bash
# Installation (macOS)
brew install git

# Set global identity
git config --global user.name "Max Mustermann"
git config --global user.email "max@example.com"

# Set default editor
git config --global core.editor "code --wait"   # VS Code
git config --global core.editor "vim"

# Set default branch name to main
git config --global init.defaultBranch main

# Show all global settings
git config --global --list

# Generate SSH key
ssh-keygen -t ed25519 -C "max@example.com"
```

---

## Create & Clone Repository

```bash
# Initialize new repo
git init

# Clone existing repo
git clone https://github.com/user/repo.git

# Clone into specific folder
git clone https://github.com/user/repo.git my-folder

# Clone a single branch
git clone --branch develop --single-branch https://github.com/user/repo.git
```

---

## Staging & Commits

```bash
# Show changes (unstaged)
git status
git diff

# Stage all changes
git add .

# Stage single file
git add src/main.go

# Stage interactively (hunk by hunk)
git add -p

# Create commit
git commit -m "feat: add new feature"

# Edit last commit retroactively (message or content)
git commit --amend

# Create empty commit (e.g. to trigger CI)
git commit --allow-empty -m "ci: restart pipeline"
```

---

## Branches

```bash
# Show all branches (local + remote)
git branch -a

# Create and switch to new branch
git switch -c feature/my-feature

# Switch branch
git switch main

# Delete branch (local)
git branch -d feature/my-feature

# Force delete branch
git branch -D feature/my-feature

# Delete remote branch
git push origin --delete feature/my-feature

# Rename branch
git branch -m old-name new-name
```

---

## Merge & Rebase

```bash
# Merge branch into current branch
git merge feature/my-feature

# Merge without fast-forward (always creates merge commit)
git merge --no-ff feature/my-feature

# Abort merge
git merge --abort

# Rebase onto main
git rebase main

# Interactive rebase (rewrite last 3 commits)
git rebase -i HEAD~3

# Abort rebase
git rebase --abort

# Cherry-pick: apply a single commit
git cherry-pick <commit-sha>
```

---

## Remote

```bash
# Show remotes
git remote -v

# Add remote
git remote add origin https://github.com/user/repo.git

# Rename remote
git remote rename origin upstream

# Remove remote
git remote remove upstream

# Fetch changes from remote (no merge)
git fetch origin

# Fetch and merge
git pull origin main

# Rebase pull (cleaner history)
git pull --rebase origin main

# Push local changes
git push origin main

# Push branch for the first time and set tracking
git push -u origin feature/my-feature

# Force push (use with caution!)
git push --force-with-lease origin feature/my-feature
```

---

## Log & History

```bash
# Compact log overview
git log --oneline --graph --decorate --all

# Last 10 commits
git log -10

# Commits by an author
git log --author="Max"

# Commits affecting a file
git log -- src/main.go

# Diff between two branches
git diff main..feature/my-feature

# Which commit introduced line X?
git blame src/main.go
```

---

## Undo Changes

```bash
# Remove file from staging
git restore --staged src/main.go

# Discard local changes to a file
git restore src/main.go

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Reverse a commit with a new "revert commit" (safe for shared branches)
git revert <commit-sha>

# Discard all local changes
git checkout -- .
```

---

## Stash

```bash
# Save current changes temporarily
git stash

# Stash with description
git stash push -m "WIP: error handling"

# Show stash list
git stash list

# Apply last stash (keep it)
git stash apply

# Apply last stash and delete it
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Delete stash
git stash drop stash@{0}

# Delete all stashes
git stash clear
```

---

## Tags

```bash
# Show all tags
git tag

# Create lightweight tag
git tag v1.0.0

# Annotated tag (with message)
git tag -a v1.0.0 -m "Release v1.0.0"

# Push tag
git push origin v1.0.0

# Push all tags
git push origin --tags

# Delete tag (local + remote)
git tag -d v1.0.0
git push origin --delete v1.0.0
```

---

## .gitignore

```bash
# Remove file from tracking (without deleting)
git rm --cached .env

# Test .gitignore patterns
git check-ignore -v my-file.log

# Set global .gitignore
git config --global core.excludesfile ~/.gitignore_global
```

---

## Useful Shortcuts

```bash
# All branches that are merged (cleanup)
git branch --merged | grep -v "\*\|main\|master" | xargs git branch -d

# Reflog: every action from recent history
git reflog

# Get a file from another branch
git checkout other-branch -- path/to/file

# Initialize and update submodules
git submodule update --init --recursive
```

---

## Conventional Commits (Recommended)

```
feat:     new feature
fix:      bugfix
docs:     documentation
style:    formatting, no logic change
refactor: refactoring without feature/fix
test:     add/modify tests
chore:    build, dependencies, tooling
ci:       CI/CD configuration
perf:     performance improvement
```
