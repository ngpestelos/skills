---
name: nix-darwin-multi-user
<<<<<<< HEAD
description: "Guides multi-user nix-darwin configuration with home-manager. Auto-activates when adding users, configuring home-manager for multiple accounts, or troubleshooting per-user activation. Covers mkDarwinConfig, sharedSystemModule, activation scripts, home-manager file conflicts, dotted-username flake key escaping, portable rebuild helper, per-user package breakage. Trigger keywords: multi-user, usernames, mkDarwinConfig, sharedSystemModule, home-manager activation, users.users, agent user, second user, per-user, activation script, .zshrc conflict, unmanaged file, darwin-rebuild alias, rebuild script, flake attribute dots, dotted username, hostname-user output, per-user package disappears, direnv hook broken, fasd hook broken, shell init eval, environment.systemPackages, no such file or directory direnv."
metadata:
  version: "1.2.0"
=======
description: "Guides multi-user nix-darwin configuration with home-manager. Auto-activates when adding users, configuring home-manager for multiple accounts, or troubleshooting per-user activation. Covers mkDarwinConfig, sharedSystemModule, activation scripts, home-manager file conflicts, per-host-per-user launchd agents. Trigger keywords: multi-user, usernames, mkDarwinConfig, sharedSystemModule, home-manager activation, users.users, agent user, second user, per-user, activation script, .zshrc conflict, unmanaged file, launchd agent bootstrap failed, gui domain, error 125, per-host-per-user darwinConfigurations."
metadata:
  version: 1.1.0
>>>>>>> 8f18ca4 (chore: auto-sync)
---

# Configuring Multi-User nix-darwin Systems

## Core Principles

1. **One function, many users**: Extract user config into `mkUserConfig` — never duplicate config blocks per user
2. **Primary user for system services**: Redis, PostgreSQL, launchd agents reference one user's home; additional users share system packages but not service data dirs
3. **Activation scripts must iterate**: Per-user setup in `system.activationScripts` must loop over all `usernames`, not just the primary
4. **Home-manager won't clobber**: Existing unmanaged dotfiles block activation silently — remove them before rebuild
5. **One darwinConfiguration per (host, user)**: When any user has `launchd.agents`, split flake outputs into `host-user` entries. `users.users` still lists every account via `allUsers`; only the `activeUser` gets a `home-manager.users.<user>` entry. Each user rebuilds their own output so `launchctl asuser` never targets a non-console UID.
6. **Default ports on single-user hosts**: Derive service ports from `builtins.length allUsers`. Single-user hosts get defaults (redis 6379, postgres 5432); shift only the secondary user of multi-user hosts.

## Required Patterns

### mkDarwinConfig with activeUser + allUsers

```nix
mkUserConfig = { hostname, username, redisPort, postgresPort }: { pkgs, lib, ... }: {
  launchd.agents.redis.config.ProgramArguments = [
    "/bin/sh" "-c"
    "/bin/wait4path /nix/store && exec ${pkgs.redis}/bin/redis-server --port ${redisPort}"
  ];
  home = {
    stateVersion = "20.09";
    homeDirectory = "/Users/${username}";
    packages = with pkgs; [ /* shared packages */ ];
  };
  programs.zsh = { /* shared config */ };
};

mkDarwinConfig = { hostname, system, activeUser, allUsers }: let
  isMultiUser  = (builtins.length allUsers) > 1;
  redisPort    = if isMultiUser && activeUser != (builtins.head allUsers) then "6380" else "6379";
  postgresPort = if isMultiUser && activeUser != (builtins.head allUsers) then "5433" else "5432";
in nix-darwin.lib.darwinSystem {
  modules = [
    {
      # Keep ALL users known to the system, regardless of who's rebuilding.
      users.users = builtins.listToAttrs (map (u: {
        name = u;
        value.home = "/Users/${u}";
      }) allUsers);
    }
    (sharedSystemModule { username = activeUser; usernames = allUsers; })
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      # Only the active user gets home-manager (and launchd agents).
      home-manager.users.${activeUser} = mkUserConfig {
        inherit hostname;
        username = activeUser;
        inherit redisPort postgresPort;
      };
    }
  ];
};
```

### Per-host-per-user flake outputs

```nix
darwinConfigurations = let
  hostUsers = [ "ngpestelos" "agent.nestor.pestelos" ];
in {
  ascalon-ngpestelos              = mkDarwinConfig { hostname = "ascalon";  system = "aarch64-darwin"; activeUser = "ngpestelos";             allUsers = hostUsers; };
  "ascalon-agent.nestor.pestelos" = mkDarwinConfig { hostname = "ascalon";  system = "aarch64-darwin"; activeUser = "agent.nestor.pestelos"; allUsers = hostUsers; };
  durendal-ngpestelos             = mkDarwinConfig { hostname = "durendal"; system = "aarch64-darwin"; activeUser = "ngpestelos";             allUsers = [ "ngpestelos" ]; };
};
```

Rebuild alias:
```nix
rebuild = "sudo darwin-rebuild switch --flake ~/src/dotfiles#$(hostname -s)-$USER";
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

<<<<<<< HEAD
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

=======
>>>>>>> 8f18ca4 (chore: auto-sync)
## Decision Tree

- **Adding a user to existing host** -> Add to `allUsers` list and create a new `host-user` flake output for them; rebuild
- **User reports "nothing configured"** -> Check if unmanaged dotfiles blocked activation (see below)
- **`launchctl` error 125 on rebuild** -> Host is still using a single `usernames`-list output with home-manager for every user. Split into per-user flake outputs (see above)

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

<<<<<<< HEAD
### Flake output keys cannot contain dots

Nix CLI treats `.` as attribute path separator. An output keyed `"ascalon-agent.nestor.pestelos"` is unreachable on the command line — `--flake .#ascalon-agent.nestor.pestelos` is parsed as `darwinConfigurations.ascalon-agent.nestor.pestelos.system`, looking for nested attributes that don't exist.

