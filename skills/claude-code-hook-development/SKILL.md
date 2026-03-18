---
name: claude-code-hook-development
description: "Guides creating, testing, and deploying Claude Code hooks via nix-darwin. Auto-activates when creating hook scripts, configuring settings.json hooks section, or adding UserPromptSubmit handlers. Covers hook input JSON format, exit codes, stdout context injection, nix-darwin deployment with executable flag. Trigger keywords: hook, UserPromptSubmit, settings.json hooks, hook script, exit code, stdin JSON, transcript_path."
metadata:
  version: 1.0.0
---

# Developing Claude Code Hooks

> **Purpose**: Create shell-based Claude Code hooks that receive JSON on stdin and inject context or block prompts, deployed via nix-darwin home.file entries.

## Core Principles

1. **Hooks are shell scripts** that receive a JSON payload on stdin and communicate via stdout (context) or exit codes (pass/block)
2. **Deploy through nix-darwin** using `home.file` with `executable = true` for hooks, `force = true` for config
3. **settings.json is the hook registry** — hooks must be declared there with type, command path, and timeout
4. **Hooks must be fast** — they run on every prompt submission; keep logic minimal and timeouts tight

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

### Exit code conventions

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
# Hooks need executable = true
home.file.".claude/hooks/my-hook.sh" = {
  source = ./config/claude/hooks/my-hook.sh;
  executable = true;
};

# Config files use force = true
home.file.".claude/settings.json" = {
  source = ./config/claude/settings.json;
  force = true;
};
```

## Forbidden Patterns

### Don't read stdin twice

```bash
# WRONG — stdin is a stream, second read gets nothing
PROMPT=$(jq -r '.prompt' < /dev/stdin)
TRANSCRIPT=$(jq -r '.transcript_path' < /dev/stdin)  # Empty!

# RIGHT — save to variable first
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
```

### Don't skip set -euo pipefail

```bash
# WRONG — silent failures corrupt hook behavior
#!/usr/bin/env bash
jq -r '.prompt'  # Could fail silently

# RIGHT
#!/usr/bin/env bash
set -euo pipefail
```

### Don't use force = true for hook scripts

```nix
# WRONG — hooks need executable bit, not force
home.file.".claude/hooks/my-hook.sh" = {
  source = ./config/claude/hooks/my-hook.sh;
  force = true;  # Missing executable!
};

# RIGHT
home.file.".claude/hooks/my-hook.sh" = {
  source = ./config/claude/hooks/my-hook.sh;
  executable = true;
};
```

### Don't set long timeouts

```json
// WRONG — blocks every prompt for up to 30 seconds
{ "type": "command", "command": "...", "timeout": 30 }

// RIGHT — keep under 10 seconds
{ "type": "command", "command": "...", "timeout": 10 }
```

## Quick Decision Tree

| Need | Approach |
|------|----------|
| Add context to every prompt | UserPromptSubmit hook, exit 0, stdout text |
| Block certain prompts | UserPromptSubmit hook, exit 2, stderr message |
| Periodic quality check | Create a `/command` instead of a hook |
| Complex analysis | Create a `/command` — hooks must be fast |

## Common Mistakes

1. **Reading stdin twice** — stdin is a stream; save to variable with `INPUT=$(cat)` first
2. **Missing jq dependency** — ensure `jq` is in `home.packages`
3. **Forgetting executable flag** — nix-darwin `home.file` for scripts needs `executable = true`, not `force = true`
4. **Heavy processing in hooks** — hooks run on every prompt; keep them under 5-10 seconds
5. **Not handling missing transcript** — transcript file may not exist at session start
6. **Flat string search on transcripts** — system context is embedded in transcripts; use structural JSONL parsing instead

## Transcript Parsing: Avoiding False Positives

### Wrong — Flat string search on transcript content

Transcripts include system context (MEMORY.md, CLAUDE.md, skill listings)
that reference commands/skills as text. Flat search always matches:

```python
# Permanent false positive — MEMORY.md contains "capture-skill"
content = transcript.read_text()
capture_invoked = "capture-skill" in content
```

### Right — Structural JSONL parsing with type filtering

Parse line-by-line, check `type` field, inspect message structure:

```python
# Only matches real invocations
capture_invoked = False
with open(transcript, encoding="utf-8", errors="replace") as f:
    for line in f:
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue

        # User slash command
        if obj.get("type") == "user":
            msg_content = obj.get("message", {}).get("content", "")
            if isinstance(msg_content, str) and "<command-message>capture-skill</command-message>" in msg_content:
                capture_invoked = True
                break

        # Programmatic Skill tool call
        if obj.get("type") == "assistant":
            for block in (obj.get("message", {}).get("content", []) or []):
                if (isinstance(block, dict)
                        and block.get("type") == "tool_use"
                        and block.get("name") == "Skill"
                        and block.get("input", {}).get("skill") == "capture-skill"):
                    capture_invoked = True
                    break
```

### Key JSONL types to filter

| `type` field | Contains | Safe for action detection? |
|---|---|---|
| `user` | Real user messages + `<command-message>` tags | Yes |
| `assistant` | Tool calls (`tool_use` blocks), thinking | Tool calls only |
| `progress` | Streaming progress updates | No — duplicates |
| (system context) | MEMORY.md, CLAUDE.md, skill listings | No — text references |

## Violation Detection

```bash
# Check hooks are executable after deployment
ls -la ~/.claude/hooks/*.sh

# Validate settings.json hooks section
jq '.hooks' ~/.claude/settings.json

# Verify hook scripts have valid bash syntax
for f in config/claude/hooks/*.sh; do bash -n "$f" && echo "$f: OK"; done
```

## Key Takeaway

Claude Code hooks are shell scripts receiving JSON on stdin — save stdin to a variable once, parse with jq, output context text on stdout, and deploy via nix-darwin `home.file` with `executable = true`.
