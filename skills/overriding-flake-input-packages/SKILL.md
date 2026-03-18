---
name: overriding-flake-input-packages
description: "Guides fixing build failures in external flake inputs by overriding their derivations. Auto-activates when an external package fails to build due to missing dependencies, native compilation errors, or node-gyp failures. Covers overrideAttrs, nativeBuildInputs, buildInputs, node-gyp/Python requirements. Trigger keywords: overrideAttrs, flake input, build failure, node-gyp, python, nativeBuildInputs, better-sqlite3, native addon, install script exited, gyp ERR."
metadata:
  version: 1.0.0
---

# Overriding External Flake Input Packages

## Core Principles

1. **Override locally, report upstream** — fix the build in your flake with `overrideAttrs`, then report the missing dependency upstream
2. **Preserve existing attributes** — always use `(old.attr or []) ++ [...]` to avoid clobbering upstream's build inputs
3. **Diagnose before fixing** — read the full build log (`nix log <drv>`) to identify the actual missing dependency

## Required Patterns

### Override external package in home.packages

When an external flake input package fails to build, wrap it with `overrideAttrs`:

```nix
# In home.packages:
(externalInput.packages.aarch64-darwin.pkg.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.python3 ];
}))
```

### Read the build log first

```bash
nix log /nix/store/<hash>-<name>.drv
```

Look for the actual error — common patterns:
- `gyp ERR! find Python` -> add `pkgs.python3`
- `cc: command not found` -> add `pkgs.gcc` or check `stdenv`
- `pkg-config: command not found` -> add `pkgs.pkg-config`
- `cmake: command not found` -> add `pkgs.cmake`

## Forbidden Patterns

### Don't fork the upstream flake

```nix
# WRONG — unnecessary maintenance burden
inputs.qmd.url = "github:my-fork/qmd";
```

### Don't replace nativeBuildInputs entirely

```nix
# WRONG — clobbers upstream's build dependencies
(pkg.overrideAttrs (old: {
  nativeBuildInputs = [ pkgs.python3 ];  # Lost bun, makeWrapper, etc.
}))
```

## Quick Decision Tree

- **Build fails with missing tool** -> `overrideAttrs` to add to `nativeBuildInputs`
- **Build fails with missing library** -> `overrideAttrs` to add to `buildInputs`
- **Build fails with wrong version** -> Check if `inputs.<pkg>.inputs.nixpkgs.follows` helps
- **Build fails fundamentally** -> Consider packaging locally or opening upstream issue

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Using `buildInputs` for build tools | Build tools need `nativeBuildInputs` for cross-compilation | Use `nativeBuildInputs` for compilers, Python, pkg-config |
| Forgetting `(old.attr or [])` | Crashes if upstream doesn't define the attribute | Always use fallback `or []` |
| Not checking the full log | Surface error may hide the real cause | Run `nix log <drv>` for complete output |

## Violation Detection

```bash
# Find external flake inputs used directly (potential override candidates)
grep -n 'packages\.\(aarch64\|x86_64\)' flake.nix

# Check for overrides missing the fallback pattern
grep -n 'overrideAttrs' flake.nix | grep -v 'or \[\]'
```
