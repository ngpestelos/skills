---
name: apple-reminders-cli
description: "Use remindctl to manage Apple Reminders from terminal. Quick setup, common operations, troubleshooting. Trigger: remindctl, Apple Reminders CLI, terminal reminders."
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  version: "1.1.1"
  hermes:
    tags: [apple, reminders, macos, cli, productivity]
---

# Apple Reminders CLI

Manage Apple Reminders from the terminal. Tasks sync to iPhone/iPad via iCloud.

## Quick Start

```bash
# One-time setup
sudo chown -R $(whoami) /opt/homebrew
brew install steipete/tap/remindctl
remindctl authorize  # Grant Terminal access when prompted

# Create a reminder
remindctl add "Buy milk" --due tomorrow
```

## Hermes/Agent Usage Pattern

**Delegate to Claude Code**: When an AI agent (Hermes) needs to check or manage reminders, delegate to Claude Code rather than executing directly. This avoids permission issues and provides better error handling.

```python
# Pattern: Load skill, then delegate
delegate_task(
    goal="Check Apple Reminders using remindctl. Show today's reminders and upcoming week's reminders.",
    context="User wants to see their Apple Reminders. Use remindctl to fetch today's and this week's reminders.",
    toolsets=["terminal"],
    acp_command="claude"
)
```

**Why delegate**: Claude Code runs in a local environment where `remindctl authorize` has already been granted Reminders access. Direct execution from Hermes may fail due to sandboxed permissions or missing authorization.

## Usage

```bash
remindctl              # Today's reminders
remindctl today        # Today
remindctl tomorrow     # Tomorrow
remindctl week         # This week
remindctl add "Task" --due "2026-04-15 09:00"
remindctl complete 1   # Complete by ID
remindctl delete 2 --force
```

See `remindctl --help` for all options and date formats.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "command not found" | Ensure `/opt/homebrew/bin` is in PATH |
| Permission denied | System Settings → Privacy & Security → Reminders → Enable Terminal |
| Brew install fails | `sudo chown -R $(whoami) /opt/homebrew` |
| Timeout/hangs | Terminal lacks Reminders permission |
| "List not found" | Run `remindctl list` to see available lists |

## Common Flags

| Flag | Description |
|------|-------------|
| `--due <value>` | Due date/time (e.g., `tomorrow`, `2026-04-15 09:00`) |
| `-l, --list <name>` | Target list (use `remindctl list` to see available) |
| `-n, --notes <text>` | Additional notes for the reminder |
| `-p, --priority <level>` | none, low, medium, high |

## Notes

- Requires macOS with Reminders.app
- Syncs via iCloud to all Apple devices
