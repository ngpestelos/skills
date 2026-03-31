---
name: nix-darwin-activation-scripts
description: "Reliable nix-darwin activation scripts. Auto-activates when editing postActivation blocks, adding installers to darwin-rebuild, or debugging silent activation failures. Covers ownership guards, user-scoped execution, error surfacing, temp file downloads, gated cleanup, and Nix escaping. Trigger keywords: postActivation, activation script, darwin-rebuild, silent failure, sudo -u, chown, stat, ARG_MAX."
allowed-tools: Read, Grep, Glob, Bash
---

# Writing Reliable nix-darwin Activation Scripts

Prevent silent failures and permission bugs in `system.activationScripts.postActivation` blocks. Activation scripts run as root with no interactive terminal — every operation must explicitly handle failure, fix ownership, and report its outcome.

## Core Principles

1. Every failure must produce visible output — never swallow errors
2. User-scoped operations must run as the target user, not root
3. Fix root-owned artifacts before running user-scoped operations
4. Gate destructive cleanup on successful preceding operations

## REQUIRED Patterns

### Fix ownership before user operations

Activation runs as root, so prior runs leave root-owned files and directories. Fix **both** the parent directory **and** the target — a user can't create a symlink inside a root-owned directory.

```nix
# Fix parent directory ownership first
mkdir -p "$BIN_DIR"
if [ "$(/usr/bin/stat -f '%%Su' "$BIN_DIR")" != "${u}" ]; then
  chown ${u}:staff "$BIN_DIR"
fi
# Then fix symlink/file ownership
if [ -L "$SYMLINK" ]; then
  OWNER=$(/usr/bin/stat -f '%%Su' "$SYMLINK" 2>/dev/null || echo "")
  if [ "$OWNER" != "${u}" ] && [ -n "$OWNER" ]; then
    chown -h ${u}:staff "$SYMLINK"
  fi
fi
```

### Download large scripts to temp files

`bash -c "$VAR"` hits ARG_MAX for large scripts. Download to a temp file instead.

```nix
INSTALL_TMP=$(mktemp)
chmod 644 "$INSTALL_TMP"
if ! ${pkgs.curl}/bin/curl -fsSL https://example.com/install.sh -o "$INSTALL_TMP"; then
  echo "WARNING: download failed for ${u}"
  rm -f "$INSTALL_TMP"
elif ! /usr/bin/sudo -u ${u} HOME="/Users/${u}" ${pkgs.bash}/bin/bash "$INSTALL_TMP" 2>&1; then
  echo "WARNING: installer failed for ${u}"
  rm -f "$INSTALL_TMP"
else
  rm -f "$INSTALL_TMP"
fi
```

### Use system sudo, not pkgs.sudo

`pkgs.sudo` only supports Linux. On macOS, use `/usr/bin/sudo`.

```nix
/usr/bin/sudo -u ${u} HOME="/Users/${u}" ${pkgs.bash}/bin/bash "$SCRIPT"
```

### Gate cleanup on success

Destructive operations must only run after a successful update.

```nix
# Inside success branch only
NEW_VERSION=$("$SYMLINK" --version 2>/dev/null || echo "unknown")
for v in "$VERSIONS_DIR"/*; do
  if [ "$(basename "$v")" != "$CURRENT" ]; then rm -rf "$v"; fi
done
```

## FORBIDDEN Patterns

### Silent error swallowing

```nix
# BAD — hides network failures, permission errors, everything
curl -fsSL https://example.com/install.sh | bash || true
```

### Running user installers as root

```nix
# BAD — creates files owned by root in user's HOME
export HOME="/Users/${u}"
curl -fsSL https://example.com/install.sh | bash
```

### Bare `stat` instead of `/usr/bin/stat`

Nix coreutils puts GNU `stat` in PATH. GNU `stat -f` means `--file-system` (treats next arg as a file path), not format string. Always use `/usr/bin/stat` for BSD stat on macOS. (Discovered 2026-03-30)

### Unescaped % in stat format strings

`stat -f %Su` breaks because Nix consumes `%S`. Use `%%Su`.

### Using rm -f on directories

`rm -f` silently does nothing on directories. Use `rm -rf`.

### Nix string interpolation in subshells

`${u}` inside single-quoted `bash -c '...'` won't interpolate. Use Nix-level string building or pass via variable.

### Forgetting 2>&1

Without `2>&1`, stderr goes to the activation log but not the terminal output the user sees.

### SSH as root

`git clone git@github.com:...` as root uses root's SSH keys. Run as target user via `sudo -u`. (Discovered 2026-03-30)
