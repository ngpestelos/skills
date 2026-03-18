---
name: nix-github-release-packaging
description: "Packages pre-built binaries from GitHub releases as Nix derivations for home-manager. Auto-activates when adding CLI tools from GitHub, creating Nix packages for Go/Rust binaries, or troubleshooting fetchurl hash mismatches. Covers stdenv.mkDerivation with fetchurl, SHA256 hash workflow, Homebrew cask naming collisions, darwin_arm64 targeting. Trigger keywords: GitHub release, pre-built binary, fetchurl, stdenv.mkDerivation, hash mismatch, nix-prefetch-url, homebrew cask, Go CLI, Rust CLI, home.packages."
metadata:
  version: 1.0.0
---

# Packaging GitHub Release Binaries for Nix

> **Purpose**: Install pre-built CLI tools from GitHub releases into home-manager via Nix derivations, avoiding Homebrew cask naming collisions and hash mismatches.

## Core Principles

1. **Nix derivations over Homebrew casks** — Homebrew cask names often collide (e.g., `basecamp` cask = desktop app, not CLI)
2. **Use the build error hash** — `nix-prefetch-url --unpack` often gives wrong hashes; use the hash from the first failed build
3. **Declare derivations near usage** — define in `flake.nix` `let` block, reference in `home.packages`

## Required Patterns

### Derivation Template (pre-built binary)

```nix
# In flake.nix let block:
tool-name = { pkgs }: pkgs.stdenv.mkDerivation rec {
  pname = "tool-name";
  version = "0.2.3";
  src = pkgs.fetchurl {
    url = "https://github.com/ORG/REPO/releases/download/v${version}/tool_${version}_darwin_arm64.tar.gz";
    sha256 = "sha256-ACTUAL_HASH_HERE=";
  };
  sourceRoot = ".";
  installPhase = ''
    mkdir -p $out/bin
    cp tool-name $out/bin/tool-name
    chmod +x $out/bin/tool-name
  '';
};

# In home.packages:
(tool-name { inherit pkgs; })
```

### SHA256 Hash Workflow

```bash
# Step 1: Use empty hash to trigger build error
sha256 = "";

# Step 2: Run darwin-rebuild, it will fail with:
#   specified: sha256-AAAA...
#   got:       sha256-BBBB...

# Step 3: Use the "got:" hash (NOT nix-prefetch-url output)
sha256 = "sha256-BBBB...=";
```

### Global Config for CLI Tools

```nix
# In home.file section (for tools needing config):
file.".config/tool-name/config.json" = {
  text = builtins.toJSON {
    account_id = "12345";
  };
  force = true;
};
```

## Forbidden Patterns

### Homebrew Cask Assumption

```nix
# WRONG: Homebrew cask names often map to desktop apps, not CLIs
casks = [ "basecamp" ];  # Installs Basecamp.app, NOT basecamp CLI

# RIGHT: Use Nix derivation from GitHub release
(basecamp-cli { inherit pkgs; })
```

### nix-prefetch-url Hash

```bash
# WRONG: This hash may differ from actual build hash
nix hash to-sri --type sha256 $(nix-prefetch-url --unpack URL)

# RIGHT: Use empty hash, let build fail, copy "got:" hash
sha256 = "";  # Then use the error output
```

## Quick Decision Tree

- **Tool in nixpkgs?** -> Use `pkgs.tool-name` directly
- **Tool has flake?** -> Add as flake input (like `qmd`)
- **Pre-built binary on GitHub?** -> Use this derivation pattern
- **Only in Homebrew?** -> Use `homebrew.brews` (last resort)

## Common Mistakes

1. **Trusting `nix-prefetch-url --unpack`** — hash often differs from actual build due to unpacking differences. Always use the error-reported hash.
2. **Assuming Homebrew tap = CLI** — many taps serve desktop apps via casks. Always verify with `brew info TAP/FORMULA` before adding.
3. **Forgetting `sourceRoot = "."`** — needed when tarball extracts files directly (no subdirectory).
4. **Missing `force = true`** on config files — home-manager won't overwrite existing files without it.

## Key Takeaway

Use empty SHA256 + build error hash, never trust `nix-prefetch-url`. Define derivations in the `let` block, add to `home.packages` via function call.
