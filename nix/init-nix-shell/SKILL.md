---
name: init-nix-shell
version: 1.0
description: "Initialize a nix shell environment with Claude Code in a target project directory. Auto-activates when setting up nix-shell for a project, deploying shell.nix templates, or configuring direnv for Nix. Trigger keywords: init nix shell, nix-shell setup, shell.nix template, direnv nix, nix environment."
allowed-tools: Read, Grep, Glob, Bash
---

# Init Nix Shell

> **Purpose**: Deploy a shell.nix + .envrc template to a target directory for per-project nix shell with Claude Code.

## Steps

1. Get the absolute path to the destination directory. Resolve relative paths.
2. Validate the destination exists (offer to `mkdir -p` if not).
3. If `shell.nix` or `.envrc` already exist, warn and confirm before overwriting.
4. Copy both files from `~/src/dotfiles/nix-template/` to the destination.
5. Print next steps:
   ```
   1. cd <destination>
   2. direnv allow
   3. nix-shell (Claude Code installs on first activation)
   4. Run 'claude'
   ```
