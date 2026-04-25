---
name: nix-template-deployment
description: "Guides deploying nix-template shell.nix and .envrc to directories for per-directory package availability via direnv. Auto-activates when troubleshooting 'command not found' for Nix packages, setting up dev environments in directories, or working with nix-template. Covers home.packages vs devShell distinction, template customization, direnv activation. Trigger keywords: command not found, shell.nix, .envrc, nix-template, direnv allow, home.packages, devShell, buildInputs, per-directory, package not available."
metadata:
  version: "1.0.2"
---

# Deploying Nix Shell Templates

## Decision Tree

| Scenario | Action |
|----------|--------|
| Package needed everywhere | Add to `home.packages` in flake.nix |
| Package needed in one project | Deploy `nix-template` to that directory |
| Package in devShell but "not found" | Deploy `.envrc` + `shell.nix` (or use `nix develop`) |

Key distinction: `home.packages` = always on PATH. `devShell` packages require `nix develop` or direnv.

## Diagnose "Command Not Found"

1. Check `home.packages` in flake.nix — is the package listed?
2. Check `devShells` `buildInputs` — package may exist but not be on PATH
3. Check target directory for `.envrc` + `shell.nix` — direnv may not be set up

## Deploy from Template

```bash
cp ~/src/dotfiles/nix-template/shell.nix /target/dir/shell.nix
cp ~/src/dotfiles/nix-template/.envrc /target/dir/.envrc
# Edit shell.nix buildInputs to add needed packages
cd /target/dir && direnv allow
```

Template only includes `curl` — always customize `buildInputs` for the project's actual needs.

## Forbidden Patterns

**Don't add project-specific packages to home.packages** — deploy `shell.nix` to the project directory instead.

```nix
# WRONG - Pollutes global PATH for one project
home.packages = with pkgs; [ nodejs_24 ];

# RIGHT - Deploy shell.nix to ~/src/myproject with nodejs_24 in buildInputs
```

**Don't fall back to Homebrew** — if a setup script uses `brew install`, the fix is making the Nix package available via `shell.nix`, not accepting the Homebrew install.

## Violation Detection

```bash
# Find directories with .envrc but no shell.nix or flake.nix (broken direnv)
find ~/ -maxdepth 3 -name ".envrc" -exec sh -c 'dir=$(dirname "$1"); [ ! -f "$dir/shell.nix" ] && [ ! -f "$dir/flake.nix" ] && echo "$dir"' _ {} \;
```
