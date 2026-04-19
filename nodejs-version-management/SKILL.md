---
name: nodejs-version-management
description: "Guides Node.js and npm version management in Nix flakes. Auto-activates when working with nodejs versions, npm upgrades, or version notices. Covers system packages, activation scripts, devShells, version synchronization, pnpm global configuration, runtime resolution for pnpm-installed global scripts. Trigger keywords: nodejs, npm, version, upgrade, nodejs_22, nodejs_23, nodejs_24, npm notice, node version, npm install -g, undefined variable, devShell, direnv, buildInputs, pnpm, corepack, nodePackages, EACCES, nix store immutable, pnpm setup, PNPM_HOME, exec: node: not found, .local/share/pnpm, PATH shadowing, /etc/profiles/per-user, non-interactive shell, gws, firecrawl."
metadata:
  version: 1.1.0
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

## Making `node` Available to pnpm-Installed Global Scripts

`nodePackages.pnpm` exposes `pnpm` in the nix profile but **not** `node` — node is only a transitive runtime dep, not a top-level symlink at `/etc/profiles/per-user/$USER/bin/node`. pnpm-installed global scripts (`~/.local/share/pnpm/<tool>`) use a shebang that looks for `node` on PATH, so without `node` exposed somewhere, they fail with `exec: node: not found` in fresh non-interactive shells.

### Preferred fix: add `nodejs` to `home.packages`

```nix
home.packages = with pkgs; [
  nodePackages.pnpm
  nodejs          # exposes `node` in the nix profile; raw pnpm scripts resolve it
];
```

One line, fixes every pnpm-global tool at once, no per-tool wrappers. `pkgs.nodejs` resolves to the same store derivation that `nodePackages.pnpm` references transitively — no version skew.

### Fallback: per-tool wrapper

Use only when you specifically need a different node version for one tool than what's globally available:

```nix
(pkgs.writeShellScriptBin "gws" ''
  export PATH="${pkgs.nodejs}/bin:$PATH"
  exec "$HOME/.local/share/pnpm/gws" "$@"
'')
```

**Wrapper shadowing gotcha (Apr 2026)**: Wrappers live at `/etc/profiles/per-user/$USER/bin/<tool>`. If `~/.local/share/pnpm` comes **earlier** in PATH (typical, because `.zshrc` does `export PATH="$PNPM_HOME:$PATH"`), the raw pnpm script wins and the wrapper never runs. Diagnose with:

```bash
echo $PATH | tr ':' '\n' | nl | grep -E "(pnpm|profiles/per-user)"
# If pnpm appears BEFORE profiles/per-user, wrappers are shadowed.
```

Fixes: (a) add `nodejs` to `home.packages` (preferred — makes wrapper unnecessary), or (b) reorder PATH so `/etc/profiles/per-user/$USER/bin` comes first.

### Auto-install global packages

```nix
activation.installGlobalNpmPackages = lib.hm.dag.entryAfter ["setupPnpm"] ''
  export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"
  export PNPM_HOME="$HOME/.local/share/pnpm"
  if [ ! -f "$PNPM_HOME/gws" ]; then
    $DRY_RUN_CMD pnpm add -g @googleworkspace/cli
  fi
'';
```

### Discoveries

- **Mar 2026**: `@googleworkspace/cli` installed via pnpm failed with `exec: node: not found`. First fix was the wrapper pattern.
- **Apr 2026**: Wrapper pattern was shadowed by PATH ordering; never ran. Root-cause fix is adding `nodejs` to `home.packages`. Commit: `dotfiles/31fb91a`.

## Violation Detection

```bash
# All nodejs refs should show single version
grep -o "nodejs_[0-9]*" flake.nix | sort | uniq -c

# Check for deprecated npm-based Claude Code installation
grep -n "npm install.*claude-code" flake.nix
```
