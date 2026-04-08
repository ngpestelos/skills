---
name: claude-code-hook-development
description: "Guides creating, testing, and deploying Claude Code hooks via nix-darwin. Auto-activates when creating hook scripts, configuring settings.json hooks section, or adding UserPromptSubmit handlers. Covers hook input JSON format, exit codes, stdout context injection, nix-darwin deployment with executable flag. Trigger keywords: hook, UserPromptSubmit, settings.json hooks, hook script, exit code, stdin JSON, transcript_path."
metadata:
  version: 1.0.0
---

# Developing Claude Code Hooks

> **Purpose**: Create shell-based Claude Code hooks that receive JSON on stdin and inject context or block prompts, deployed via nix-darwin home.file entries.

## Core Principles

1. **Hooks are shell scripts** that receive JSON on stdin, communicate via stdout (context) or exit codes (pass/block)
2. **Deploy through nix-darwin** using `home.file` with `executable = true` for hooks, `force = true` for config
3. **settings.json is the hook registry** — declare hooks with type, command path, and timeout
4. **Hooks must be fast** — they run on every prompt; keep logic minimal and timeouts under 10 seconds

## Required Patterns

### Hook input parsing

Always read stdin once into a variable, then parse fields with jq:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
```

**Critical**: stdin is a stream — reading it twice gives empty on the second read. Always capture with `INPUT=$(cat)` first.

### UserPromptSubmit input fields

```json
{
  "session_id": "string",
  "transcript_path": "string",
  "cwd": "string",
  "permission_mode": "default|plan|acceptEdits|dontAsk|bypassPermissions",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "string"
}
```

### Exit codes

| Exit Code | Behavior |
|-----------|----------|
| 0 | Pass — stdout text becomes context Claude sees |
| 2 | Block — stderr shown as error, prompt rejected |

### settings.json hook registration

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/my-hook.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### nix-darwin deployment

```nix
-- Hooks need executable = true
home.file.".claude/hooks/my-hook.sh" = {
  source = ./config/claude/hooks/my-hook.sh;
  executable = true;
};

-- Config files use force = true (not executable)
home.file.".claude/settings.json" = {
  source = ./config/claude/settings.json;
  force = true;
};
```

## Quick Decision Tree

| Need | Approach |
|------|----------|
| Add context to every prompt | UserPromptSubmit hook, exit 0, stdout text |
| Block certain prompts | UserPromptSubmit hook, exit 2, stderr message |
| Periodic quality check | Create a `/command` instead |
| Complex analysis | Create a `/command` — hooks must be fast |

## Common Mistakes

1. **Missing jq dependency** — ensure `jq` is in `home.packages`
2. **Wrong nix-darwin flag** — hook scripts need `executable = true`, config files need `force = true`; mixing them up silently breaks hooks
3. **Heavy processing** — hooks run on every prompt; keep under 5-10 seconds
4. **Missing transcript at session start** — `transcript_path` file may not exist yet; guard reads
5. **Flat string search on transcripts** — transcripts embed system context (MEMORY.md, CLAUDE.md, skill listings) that contain keyword matches; use structural JSONL parsing instead

## Transcript Parsing

Transcripts are JSONL. Flat text search produces false positives because system context contains skill/command names as text.

**Correct approach**: Parse line-by-line, filter by `type` field:

| `type` field | Contains | Safe for detection? |
|---|---|---|
| `user` | Real user messages + `<command-message>` tags | Yes |
| `assistant` | Tool calls (`tool_use` blocks), thinking | Tool calls only |
| `progress` | Streaming progress | No — duplicates |
| (system context) | MEMORY.md, CLAUDE.md, skill listings | No — text references |

For user slash commands, match `<command-message>name</command-message>` in messages with `type: "user"`. For programmatic tool calls, check `tool_use` blocks with `name: "Skill"` in `type: "assistant"` messages.
