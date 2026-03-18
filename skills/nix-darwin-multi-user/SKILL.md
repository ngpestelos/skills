---
name: nix-darwin-multi-user
description: "Guides multi-user nix-darwin configuration with home-manager. Auto-activates when adding users, configuring home-manager for multiple accounts, or troubleshooting per-user activation. Covers mkDarwinConfig, sharedSystemModule, activation scripts, home-manager file conflicts. Trigger keywords: multi-user, usernames, mkDarwinConfig, sharedSystemModule, home-manager activation, users.users, agent user, second user, per-user, activation script, .zshrc conflict, unmanaged file."
metadata:
  version: 1.0.0
---

# Configuring Multi-User nix-darwin Systems

## Instructions

### Core Principles

1. **One function, many users**: Extract user config into `mkUserConfig` — never duplicate config blocks per user
2. **Primary user for system services**: Redis, PostgreSQL, and launchd agents reference one user's home; additional users share system packages but not service data dirs
3. **Activation scripts must iterate**: Any per-user setup in `system.activationScripts` (e.g., Claude Code install) must loop over all `usernames`, not just the primary
4. **Home-manager won't clobber**: Existing unmanaged dotfiles block home-manager activation silently — users must remove them before rebuild

### Required Patterns

#### Reusable user config function

```nix
# Extract ALL home-manager config into a standalone function
mkUserConfig = username: { pkgs, lib, ... }: {
  home = {
    stateVersion = "20.09";
    homeDirectory = "/Users/${username}";
    packages = with pkgs; [ /* shared packages */ ];
  };
  programs.zsh = { /* shared zsh config */ };
  programs.neovim = { /* shared neovim config */ };
  programs.tmux = { /* shared tmux config */ };
};
```

#### Accept usernames list in mkDarwinConfig

```nix
mkDarwinConfig = { hostname, system, usernames }: let
  primaryUser = builtins.head usernames;
in nix-darwin.lib.darwinSystem {
  modules = [
    # Per-user home directories
    {
      users.users = builtins.listToAttrs (map (u: {
        name = u;
        value.home = "/Users/${u}";
      }) usernames);
    }
    # System module uses primaryUser for service data dirs
    (sharedSystemModule { username = primaryUser; inherit usernames; })
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      # All users get identical config
      home-manager.users = builtins.listToAttrs (map (u: {
        name = u;
        value = mkUserConfig u;
      }) usernames);
    }
  ];
};
```

#### Loop activation scripts over all users

```nix
# In sharedSystemModule, accept both username and usernames
sharedSystemModule = { username, usernames }: { pkgs, ... }: {
  system.activationScripts.postActivation.text = ''
    # Per-user installations must loop
    ${builtins.concatStringsSep "\n" (map (u: ''
    echo "Installing Claude Code for ${u}..."
    export HOME="/Users/${u}"
    ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | bash || true
    '') usernames)}
  '';
};
```

#### Host definitions with usernames list

```nix
my-host = mkDarwinConfig {
  hostname = "my-host";
  system = "aarch64-darwin";
  usernames = [ "primary-user" "secondary-user" ];
};
```

### Forbidden Patterns

#### Single username parameter

```nix
# BAD: Only configures one user
mkDarwinConfig = { hostname, system, username }: ...
  home-manager.users.${username} = { /* config */ };
```

#### Hardcoded HOME in activation scripts

```nix
# BAD: Only installs for one user
export HOME="/Users/${username}"
curl -fsSL https://claude.ai/install.sh | bash || true
```

#### Duplicating user config blocks

```nix
# BAD: Copy-paste config for each user
home-manager.users.alice = { /* 400 lines */ };
home-manager.users.bob = { /* same 400 lines */ };
```

### Quick Decision Tree

- **Adding a new user to an existing host** -> Add username to `usernames` list, rebuild
- **New host with single user** -> `usernames = [ "username" ];`
- **New host with multiple users** -> `usernames = [ "primary" "secondary" ];` (first = primary for services)
- **User reports "nothing configured" after rebuild** -> Check if unmanaged dotfiles blocked activation

### Common Mistakes

#### 1. Home-manager activation blocked by existing files

**Problem**: A user's `.zshrc` already exists as a regular file. Home-manager silently skips it — no symlink created, no config applied.

**Symptoms**: User has `.zshrc` but it's a plain file (not a nix store symlink). Shell aliases, PATH additions, direnv hook all missing.

**Fix**: Back up and remove the file, then rebuild:
```bash
mv ~/.zshrc ~/.zshrc.bak
sudo darwin-rebuild switch --flake ~/src/dotfiles#<hostname>
# Verify: ls -la ~/.zshrc should show -> /nix/store/...
```

#### 2. Activation script only targets primary user

**Problem**: `system.activationScripts` uses `${username}` (primary user) for per-user operations like installing CLI tools.

**Fix**: Pass `usernames` list to `sharedSystemModule` and loop with `builtins.concatStringsSep` + `map`.

#### 3. Forgetting to pull before rebuild on remote hosts

**Problem**: `--flake ~/src/dotfiles#hostname` reads from local checkout. If you push from one machine and rebuild on another, you must `git pull` first.

### Debugging

#### Inspect generated activation script

```bash
nix eval --raw '.#darwinConfigurations.<hostname>.config.system.activationScripts.postActivation.text'
```

#### Verify home-manager file is a symlink

```bash
ls -la /Users/<username>/.zshrc
# Should show: .zshrc -> /nix/store/...-home-manager-files/.zshrc
```

#### Check per-user nix profile exists

```bash
ls /etc/profiles/per-user/<username>/bin/
```

#### Validate flake structure

```bash
nix flake check
```
