---
name: git-stash-pull-pop
description: Gracefully update a git repository from remote when you have unstaged local changes. Stashes changes, pulls, then restores them. Auto-activates when pull is blocked by uncommitted files. Trigger keywords: update repo with local changes, git pull blocked by unstaged files, sync with uncommitted work, pull with changes.
metadata:
  version: 1.0.0
---

# Git Stash-Pull-Pop Workflow

Update from remote when you have local uncommitted changes that you want to preserve and commit after pulling.

## When to Use This

- You have unstaged/uncommitted changes in the working tree
- You need to pull from remote first (e.g., to get latest changes, avoid conflicts)
- You want to commit your changes after the pull (not before)

## Steps

### 1. Check status
```bash
git status
```

### 2. Attempt pull (expected to fail)
```bash
git pull --rebase
```

If it fails with "cannot pull with rebase: You have unstaged changes", proceed.

### 3. Inspect changes to understand scope
```bash
git diff <file>
```

### 4. Stash local changes
```bash
git stash
```

### 5. Pull from remote
```bash
git pull --rebase
```

### 6. Restore stashed changes
```bash
git stash pop
```

### 7. Now you can commit
```bash
git add <files>
git commit -m "<message>"
git push
```

## Pitfalls

- **Do not use `git checkout -- .`** — this discards your changes permanently
- **Do not commit before pulling** — creates unnecessary merge commits
- **Do not use `git add .` before stashing** — `stash` already handles this
- **Merge conflicts on pop** — rare, but resolve normally and run `git stash drop` after if needed
- **Stash is stack-based** — `pop` applies and removes; `apply` keeps it in stash

## Alternatives to Consider

| Situation | Approach |
|-----------|----------|
| Changes are throwaway | `git checkout -- . && git pull --rebase` |
| Changes ready to commit | Commit first, then pull |
| Long-lived work | Create a branch, commit there, rebase later |
| Multiple stashes | Use `git stash list` and `git stash apply stash@{N}` |
