---
name: nodejs-version-management
description: "Guides Node.js and npm version management in Nix flakes. Auto-activates when working with nodejs versions, npm upgrades, or version notices. Covers system packages, activation scripts, devShells, version synchronization, pnpm global configuration. Trigger keywords: nodejs, npm, version, upgrade, nodejs_22, nodejs_23, nodejs_24, npm notice, node version, npm install -g, undefined variable, devShell, direnv, buildInputs, pnpm, corepack, nodePackages, EACCES, nix store immutable, pnpm setup, PNPM_HOME."
metadata:
  version: 1.0.0
---

# Managing Node.js Versions in Nix

## Core Principles

1. **npm is bundled with Node.js** - Never run `npm install -g npm@version` in Nix environments
2. **Version synchronization** - All Node.js references in flake.nix must use the same version
3. **LTS awareness** - Even-numbered versions (20, 22, 24) are LTS; odd (21, 23) are "Current"
4. **nixpkgs availability** - New Node.js versions may not be packaged yet; verify before upgrading
5. **Native installer preferred** - Claude Code should use the native installer, not npm

## Required Patterns

### All Node.js references must match

When changing Node.js version, update ALL occurrences:

```nix
# 1. System packages
environment.systemPackages = with pkgs; [ nodejs_24 ];

# 2. Activation scripts
system.activationScripts.postActivation.text = ''
  ${pkgs.nodejs_24}/bin/npm config set prefix ...
  ${pkgs.nodejs_24}/bin/npm install -g ...
'';

# 3. DevShell buildInputs (loaded via direnv)
devShells.aarch64-darwin.home = mkShell {
  buildInputs = with pkgs; [ nodejs_24 ];
};
```

All three locations must reference the same `nodejs_XX` version.

## Forbidden Patterns

### Never upgrade npm separately

```bash
# WRONG - Breaks Nix declarative model
npm install -g npm@11.6.3

# RIGHT - Upgrade Node.js version in flake.nix (npm 11.x bundled with nodejs_24)
```

### Never use `npm install -g` or `corepack enable` for Node ecosystem tools

```bash
# WRONG - Nix store is immutable, EACCES on /nix/store/...
npm install -g pnpm
corepack enable pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -  # Fails on Nix-managed .zshrc
```

```nix
# RIGHT - Add to home.packages in flake.nix
home.packages = with pkgs; [ nodePackages.pnpm ];
# Then: darwin-rebuild switch
```

### Configure PNPM_HOME for global commands

After adding `nodePackages.pnpm` to `home.packages`:

```nix
# Create pnpm global directory via activation
home.activation.setupPnpm = lib.hm.dag.entryAfter ["writeBoundary"] ''
  $DRY_RUN_CMD mkdir -p "$HOME/.local/share/pnpm"
'';

# Export PNPM_HOME before PATH in programs.zsh.initExtra
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.local/bin:$PNPM_HOME:$PATH:/opt/homebrew/bin"
```

### Isolate Node runtime for npm-based CLI tools

When an npm CLI tool (e.g., `@googleworkspace/cli`) needs `node` at runtime but you don't want Node system-wide (to avoid version conflicts with project devShells):

```nix
# Wrapper injects Node only for this tool — no system-wide Node pollution
(pkgs.writeShellScriptBin "gws" ''
  export PATH="${pkgs.nodejs}/bin:$PATH"
  exec "$HOME/.local/share/pnpm/gws" "$@"
'')
```

Auto-install the package on new machines via activation:

```nix
activation.installGlobalNpmPackages = lib.hm.dag.entryAfter ["setupPnpm"] ''
  export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"
  export PNPM_HOME="$HOME/.local/share/pnpm"
  if [ ! -f "$PNPM_HOME/gws" ]; then
    $DRY_RUN_CMD pnpm add -g @googleworkspace/cli
  fi
'';
```

**Discovery (Mar 2026)**: `@googleworkspace/cli` installed via pnpm but failed with `exec: node: not found`. Adding Node system-wide would conflict with project devShells. The wrapper pattern injects Node only for the specific tool.

### Never leave version references out of sync

```nix
# WRONG - Mixed versions
environment.systemPackages = [ pkgs.nodejs_24 ];
${pkgs.nodejs_22}/bin/npm install -g ...  # Out of sync!
```

### Never use unversioned nodejs in devShells

```nix
# WRONG - Unversioned nodejs defaults to different version than system
buildInputs = with pkgs; [ nodejs ];

# RIGHT - Explicit version matching system packages
buildInputs = with pkgs; [ nodejs_24 ];
```

### Never assume new Node.js versions are available

```nix
# WRONG - nodejs_23 doesn't exist in nixpkgs-unstable
environment.systemPackages = [ pkgs.nodejs_23 ];
# Error: undefined variable 'nodejs_23'
```

**Before upgrading**, verify: `nix-env -qaP 'nodejs.*' 2>/dev/null | grep -E "nodejs_[0-9]+"`

## Quick Decision Tree

| npm notice says... | Action |
|-------------------|--------|
| "New major version available" | Consider upgrading Node.js in flake.nix |
| Minor/patch version | Usually ignore - comes with next Node.js update |

| Package | Availability | npm version |
|---------|--------------|-------------|
| nodejs_20 (LTS) | Available | npm 10.x |
| nodejs_22 (LTS) | Available | npm 10.x |
| nodejs_24 (LTS) | Available | npm 11.x |

## Claude Code Installation

> The native installer is the recommended method. This removes the Node.js/npm dependency for Claude Code.

### Required - Native Installation

```nix
system.activationScripts.postActivation.text = ''
  export HOME="/Users/$USER"
  ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | bash || true
'';

environment.systemPath = [ "$HOME/.local/bin" ];
```

### Forbidden - npm Installation (Deprecated)

```nix
# WRONG - Old npm-based approach
${pkgs.nodejs_24}/bin/npm install -g @anthropic-ai/claude-code@latest
```

## Violation Detection

```bash
# Find all nodejs version references
grep -n "nodejs_" flake.nix

# Check for mixed versions (should show single version)
grep -o "nodejs_[0-9]*" flake.nix | sort | uniq -c

# Check for unversioned nodejs in devShells
grep -B 5 "buildInputs" flake.nix | grep "^\s*nodejs$"

# Check for deprecated npm-based Claude Code installation
grep -n "npm install.*claude-code\|npm-global" flake.nix

# Verify native installer is configured
grep -n "install.sh\|\.local/bin" flake.nix

# Check for PNPM_HOME configuration
grep -n "PNPM_HOME\|setupPnpm\|\.local/share/pnpm" flake.nix
```
