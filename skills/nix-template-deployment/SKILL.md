---
name: nix-template-deployment
description: "Guides deploying nix-template shell.nix and .envrc to directories for per-directory package availability via direnv. Auto-activates when troubleshooting 'command not found' for Nix packages, setting up dev environments in directories, or working with nix-template. Covers home.packages vs devShell distinction, template customization, direnv activation. Trigger keywords: command not found, shell.nix, .envrc, nix-template, direnv allow, home.packages, devShell, buildInputs, per-directory, package not available."
metadata:
  version: 1.0.0
---

# Deploying Nix Shell Templates

## Core Principles

1. **home.packages vs devShell** — Packages in `home.packages` are always on PATH; packages in `devShells` are only available inside `nix develop` or via direnv
2. **Template-driven** — Use a `nix-template/shell.nix` + `.envrc` as the starting point for per-directory environments
3. **direnv activation** — `.envrc` with `use nix` auto-loads `shell.nix` when entering the directory (and subdirectories without their own `.envrc`)

## Required Patterns

### Diagnose before deploying

When a user reports "command not found" for a package:

1. Check if the package is in `home.packages` (globally available)
2. Check if the package is in a `devShell` (only available in `nix develop`)
3. Check if the target directory has `.envrc` + `shell.nix`

```bash
# Check home.packages in flake.nix
grep -A 50 "packages = with pkgs" flake.nix | head -60

# Check devShells
grep -A 10 "buildInputs" flake.nix

# Check target directory for direnv setup
ls -la /target/dir/.envrc /target/dir/shell.nix
```

### Deploy from template

```bash
# Copy template files
cp ~/src/dotfiles/nix-template/shell.nix /target/dir/shell.nix
cp ~/src/dotfiles/nix-template/.envrc /target/dir/.envrc

# Add needed packages to shell.nix buildInputs
# Then activate direnv
cd /target/dir && direnv allow
```

### Customize shell.nix for the directory's needs

```nix
# Add only the packages needed for that directory
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    curl
    nodejs_24    # Add packages as needed
  ];

  shellHook = ''
    export PATH="$HOME/.local/bin:$PATH"
  '';
}
```

## Forbidden Patterns

### Don't add packages to home.packages just for one project

```nix
# WRONG - Pollutes global PATH for a single project's need
home.packages = with pkgs; [
  nodejs_24   # Only needed in ~/src/myproject
];

# RIGHT - Deploy shell.nix to ~/src/myproject with nodejs_24
```

### Don't assume devShell packages are globally available

```nix
# WRONG assumption - This is ONLY available in `nix develop .#home`
devShells.aarch64-darwin.home = mkShell {
  buildInputs = [ nodejs_24 ];  # NOT on global PATH
};
```

### Don't install via Homebrew when Nix can provide it

```bash
# WRONG - Bypasses Nix, creates version drift
brew install node@22

# RIGHT - Add to shell.nix in the directory that needs it
```

## Quick Decision Tree

| Scenario | Action |
|----------|--------|
| Package needed everywhere | Add to `home.packages` in flake.nix |
| Package needed in one directory/project | Deploy `nix-template` to that directory |
| Package in devShell but not found | Either enter `nix develop` or deploy `.envrc` + `shell.nix` |
| "command not found" for Nix package | Check if it's in `home.packages` vs `devShell` |

## Common Mistakes

1. **Confusing devShell with home.packages** — devShell packages require `nix develop` or direnv to be on PATH
2. **Forgetting `direnv allow`** — After copying `.envrc`, must run `direnv allow` in the target directory
3. **Not customizing shell.nix** — Template only includes `curl`; add the packages you actually need
4. **Using Homebrew as fallback** — When a setup script falls back to Homebrew, the fix is usually making the Nix package available, not accepting the Homebrew install

## Violation Detection

```bash
# Find directories with .envrc but no shell.nix (broken direnv)
find ~/ -maxdepth 3 -name ".envrc" -exec sh -c 'dir=$(dirname "$1"); [ ! -f "$dir/shell.nix" ] && [ ! -f "$dir/flake.nix" ] && echo "$dir"' _ {} \;
```
