---
name: nix-github-release-packaging
description: "Packages pre-built binaries from GitHub releases as Nix derivations for home-manager. Auto-activates when adding CLI tools from GitHub, creating Nix packages for Go/Rust binaries, or troubleshooting fetchurl hash mismatches. Covers stdenv.mkDerivation with fetchurl, SHA256 hash workflow, Homebrew cask naming collisions, darwin_arm64 targeting. Trigger keywords: GitHub release, pre-built binary, fetchurl, stdenv.mkDerivation, hash mismatch, nix-prefetch-url, homebrew cask, Go CLI, Rust CLI, home.packages."
metadata:
  version: 1.0.0
---

# Packaging GitHub Release Binaries for Nix

Package pre-built CLI tools from GitHub releases into home-manager via Nix derivations.

## Decision Tree

- **Tool in nixpkgs?** -> `pkgs.tool-name` directly
- **Tool has flake?** -> Add as flake input
- **Pre-built binary on GitHub?** -> Use derivation pattern below
- **Only in Homebrew?** -> `homebrew.brews` (last resort; cask names often collide with desktop apps)

## Derivation Template

```nix
# In flake.nix let block:
tool-name = { pkgs }: pkgs.stdenv.mkDerivation rec {
  pname = "tool-name";
  version = "0.2.3";
  src = pkgs.fetchurl {
    url = "https://github.com/ORG/REPO/releases/download/v${version}/tool_${version}_darwin_arm64.tar.gz";
    sha256 = "sha256-ACTUAL_HASH_HERE=";  # See hash workflow below
  };
  sourceRoot = ".";  # Required when tarball extracts files directly (no subdirectory)
  installPhase = ''
    mkdir -p $out/bin
    cp tool-name $out/bin/tool-name
    chmod +x $out/bin/tool-name
  '';
};

# In home.packages:
(tool-name { inherit pkgs; })
```

## SHA256 Hash Workflow

Never use `nix-prefetch-url --unpack` — its hash often differs from the actual build hash due to unpacking differences.

```bash
# Step 1: Set empty hash
sha256 = "";

# Step 2: Run darwin-rebuild — fails with:
#   specified: sha256-AAAA...
#   got:       sha256-BBBB...

# Step 3: Copy the "got:" hash into sha256
sha256 = "sha256-BBBB...=";
```
