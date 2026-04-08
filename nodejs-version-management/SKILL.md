---
name: nodejs-version-management
description: "Guides Node.js and npm version management in Nix flakes. Auto-activates when working with nodejs versions, npm upgrades, or version notices. Covers system packages, activation scripts, devShells, version synchronization, pnpm global configuration. Trigger keywords: nodejs, npm, version, upgrade, nodejs_22, nodejs_23, nodejs_24, npm notice, node version, npm install -g, undefined variable, devShell, direnv, buildInputs, pnpm, corepack, nodePackages, EACCES, nix store immutable, pnpm setup, PNPM_HOME."
metadata:
  version: 1.0.0
---

# Managing Node.js Versions in Nix

## Core Principles

1. **npm is bundled with Node.js** -- never run `npm install -g npm@version`
2. **All Node.js references in flake.nix must use the same `nodejs_XX`** -- system packages, activation scripts, and devShell buildInputs
3. **Verify nixpkgs availability before upgrading** -- `nix-env -qaP 'nodejs.*' 2>/dev/null | grep -E "nodejs_[0-9]+"`
4. **Claude Code**: use the native installer, not npm

## Required: Version Synchronization

All three locations must reference the same `nodejs_XX`:

```nix
# 1. System packages
environment.systemPackages = with pkgs; [ nodejs_24 ];

# 2. Activation scripts
system.activationScripts.postActivation.text = ''
  ${pkgs.nodejs_24}/bin/npm config set prefix ...
  ${pkgs.nodejs_24}/bin/npm install -g ...
'';

# 3. DevShell buildInputs (loaded via direnv) -- always use versioned package
devShells.aarch64-darwin.home = mkShell {
  buildInputs = with pkgs; [ nodejs_24 ];  # NOT unversioned `nodejs`
};
```

## Forbidden Patterns

### Never upgrade npm or install Node tools imperatively

```bash
# WRONG - breaks Nix declarative model
npm install -g npm@11.6.3
npm install -g pnpm
corepack enable pnpm
```

```nix
# RIGHT - declare in flake.nix, then darwin-rebuild switch
home.packages = with pkgs; [ nodePackages.pnpm ];
```

### Never install Claude Code via npm

```nix
# WRONG
${pkgs.nodejs_24}/bin/npm install -g @anthropic-ai/claude-code@latest

# RIGHT - native installer in activation script
system.activationScripts.postActivation.text = ''
  export HOME="/Users/$USER"
  ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | bash || true
'';
environment.systemPath = [ "$HOME/.local/bin" ];
```

## PNPM Global Configuration

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

## Isolating Node Runtime for npm CLI Tools

When an npm CLI tool needs `node` at runtime but you want to avoid system-wide Node (version conflicts with project devShells):

```nix
# Wrapper injects Node only for this tool
(pkgs.writeShellScriptBin "gws" ''
  export PATH="${pkgs.nodejs}/bin:$PATH"
  exec "$HOME/.local/share/pnpm/gws" "$@"
'')
```

Auto-install on new machines via activation:

```nix
activation.installGlobalNpmPackages = lib.hm.dag.entryAfter ["setupPnpm"] ''
  export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"
  export PNPM_HOME="$HOME/.local/share/pnpm"
  if [ ! -f "$PNPM_HOME/gws" ]; then
    $DRY_RUN_CMD pnpm add -g @googleworkspace/cli
  fi
'';
```

**Discovery (Mar 2026)**: `@googleworkspace/cli` installed via pnpm failed with `exec: node: not found`. The wrapper pattern injects Node only for the specific tool without polluting devShells.

## Violation Detection

```bash
# All nodejs refs should show single version
grep -o "nodejs_[0-9]*" flake.nix | sort | uniq -c

# Check for deprecated npm-based Claude Code installation
grep -n "npm install.*claude-code" flake.nix
```
