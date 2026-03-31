---
name: bluebubbles-imessage-setup
description: "Guides BlueBubbles server setup for iMessage integration with OpenClaw. Auto-activates when configuring iMessage channels, installing BlueBubbles, or troubleshooting iMessage connectivity. Covers server installation, macOS permissions, Private API decisions, OpenClaw channel configuration, and webhook setup. Trigger keywords: bluebubbles, imessage, iMessage, Messages.app, chat.db, channel setup, webhook, Private API, SIP, AppleScript, reactions, tapback, pairing, dmPolicy. (project)"
allowed-tools: Read, Grep, Glob, Bash
---

# Setting Up BlueBubbles iMessage Integration

## Instructions

### Core Principles

1. **BlueBubbles is the recommended iMessage channel** — preferred over the legacy `imsg` CLI for new setups
2. **BlueBubbles is a macOS GUI app** — installed via `.dmg` from GitHub, not available via Homebrew or Nix
3. **Private API is optional** — basic send/receive works without it; skip unless you need reactions, edit, unsend
4. **Onboarding is interactive** — both BlueBubbles setup wizard and OpenClaw channel config require user input

### Architecture

BlueBubbles runs as a local server on macOS with three layers:

1. **Database polling** — reads `~/Library/Messages/chat.db` to detect incoming messages (requires Full Disk Access)
2. **AppleScript** — sends messages and attachments via Messages.app (requires Automation permission)
3. **Private API** (optional) — Objective-C bundle hooking into iMessage internals for reactions, edit, unsend, typing indicators, read receipts (requires SIP disabled)

OpenClaw connects to BlueBubbles over HTTP (REST API + webhooks) on localhost.

### ✅ REQUIRED Steps

### 1. Install BlueBubbles Server

Download `.dmg` from [GitHub releases](https://github.com/BlueBubblesApp/BlueBubbles-Server/releases).

```bash
# App is unsigned — must right-click > Open to bypass Gatekeeper
# Or allow in System Settings > Privacy & Security after first blocked launch
```

### 2. Grant macOS Permissions

In **System Settings > Privacy & Security**, grant BlueBubbles:
- **Full Disk Access** (read chat.db)
- **Accessibility**
- **Automation** (AppleScript → Messages.app)
- **Contacts** (if you want contact name resolution)

### 3. Configure BlueBubbles Server Wizard

- **Set a Server Password** — required for API authentication
- **Proxy Setup** — select None for local-only access (OpenClaw on same Mac)
- **Auto Start Method** — set to **Launch Agent** for persistence across reboots/crashes
- **Private API** — skip unless SIP is already disabled (see decision tree below)
- **Open FindMy on Startup** — uncheck unless needed

### 4. Configure OpenClaw

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

### 5. Start and Pair

```bash
# Start the gateway
openclaw gateway

# Approve first DM pairing
openclaw pairing list bluebubbles
openclaw pairing approve bluebubbles <CODE>
```

### ❌ FORBIDDEN Patterns

### Never install BlueBubbles via package managers

```bash
# ❌ WRONG — not available in Homebrew or Nix
brew install bluebubbles
# ❌ WRONG
nix-env -iA nixpkgs.bluebubbles

# ✅ RIGHT — download .dmg from GitHub releases
# https://github.com/BlueBubblesApp/BlueBubbles-Server/releases
```

### Never disable SIP just for BlueBubbles basic features

```bash
# ❌ WRONG — significant security trade-off for optional features
csrutil disable  # just to get reactions working

# ✅ RIGHT — basic send/receive works without Private API
# Enable Private API later only if you specifically need:
# reactions, edit, unsend, reply threading, message effects
```

### Never expose BlueBubbles without authentication

```json5
// ❌ WRONG — no password set, anyone on network can read your messages
{
  channels: {
    bluebubbles: {
      serverUrl: "http://192.168.1.100:1234",
      password: "",
    },
  },
}

// ✅ RIGHT — always set a password
{
  channels: {
    bluebubbles: {
      serverUrl: "http://localhost:1234",
      password: "strong-password-here",
    },
  },
}
```

### Quick Decision Tree

| Question | Answer |
|----------|--------|
| Need iMessage with OpenClaw? | Use BlueBubbles (recommended) or legacy imsg |
| Need reactions, edit, unsend? | Requires Private API (SIP must be disabled) |
| Just need send/receive? | Skip Private API, basic setup is sufficient |
| Running on same Mac? | Use `http://localhost:<port>`, skip proxy |
| Running on remote Mac? | Configure proxy service or SSH tunnel |
| Want auto-restart on crash? | Set Auto Start Method to Launch Agent |

### Private API Decision

The Private API enables advanced features but requires **disabling System Integrity Protection (SIP)**:

| Feature | Without Private API | With Private API |
|---------|-------------------|-----------------|
| Send/receive messages | ✅ | ✅ |
| Attachments | ✅ | ✅ |
| Reactions/tapbacks | ❌ | ✅ |
| Edit messages | ❌ | ✅ (macOS 13+, broken on Tahoe) |
| Unsend messages | ❌ | ✅ (macOS 13+) |
| Reply threading | ❌ | ✅ |
| Message effects | ❌ | ✅ |
| Typing indicators | ❌ | ✅ |
| Read receipts | ❌ | ✅ |

**Recommendation**: Start without Private API. Add it later if needed.

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

### Common Mistakes

1. **Trying to install via Homebrew/Nix** — BlueBubbles is a macOS GUI app, `.dmg` only (February 2026)
2. **Disabling SIP for basic features** — unnecessary; basic send/receive works without Private API
3. **Leaving Auto Start as "Do Not Auto Start"** — server won't survive reboots or crashes
4. **Forgetting to uncheck "Open FindMy on Startup"** — FindMy opens every time BlueBubbles starts
5. **Not setting a password** — API is unauthenticated by default
6. **macOS Gatekeeper blocking the app** — must right-click > Open or allow in Privacy & Security

### Access Control

| Policy | Behavior |
|--------|----------|
| `pairing` (default) | Unknown senders get a pairing code; approve via CLI |
| `allowlist` | Only configured handles accepted |
| `open` | Accepts all DMs |
| `disabled` | Blocks all DMs |

### Integration

- **Related Skills**: [OpenClaw Installation](../openclaw-installation/SKILL.md) for base install
- **OpenClaw Docs**: `~/src/openclaw/docs/channels/bluebubbles.md` (full reference)
- **Legacy Alternative**: `~/src/openclaw/docs/channels/imessage.md` (imsg CLI)
- **BlueBubbles**: [bluebubbles.app](https://bluebubbles.app) | [GitHub](https://github.com/BlueBubblesApp/bluebubbles-server)

### When to Use This Skill

This skill auto-activates when:
- Setting up iMessage integration with OpenClaw
- Installing or configuring BlueBubbles server
- Troubleshooting iMessage channel connectivity
- Deciding between BlueBubbles and legacy imsg
- Configuring DM pairing or access control for iMessage
