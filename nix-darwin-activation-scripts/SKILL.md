---
name: nix-darwin-activation-scripts
description: "Reliable nix-darwin activation scripts. Auto-activates when editing postActivation blocks, adding installers to darwin-rebuild, or debugging silent activation failures. Covers ownership guards, user-scoped execution, error surfacing, temp file downloads, gated cleanup, and Nix escaping. Trigger keywords: postActivation, activation script, darwin-rebuild, silent failure, sudo -u, chown, stat, ARG_MAX."
allowed-tools: Read, Grep, Glob, Bash
---

# Reliable nix-darwin Activation Scripts

`system.activationScripts.postActivation` runs as root with no interactive terminal. Every operation must handle failure visibly, fix ownership, and run user-scoped work via `sudo -u`.

## REQUIRED Patterns

### Fix ownership before user operations

Prior runs leave root-owned artifacts. Fix **both** parent directory **and** target — users can't create symlinks inside root-owned directories.

```nix
mkdir -p "$BIN_DIR"
if [ "$(/usr/bin/stat -f '%%Su' "$BIN_DIR")" != "${u}" ]; then
  chown ${u}:staff "$BIN_DIR"
fi
if [ -L "$SYMLINK" ]; then
  OWNER=$(/usr/bin/stat -f '%%Su' "$SYMLINK" 2>/dev/null || echo "")
  if [ "$OWNER" != "${u}" ] && [ -n "$OWNER" ]; then
    chown -h ${u}:staff "$SYMLINK"
  fi
fi
```

### Download to temp files, run as user

`bash -c "$VAR"` hits ARG_MAX for large scripts. Use `/usr/bin/sudo` (not `pkgs.sudo` — Linux only). Always append `2>&1` so stderr reaches the terminal.

```nix
INSTALL_TMP=$(mktemp)
chmod 644 "$INSTALL_TMP"
if ! ${pkgs.curl}/bin/curl -fsSL https://example.com/install.sh -o "$INSTALL_TMP"; then
  echo "WARNING: download failed for ${u}"
elif ! /usr/bin/sudo -u ${u} HOME="/Users/${u}" ${pkgs.bash}/bin/bash "$INSTALL_TMP" 2>&1; then
  echo "WARNING: installer failed for ${u}"
fi
rm -f "$INSTALL_TMP"
```

### Gate cleanup on success

Only delete old versions inside the success branch.

```nix
NEW_VERSION=$("$SYMLINK" --version 2>/dev/null || echo "unknown")
for v in "$VERSIONS_DIR"/*; do
  if [ "$(basename "$v")" != "$CURRENT" ]; then rm -rf "$v"; fi
done
```

## FORBIDDEN Patterns

- **`curl ... | bash || true`** — swallows all errors silently
- **Running installers as root** — `export HOME="/Users/${u}"; bash install.sh` creates root-owned files in user HOME. Use `sudo -u`.
- **Bare `stat`** — Nix coreutils puts GNU stat in PATH. GNU `stat -f` means `--file-system`, not format string. Always use `/usr/bin/stat`.
- **`stat -f %Su`** — Nix consumes `%S`. Escape as `%%Su`.
- **`rm -f` on directories** — silently does nothing. Use `rm -rf`.
- **`${u}` in single-quoted `bash -c '...'`** — won't interpolate. Use Nix-level string building.
- **Missing `2>&1`** — stderr goes to activation log but not terminal output.
- **`git clone git@...` as root** — uses root's SSH keys. Run as target user via `sudo -u`.
