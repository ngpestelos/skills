---
name: git-stash-pull-pop
description: Gracefully update a git repository from remote when you have unstaged local changes. Stashes changes, pulls, then restores them. Auto-activates when pull is blocked by uncommitted files. Trigger keywords: update repo with local changes, git pull blocked by unstaged files, sync with uncommitted work, pull with changes.
metadata:
  version: 1.1.0
---

# Git Stash-Pull-Pop Workflow

Update from remote when you have local uncommitted changes that you want to preserve and commit after pulling.

## Steps

### 1. Diagnose
```bash
git status && git pull --rebase
```

If pull fails with "cannot pull with rebase: You have unstaged changes", proceed.

### 2. Stash
```bash
git stash
```

### 3. Pull
```bash
git pull --rebase
```

### 4. Pop
```bash
git stash pop
```

### 5. Commit
```bash
git add <files>
git commit -m "<message>"
git push
```

## Handling Rebase with Committed Changes

When you've already committed but remote has diverged:

```bash
# Pull with rebase
git pull --rebase

# If merge conflicts occur, resolve them, then:
git add <conflicted-files>

# In automated/non-interactive contexts, bypass editor:
GIT_EDITOR=true git rebase --continue

# Push
git push
```

**Critical for automation**: The `GIT_EDITOR=true` pattern prevents the default editor (nano/vim) from opening during `rebase --continue`, which would otherwise hang or fail in cron/CI environments.

## Pitfalls

- **Do not use `git checkout -- .`** — discards your changes permanently
- **Do not commit before pulling** — creates unnecessary merge commits
- **Merge conflicts on pop** — resolve normally, then `git stash drop`
- **Stash is stack-based** — `pop` applies and removes; `apply` keeps it in stash
- **Rebase editor hang in automation** — Use `GIT_EDITOR=true git rebase --continue` to bypass interactive editor prompts

## Alternatives

| Situation | Approach |
|-----------|----------|
| Changes are throwaway | `git checkout -- . && git pull --rebase` |
| Changes ready to commit | Commit first, then pull |
| Long-lived work | Create a branch, commit there, rebase later |
| Multiple stashes | `git stash list` and `git stash apply stash@{N}` |
