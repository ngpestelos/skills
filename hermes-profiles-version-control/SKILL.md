---
name: hermes-profiles-version-control
version: 1.1.0
description: "Manage Hermes profiles in git. Move profiles to version control with symlinks. Trigger: hermes profiles git, profile version control, profiles in repo."
author: Hermes Agent
license: MIT
platforms: [any]
metadata:
  hermes:
    tags: [hermes, profiles, version-control, git, configuration]
---

# Hermes Profiles Version Control

Centralize Hermes profiles in git while keeping runtime state local.

## Quick Start

```bash
# Create profile in Hermes
hermes profile create myprofile --clone

# Move to version control
cp -r ~/.hermes/profiles/myprofile ~/src/hermes-config/profiles/
rm -rf ~/.hermes/profiles/myprofile
ln -s ~/src/hermes-config/profiles/myprofile ~/.hermes/profiles/myprofile

# Commit
cd ~/src/hermes-config
git add profiles/myprofile
git commit -m "Add myprofile"
```

## Structure

```
~/src/hermes-config/          # Git repo
└── profiles/
    └── myprofile/
        ├── config.yaml       # In git
        ├── SOUL.md           # In git
        └── .env              # In git (or use env vars)

~/.hermes/profiles/
└── myprofile -> ~/src/hermes-config/profiles/myprofile  # Symlink
```

## What Goes in Git

| File | In Git? | Notes |
|------|---------|-------|
| config.yaml | Yes | Model, provider, tools |
| SOUL.md | Yes | Personality, identity |
| .env | Yes | API keys (encrypt if sensitive) |
| sessions/, logs/, skills/ | No | Runtime state |

## .gitignore Template

```gitignore
# Runtime state
profiles/*/sessions/
profiles/*/logs/
profiles/*/cron/
profiles/*/plans/
profiles/*/memories/
profiles/*/skills/
profiles/*/skins/
profiles/*/workspace/
```

## Managing Profiles

**Update a profile:**
```bash
# Edit in repo (changes apply immediately)
nvim ~/src/hermes-config/profiles/myprofile/SOUL.md
```

**Switch default:**
```bash
hermes profile use myprofile
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Profile not found | Check symlink: `ls -la ~/.hermes/profiles/` |
| Broken symlink | Recreate: `ln -sf ~/src/hermes-config/profiles/X ~/.hermes/profiles/X` |
| Git shows runtime files | Add to .gitignore, `git rm --cached` them |

## Multi-Machine Setup

Machine A: Create and push profile as shown above.

Machine B:
```bash
git pull
ln -s ~/src/hermes-config/profiles/myprofile ~/.hermes/profiles/myprofile
hermes profile use myprofile
```
