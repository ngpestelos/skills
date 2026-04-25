---
name: openclaw-installation
description: "Guides OpenClaw installation from source on Nix-managed macOS. Auto-activates when installing, building, or troubleshooting OpenClaw. Covers prerequisites (pnpm via Nix), cloning, building, onboarding wizard, and daemon setup. Trigger keywords: openclaw, open-claw, pnpm install, pnpm build, ui:build, onboard, install-daemon, gateway daemon, launchd, personal AI assistant. (project)"
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Installing OpenClaw from Source

## Core Principles

1. **pnpm via Nix only** — never `npm install -g pnpm` or `corepack enable` on Nix-managed Node.js (EACCES on `/nix/store/`). See [nodejs-version-management](../../nix/nodejs-version-management/SKILL.md).
2. **Build order**: `ui:build` before `build` — skipping causes incomplete output.
3. **Onboarding is interactive** — present the command for the user to run manually; never automate it.

### Prerequisites

| Requirement | Minimum | Verify |
|-------------|---------|--------|
| Node.js | >= 22 | `node --version` |
| pnpm | any | `pnpm --version` |

If pnpm is missing, add to `flake.nix`:

```nix
# home.packages
home.packages = with pkgs; [ nodePackages.pnpm ];
# Then: darwin-rebuild switch
```

### Steps

#### 1. Clone

```bash
git clone https://github.com/openclaw/openclaw.git ~/src/openclaw
```

#### 2. Install dependencies

```bash
cd ~/src/openclaw && pnpm install
```

#### 3. Build (order matters)

```bash
pnpm ui:build && pnpm build
```

#### 4. Run onboarding (user must run this manually)

```bash
pnpm openclaw onboard --install-daemon
```

Sets up the Gateway daemon via launchd, creates workspace/configuration, and walks through permissions. The `--install-daemon` flag is required for persistence.

#### 5. Verify

```bash
pnpm openclaw --version
launchctl list | grep openclaw
```

### Files Created

| Path | Description |
|------|-------------|
| `~/src/openclaw/` | Cloned repository |
| `~/Library/LaunchAgents/` | Gateway daemon plist (created by onboard wizard) |

### Security Note

OpenClaw gives an AI agent access to your machine. The onboarding wizard walks through permissions. Be cautious with third-party skills — Cisco's security team has flagged risks.
