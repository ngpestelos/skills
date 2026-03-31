---
name: bluebubbles-imessage-setup
description: "Guides BlueBubbles server setup for iMessage integration with OpenClaw. Auto-activates when configuring iMessage channels, installing BlueBubbles, or troubleshooting iMessage connectivity. Covers server installation, macOS permissions, Private API decisions, OpenClaw channel configuration, and webhook setup. Trigger keywords: bluebubbles, imessage, iMessage, Messages.app, chat.db, channel setup, webhook, Private API, SIP, AppleScript, reactions, tapback, pairing, dmPolicy. (project)"
allowed-tools: Read, Grep, Glob, Bash
---

# Setting Up BlueBubbles iMessage Integration

## Instructions

### Core Principles

1. **BlueBubbles is the recommended iMessage channel** -- preferred over legacy `imsg` CLI
2. **macOS GUI app only** -- `.dmg` from GitHub releases, NOT available via Homebrew or Nix
3. **Private API is optional** -- basic send/receive works without it; skip unless you need reactions, edit, unsend
4. **Onboarding is interactive** -- both BlueBubbles wizard and OpenClaw channel config require user input

### Architecture

BlueBubbles runs as a local server on macOS with three layers:

1. **Database polling** -- reads `~/Library/Messages/chat.db` (requires Full Disk Access)
2. **AppleScript** -- sends messages via Messages.app (requires Automation permission)
3. **Private API** (optional) -- Obj-C bundle hooking into iMessage internals for reactions, edit, unsend, typing, read receipts (requires SIP disabled)

OpenClaw connects via HTTP (REST API + webhooks) on localhost.

### Setup Steps

#### 1. Install BlueBubbles Server

Download `.dmg` from [GitHub releases](https://github.com/BlueBubblesApp/BlueBubbles-Server/releases). App is unsigned -- right-click > Open to bypass Gatekeeper, or allow in System Settings > Privacy & Security.

#### 2. Grant macOS Permissions

In **System Settings > Privacy & Security**, grant BlueBubbles:
- **Full Disk Access** (read chat.db)
- **Accessibility**
- **Automation** (AppleScript -> Messages.app)
- **Contacts** (optional, for name resolution)

#### 3. Configure BlueBubbles Server Wizard

- **Server Password** -- required for API auth; always set one
- **Proxy Setup** -- None for local-only (OpenClaw on same Mac)
- **Auto Start Method** -- Launch Agent (persists across reboots/crashes)
- **Private API** -- skip unless SIP already disabled
- **Open FindMy on Startup** -- uncheck

#### 4. Configure OpenClaw

```json5
{
  channels: {
    bluebubbles: {
      enabled: true,
      serverUrl: "http://localhost:<port>",  // from BlueBubbles dashboard
      password: "<your-password>",
      webhookPath: "/bluebubbles-webhook",
    },
  },
}
```

#### 5. Start and Pair

```bash
openclaw gateway
openclaw pairing list bluebubbles
openclaw pairing approve bluebubbles <CODE>
```

### Private API Decision

Requires **disabling SIP** -- significant security trade-off. Never disable SIP just for basic send/receive.

| Feature | Without | With Private API |
|---------|---------|-----------------|
| Send/receive, attachments | Yes | Yes |
| Reactions/tapbacks | No | Yes |
| Edit/unsend | No | Yes (macOS 13+, broken on Tahoe) |
| Reply threading, effects | No | Yes |
| Typing indicators, read receipts | No | Yes |

**Recommendation**: Start without. Add later if needed.

### Quick Reference

| Question | Answer |
|----------|--------|
| Same Mac as OpenClaw? | `http://localhost:<port>`, skip proxy |
| Remote Mac? | Configure proxy or SSH tunnel |
| Just send/receive? | Skip Private API |
| Need reactions/edit/unsend? | Requires Private API (SIP disabled) |

### Access Control (dmPolicy)

| Policy | Behavior |
|--------|----------|
| `pairing` (default) | Unknown senders get pairing code; approve via CLI |
| `allowlist` | Only configured handles accepted |
| `open` | Accepts all DMs |
| `disabled` | Blocks all DMs |

### Headless/VM Workaround

Messages.app can go idle on headless setups. Use a LaunchAgent to poke it every 5 minutes:

```applescript
-- ~/Scripts/poke-messages.scpt
try
  tell application "Messages"
    if not running then launch
    set _chatCount to (count of chats)
  end tell
on error
end try
```

See `~/src/openclaw/docs/channels/bluebubbles.md` for the full LaunchAgent plist.

### Integration

- **Related Skills**: [OpenClaw Installation](../openclaw-installation/SKILL.md)
- **OpenClaw Docs**: `~/src/openclaw/docs/channels/bluebubbles.md`
- **Legacy Alternative**: `~/src/openclaw/docs/channels/imessage.md` (imsg CLI)
- **BlueBubbles**: [bluebubbles.app](https://bluebubbles.app) | [GitHub](https://github.com/BlueBubblesApp/bluebubbles-server)