**Fix**: Replace dots with underscores in the key only. Keep the real dotted username inside `activeUser` / `users.users`.

```nix
# Wrong — unreachable on CLI
"ascalon-agent.nestor.pestelos" = mkDarwinConfig { activeUser = "agent.nestor.pestelos"; ... };

# Right
ascalon-agent_nestor_pestelos = mkDarwinConfig { activeUser = "agent.nestor.pestelos"; ... };
```

Symptom error: `flake does not provide attribute 'darwinConfigurations.ascalon-agent.nestor.pestelos.system'`.

### Per-user package breakage when the other user rebuilds

**Symptom**: `_direnv_hook:2: no such file or directory: /etc/profiles/per-user/<user>/bin/direnv` (or same for `fasd`, `starship`, etc.) on every prompt after the other user ran `rebuild`.

**Root cause**: `home-manager.useUserPackages = true` stores each user's packages at `/etc/profiles/per-user/<user>/`. Each flake output only applies home-manager for one `activeUser`. When user B rebuilds, nix-darwin replaces `/etc/static` with a store path containing only user B's profile — removing user A's `/etc/profiles/per-user/<user>/` symlink entirely.

Secondary: tools like `direnv` and `fasd` embed their own absolute path when generating their shell hook (`direnv hook zsh` uses `os.Executable()`). After the profile disappears, the hardcoded path in `_direnv_hook` / `_fasd_hook` no longer exists.

**Fix**: Move shared shell-init binaries from `home.packages` to `environment.systemPackages` in `sharedSystemModule`. The system path `/run/current-system/sw/bin/<binary>` is always present after any rebuild since `sharedSystemModule` is included in every flake output.

```nix
# sharedSystemModule — add after environment.systemPath block
environment.systemPackages = with pkgs; [ direnv fasd ];
```

Remove the same binaries from `home.packages` in `mkUserConfig` to avoid redundancy.

Also guard any `eval` in `initContent` that embeds a path:

```nix
initContent = ''
  if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
  fi
  if command -v fasd >/dev/null 2>&1; then
    eval "$(fasd --init auto)"
  fi
'';
```

**Which binaries to move**: Any binary that (a) is in `home.packages`, (b) is unconditionally eval'd in `initContent`, and (c) both users need. Binaries with user-specific config or data dirs (redis, postgres, mlx-lm) stay per-user.

**After fix**: existing shells retain the broken hook in memory — close and reopen them. New shells will use `/run/current-system/sw/bin/<binary>` going forward.

### Rebuild alias/script bootstrap chicken-and-egg

When changing the `rebuild` wrapper inside `flake.nix`, the change only takes effect after a successful rebuild — but the old stale definition may be what's blocking that rebuild. In zsh, aliases also shadow commands on PATH, so installing a new script doesn't displace a cached alias in the current session.

**Bootstrap**:
1. Run the full command manually once to pick up the new wrapper: `sudo darwin-rebuild switch --flake ~/src/dotfiles#<host>-<user_sanitized>`
2. Then `unalias rebuild` in the current shell or open a new terminal
3. `rebuild` now resolves to the new script
=======
### `launchctl` bootstrap fails with error 125 on rebuild

Symptom during activation:
```
Failed to stop agent 'gui/501/org.nixos.redis': Boot-out failed: 125: Domain does not support specified action
Failed to start agent 'gui/501/org.nixos.redis' with error: Bootstrap failed: 125: Domain does not support specified action
```

**Cause**: `home-manager.darwinModules.home-manager` wires every user's `launchd.agents` into nix-darwin's `setupLaunchAgents`, which calls `launchctl asuser <uid> bootstrap gui/<uid>/...` for every user. That only succeeds when `<uid>` has an active GUI session. When the rebuilding user isn't UID 501, the primary user's agents fail to bootstrap. Plist files still land in `~/Library/LaunchAgents/` so agents auto-load next login, but the noise hides real activation errors.

**Fix**: Split flake outputs into per-user entries (see "Per-host-per-user flake outputs"). `users.users` still lists every account via `allUsers`; only the `activeUser` gets a `home-manager.users.<user>` entry. Each user rebuilds their own output.

Discovered 2026-04-20 debugging redis/postgres bootstrap failures on a forge rebuild run by `agent.nestor.pestelos` while `ngpestelos` (UID 501) was not the console user.
>>>>>>> 8f18ca4 (chore: auto-sync)

## Debugging

```bash
# Inspect generated activation script
nix eval --raw '.#darwinConfigurations.<hostname>.config.system.activationScripts.postActivation.text'

# Verify home-manager file is a symlink
ls -la /Users/<username>/.zshrc
# Should show: .zshrc -> /nix/store/...-home-manager-files/.zshrc

# Check per-user nix profile exists
ls /etc/profiles/per-user/<username>/bin/

# Confirm only the active user's home-manager is wired in for a per-user output
nix eval '.#darwinConfigurations."<host>-<user>".config.home-manager.users' --apply 'u: builtins.attrNames u'
# Should return a single-element list: [ "<activeUser>" ]

# Inspect a generated launchd plist port to verify the port policy
nix eval --raw '.#darwinConfigurations."<host>-<user>".config.home-manager.users."<user>".launchd.agents.redis.config.ProgramArguments' \
  --apply 'a: builtins.elemAt a 2'
```
