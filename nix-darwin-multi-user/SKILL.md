---
name: nix-darwin-multi-user
description: "Guides multi-user nix-darwin configuration with home-manager. Auto-activates when adding users, configuring home-manager for multiple accounts, or troubleshooting per-user activation. Covers mkDarwinConfig, sharedSystemModule, activation scripts, home-manager file conflicts, dotted-username flake key escaping, portable rebuild helper. Trigger keywords: multi-user, usernames, mkDarwinConfig, sharedSystemModule, home-manager activation, users.users, agent user, second user, per-user, activation script, .zshrc conflict, unmanaged file, darwin-rebuild alias, rebuild script, flake attribute dots, dotted username, hostname-user output."
metadata:
  version: 1.1.0
---

# Configuring Multi-User nix-darwin Systems

## Core Principles

1. **One function, many users**: Extract user config into `mkUserConfig` — never duplicate config blocks per user
2. **Primary user for system services**: Redis, PostgreSQL, launchd agents reference one user's home; additional users share system packages but not service data dirs
3. **Activation scripts must iterate**: Per-user setup in `system.activationScripts` must loop over all `usernames`, not just the primary
4. **Home-manager won't clobber**: Existing unmanaged dotfiles block activation silently — remove them before rebuild

## Required Patterns

### mkDarwinConfig with usernames list

```nix
mkUserConfig = username: { pkgs, lib, ... }: {
  home = {
    stateVersion = "20.09";
    homeDirectory = "/Users/${username}";
    packages = with pkgs; [ /* shared packages */ ];
  };
  programs.zsh = { /* shared config */ };
};

mkDarwinConfig = { hostname, system, usernames }: let
  primaryUser = builtins.head usernames;
in nix-darwin.lib.darwinSystem {
  modules = [
    {
      users.users = builtins.listToAttrs (map (u: {
        name = u;
        value.home = "/Users/${u}";
      }) usernames);
    }
    (sharedSystemModule { username = primaryUser; inherit usernames; })
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users = builtins.listToAttrs (map (u: {
        name = u;
        value = mkUserConfig u;
      }) usernames);
    }
  ];
};
```

### Activation scripts looping over all users

```nix
sharedSystemModule = { username, usernames }: { pkgs, ... }: {
  system.activationScripts.postActivation.text = ''
    ${builtins.concatStringsSep "\n" (map (u: ''
    echo "Installing Claude Code for ${u}..."
    export HOME="/Users/${u}"
    ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | bash || true
    '') usernames)}
  '';
};
```

### Host definition

```nix
my-host = mkDarwinConfig {
  hostname = "my-host";
  system = "aarch64-darwin";
  usernames = [ "primary-user" "secondary-user" ];
};
```

### Per-user flake outputs with dot-safe keys

When each user rebuilds their own output (so activation scripts run in the correct `gui/<uid>/` domain), name outputs `host-user`. **Dots in usernames must be replaced with underscores in the key only** — see "Flake output keys cannot contain dots" below.

```nix
darwinConfigurations = {
  ascalon-ngpestelos            = mkDarwinConfig { hostname = "ascalon"; activeUser = "ngpestelos";             ... };
  ascalon-agent_nestor_pestelos = mkDarwinConfig { hostname = "ascalon"; activeUser = "agent.nestor.pestelos"; ... };  # dots → _ in key
};
```

### Portable `rebuild` helper

Never use a shell alias — aliases don't survive `sudo`, get shadowed by stale cached versions, and can't handle the dot-to-underscore mapping cleanly. Use a `writeShellScriptBin` in `home.packages`:

```nix
(pkgs.writeShellScriptBin "rebuild" ''
  set -euo pipefail
  HOST="$(hostname -s)"
  REAL_USER="''${SUDO_USER:-''${USER:-$(whoami)}}"
  USER_KEY="$(echo "$REAL_USER" | tr '.' '_')"
  TARGET="''${HOST}-''${USER_KEY}"
  REAL_HOME="$(dscl . -read "/Users/$REAL_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  FLAKE="''${REAL_HOME:-$HOME}/src/dotfiles"
  echo "rebuild: $FLAKE#$TARGET"
  if [ "$(id -u)" -eq 0 ]; then
    exec darwin-rebuild switch --flake "$FLAKE#$TARGET" "$@"
  else
    exec sudo darwin-rebuild switch --flake "$FLAKE#$TARGET" "$@"
  fi
'')
```

Key properties:
- `SUDO_USER` ahead of `USER` so `sudo rebuild` resolves the original caller, not root
- `dscl` looks up the real home directory; `$HOME` alone becomes `/var/root` under sudo
- `id -u` check so both `rebuild` and `sudo rebuild` work without double-sudo
- Prints `rebuild: <flake>#<target>` first — telltale that the new script is running (stale alias produces no such line)

## Decision Tree

- **Adding a user to existing host** -> Add to `usernames` list, rebuild
- **User reports "nothing configured"** -> Check if unmanaged dotfiles blocked activation (see below)

## Common Mistakes

### Home-manager activation blocked by existing files

Existing `.zshrc` as a regular file causes home-manager to silently skip it — no symlink, no config applied.

**Fix**: Back up and remove, then rebuild:
```bash
mv ~/.zshrc ~/.zshrc.bak
sudo darwin-rebuild switch --flake ~/src/dotfiles#<hostname>
# Verify: ls -la ~/.zshrc should show -> /nix/store/...
```

### Activation script only targets primary user

`system.activationScripts` uses `${username}` (primary) for per-user operations. **Fix**: Pass `usernames` list to `sharedSystemModule` and loop with `builtins.concatStringsSep` + `map`.

### Flake output keys cannot contain dots

Nix CLI treats `.` as attribute path separator. An output keyed `"ascalon-agent.nestor.pestelos"` is unreachable on the command line — `--flake .#ascalon-agent.nestor.pestelos` is parsed as `darwinConfigurations.ascalon-agent.nestor.pestelos.system`, looking for nested attributes that don't exist.

**Fix**: Replace dots with underscores in the key only. Keep the real dotted username inside `activeUser` / `users.users`.

```nix
# Wrong — unreachable on CLI
"ascalon-agent.nestor.pestelos" = mkDarwinConfig { activeUser = "agent.nestor.pestelos"; ... };

# Right
ascalon-agent_nestor_pestelos = mkDarwinConfig { activeUser = "agent.nestor.pestelos"; ... };
```

Discovered 2026-04-21 after splitting `darwinConfigurations` into per-user outputs (commit 577b5e2). Error: `flake does not provide attribute 'darwinConfigurations.ascalon-agent.nestor.pestelos.system'`.

### Rebuild alias/script bootstrap chicken-and-egg

When changing the `rebuild` wrapper inside `flake.nix`, the change only takes effect after a successful rebuild — but the old stale definition may be what's blocking that rebuild. In zsh, aliases also shadow commands on PATH, so installing a new script doesn't displace a cached alias in the current session.

**Bootstrap**:
1. Run the full command manually once to pick up the new wrapper: `sudo darwin-rebuild switch --flake ~/src/dotfiles#<host>-<user_sanitized>`
2. Then `unalias rebuild` in the current shell or open a new terminal
3. `rebuild` now resolves to the new script

## Debugging

```bash
# Inspect generated activation script
nix eval --raw '.#darwinConfigurations.<hostname>.config.system.activationScripts.postActivation.text'

# Verify home-manager file is a symlink
ls -la /Users/<username>/.zshrc
# Should show: .zshrc -> /nix/store/...-home-manager-files/.zshrc

# Check per-user nix profile exists
ls /etc/profiles/per-user/<username>/bin/
```
