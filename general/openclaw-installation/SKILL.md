---
name: openclaw-installation
description: "Guides OpenClaw installation from source on Nix-managed macOS. Auto-activates when installing, building, or troubleshooting OpenClaw. Covers prerequisites (pnpm via Nix), cloning, building, onboarding wizard, and daemon setup. Trigger keywords: openclaw, open-claw, pnpm install, pnpm build, ui:build, onboard, install-daemon, gateway daemon, launchd, personal AI assistant. (project)"
allowed-tools: Read, Grep, Glob, Bash
---

# Installing OpenClaw from Source

## Instructions

### Core Principles

1. **pnpm is required** - OpenClaw uses pnpm workspaces (35 workspace projects)
2. **Install pnpm via Nix** - Never `npm install -g pnpm` on Nix-managed Node.js (see nodejs-version-management skill)
3. **Build order matters** - `ui:build` must run before `build`
4. **Onboarding is interactive** - The `onboard --install-daemon` wizard requires user input; don't run it non-interactively

### Prerequisites

| Requirement | Minimum | How to verify |
|-------------|---------|---------------|
| Node.js | >= 22 | `node --version` |
| pnpm | any | `pnpm --version` |
| macOS | supported | `uname -s` |

### Installing pnpm on Nix-managed systems

```nix
# In flake.nix home.packages
home.packages = with pkgs; [
  nodePackages.pnpm
];
# Then: darwin-rebuild switch
```

See [nodejs-version-management skill](../../nix/nodejs-version-management/SKILL.md) for why `npm install -g pnpm` and `corepack enable` fail.

### REQUIRED Steps

### 1. Clone

```bash
git clone https://github.com/openclaw/openclaw.git ~/src/openclaw
```

### 2. Install dependencies

```bash
cd ~/src/openclaw && pnpm install
```

Expect ~996 packages across 35 workspace projects. Takes ~30 seconds.

### 3. Build UI first, then project

```bash
pnpm ui:build
pnpm build
```

### 4. Run onboarding (interactive — user must run this)

```bash
pnpm openclaw onboard --install-daemon
```

This wizard:
- Sets up the Gateway daemon via launchd on macOS
- Creates workspace and configuration
- Walks through permissions

### 5. Verify

```bash
pnpm openclaw --version
launchctl list | grep openclaw
```

### FORBIDDEN Patterns

### Never install pnpm via npm or corepack on Nix

```bash
# ❌ WRONG - EACCES on /nix/store/
npm install -g pnpm
corepack enable pnpm

# ❌ WRONG - Standalone installer fails on Nix-managed .zshrc
curl -fsSL https://get.pnpm.io/install.sh | sh -

# ✅ RIGHT - nodePackages.pnpm in flake.nix home.packages
```

### Never run onboarding non-interactively

```bash
# ❌ WRONG - Wizard requires user input for permissions
pnpm openclaw onboard --install-daemon  # Don't run via automation

# ✅ RIGHT - Present the command for the user to run manually
```

### Never skip ui:build

```bash
# ❌ WRONG - Build will fail or produce incomplete output
pnpm build

# ✅ RIGHT - UI must be built first
pnpm ui:build && pnpm build
```

### Files Created/Modified

| Path | Description |
|------|-------------|
| `~/src/openclaw/` | Cloned repository |
| `~/Library/LaunchAgents/` | Gateway daemon plist (created by onboard wizard) |
| `flake.nix` home.packages | `nodePackages.pnpm` added (if not present) |

### Security Note

OpenClaw gives an AI agent access to your machine. The onboarding wizard walks through permissions. Be cautious when installing community skills — Cisco's security team has flagged risks with third-party skills.

### Common Mistakes

1. **Attempting `npm install -g pnpm`** on Nix-managed Node.js — EACCES error (February 2026)
2. **Running `pnpm build` without `pnpm ui:build` first** — incomplete build
3. **Running the onboard wizard non-interactively** — requires user input for permission decisions
4. **Forgetting `--install-daemon`** — daemon won't be set up for persistence

### Integration

- **Related Skills**: [nodejs-version-management](../../nix/nodejs-version-management/SKILL.md) for pnpm installation via Nix
- **Project Documentation**: See [CLAUDE.md](../../CLAUDE.md) for flake.nix structure
- **Repository**: https://github.com/openclaw/openclaw

### When to Use This Skill

This skill auto-activates when:
- User asks to install OpenClaw
- Building or rebuilding OpenClaw from source
- Troubleshooting OpenClaw build failures
- Setting up the OpenClaw Gateway daemon
