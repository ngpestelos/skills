---
name: nix-darwin-multi-user
description: "Guides multi-user nix-darwin configuration with home-manager. Auto-activates when adding users, configuring home-manager for multiple accounts, or troubleshooting per-user activation. Covers mkDarwinConfig, sharedSystemModule, activation scripts, home-manager file conflicts. Trigger keywords: multi-user, usernames, mkDarwinConfig, sharedSystemModule, home-manager activation, users.users, agent user, second user, per-user, activation script, .zshrc conflict, unmanaged file."
metadata:
  version: 1.0.0
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
