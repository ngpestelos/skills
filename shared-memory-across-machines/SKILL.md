---
name: shared-memory-across-machines
description: "Store Claude Code memory in project repos with symlinks for cross-machine sync. Auto-activates when setting up memory for new projects, migrating memory, or troubleshooting memory sync. Trigger keywords: shared memory, memory sync, cross-machine, memory symlink, portable memory."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Sharing Claude Code Memory Across Machines

Claude Code stores memory at `~/.claude/projects/<encoded-path>/memory/` — a machine-specific local path. This skill makes memory portable by storing it in the project repo and symlinking.

## Setup for a New Project

1. Create `.claude/memory/` in the project repo:
   ```bash
   mkdir -p <project-root>/.claude/memory
   ```

2. The `ensure-memory-symlink.sh` hook (UserPromptSubmit) auto-creates the symlink on next session start. No manual step needed.

3. Memory files are now git-tracked. They sync via normal `git push`/`git pull`.

## Migrating Existing Memory

If a project already has local memory files:

```bash
# Copy existing memory into the repo
cp ~/.claude/projects/<encoded-path>/memory/* <project-root>/.claude/memory/

# Replace local dir with symlink
rm -r ~/.claude/projects/<encoded-path>/memory
ln -s <project-root>/.claude/memory ~/.claude/projects/<encoded-path>/memory
```

The hook detects non-symlink directories and prints the migration command.

## Path Encoding Rule

Absolute project path with `/` replaced by `-`:

| Project Path | Encoded |
|---|---|
| `/Users/ngpestelos/src/PARA` | `-Users-ngpestelos-src-PARA` |
| `/home/nestor/src/PARA` | `-home-nestor-src-PARA` |

Full memory path: `~/.claude/projects/<encoded>/memory/`

## How It Works

- **Hook**: `~/.claude/hooks/ensure-memory-symlink.sh` runs on every UserPromptSubmit
- **Logic**: Checks if `$CWD/.claude/memory/` exists -> computes encoded path -> creates symlink if missing
- **Nix deployment**: Hook and settings.json are nix-managed via `dotfiles/config/claude/hooks/`
- **On new machines**: `git clone` the project + `darwin-rebuild switch` -> hook activates on first session

## Key Constraint

The encoded path differs per machine (based on absolute project path). The symlink must be created per-machine — the hook handles this automatically.
