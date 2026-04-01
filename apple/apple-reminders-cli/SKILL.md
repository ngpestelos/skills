---
name: apple-reminders-cli
version: 1.0.0
description: "Install and use remindctl CLI for Apple Reminders. Covers brew installation, permission setup, and common operations. Trigger: remindctl, Apple Reminders CLI, reminders from terminal."
author: Hermes Agent
license: MIT
platforms: [macos]
metadata:
  hermes:
    tags: [apple, reminders, macos, cli, productivity]
---

# Apple Reminders CLI

Use `remindctl` to manage Apple Reminders from the terminal. Tasks sync across all Apple devices via iCloud.

## Installation

```bash
# Fix Homebrew permissions if needed (common on fresh installs)
sudo chown -R $(whoami) /opt/homebrew

# Install remindctl
brew install steipete/tap/remindctl
```

## Permission Setup

Terminal needs Reminders access:

1. Open **System Settings** → **Privacy & Security** → **Reminders**
2. Add your terminal app (Terminal.app, iTerm, or Ghostty)
3. Enable the checkbox

Or run:
```bash
remindctl authorize
```

## Usage

### View Reminders
```bash
remindctl              # Today's reminders
remindctl today        # Today
remindctl tomorrow     # Tomorrow
remindctl week         # This week
remindctl overdue      # Past due
remindctl all          # Everything
```

### Create Reminders
```bash
remindctl add "Buy milk"
remindctl add --title "Call mom" --list Personal --due tomorrow
remindctl add --title "Meeting prep" --due "2026-04-15 09:00"
```

### Manage Lists
```bash
remindctl list                    # Show all lists
remindctl list Work --create      # Create list
remindctl list Work --delete      # Delete list
```

### Complete / Delete
```bash
remindctl complete 1 2 3          # Complete by ID
remindctl delete 4A83 --force     # Delete by ID
```

## Date Formats

- `today`, `tomorrow`, `yesterday`
- `YYYY-MM-DD`
- `YYYY-MM-DD HH:mm`
- ISO 8601: `2026-04-15T09:00:00Z`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "command not found" | Ensure `/opt/homebrew/bin` is in PATH |
| Permission denied | Grant Reminders access in System Settings |
| Brew install fails | Run `sudo chown -R $(whoami) /opt/homebrew` |
| Timeout / hangs | Terminal lacks Reminders permission - check System Settings |

## Notes

- Reminders sync via iCloud to iPhone/iPad
- Uses native Apple Reminders.app backend
- No separate account needed
