---
name: nix-darwin-zsh-completion
description: "Fixes zsh compinit insecure directories warning in nix-darwin. Auto-activates when troubleshooting compinit warnings, zsh completion issues, or /etc/zshrc generation. Covers enableGlobalCompInit, completionInit differences between nix-darwin and home-manager, system vs user zsh init ordering. Trigger keywords: compinit, insecure directories, compaudit, enableGlobalCompInit, completionInit, /etc/zshrc, zsh completion, compinit -u."
metadata:
  version: "1.0.1"
---

# Fixing zsh compinit Insecure Directories Warning

## Core Principles

1. `/etc/zshrc` (nix-darwin) runs **before** `~/.zshrc` (home-manager) — system-level compinit triggers the warning before home-manager can fix it
2. nix-darwin and home-manager have **different** zsh option names — don't confuse them
3. Only one layer should call `compinit` — disable the system-level call and let home-manager handle it

### Forbidden Patterns

#### Using home-manager option names in nix-darwin

```nix
# WRONG — completionInit does NOT exist in nix-darwin's programs.zsh
programs.zsh = {
  enableCompletion = true;
  completionInit = "autoload -U compinit && compinit -u";  # home-manager only
};
```

Error: `The option 'programs.zsh.completionInit' does not exist`

### Required Patterns

#### Disable system-level compinit via nix-darwin

```nix
# In sharedSystemModule (system-level config):
programs.zsh.enableGlobalCompInit = false;
```

#### Keep home-manager compinit -u

```nix
# In mkUserConfig (home-manager config):
programs.zsh = {
  enable = true;
  completionInit = "autoload -U compinit && compinit -u";  # valid here
};
```

### Quick Decision Tree

| Option | Module | Effect |
|--------|--------|--------|
| `enableGlobalCompInit` | nix-darwin | Controls `compinit` in `/etc/zshrc` |
| `completionInit` | home-manager | Custom compinit command in `~/.zshrc` |
| `enableCompletion` | both (different behavior) | Enables completion system |

### Common Mistakes

- **Assuming nix-darwin and home-manager share the same zsh options** — They don't. Always check the module source.
- **Adding `compinit -u` to nix-darwin's `interactiveShellInit`** — This still runs the default `compinit` first via `enableGlobalCompInit`.
- **Ignoring init ordering** — `/etc/zshrc` always runs before `~/.zshrc`. Fixes in home-manager alone cannot prevent system-level warnings.

### Verification

```bash
# After darwin-rebuild switch:
grep compinit /etc/zshrc          # Should show NO compinit line
grep compinit ~/.zshrc            # Should show: compinit -u
compaudit                         # Lists dirs (ignored by -u flag)
```
