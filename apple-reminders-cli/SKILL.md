---
name: apple-reminders-cli
version: 1.1.0
description: "Use remindctl to manage Apple Reminders from terminal. Quick setup, common operations, troubleshooting. Trigger: remindctl, Apple Reminders CLI, terminal reminders."
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
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
