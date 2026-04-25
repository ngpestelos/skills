---
name: vision-fallback-claude-code
description: "Fallback patterns when vision analysis fails due to API limits. Two methods: Claude Code CLI delegation and browser accessibility tree. Trigger: vision API limits exceeded, 403 errors, monthly quota reached, image extraction failed."
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.1"
---

# Vision Fallback

When vision analysis fails (403, quota exceeded, rate limited), use these fallbacks:

## Method 1: Claude Code CLI (Local Images)

### Option A: Direct terminal command

For local image files when vision API fails or no browser session exists:

```bash
# Basic usage
claude -p "Analyze these images and describe [what you need]: /path/to/image1.jpg /path/to/image2.jpg" --allowedTools Read

# Cost-optimized (use Sonnet instead of default Opus)
claude -p "Your prompt here" --model claude-sonnet-4-6 --allowedTools Read
```

**Requirements:**
- Use `-p` (prompt mode) not interactive mode
- Include `--allowedTools Read` so Claude can access the image files
- Use `--model claude-sonnet-4-6` for cheaper inference (Sonnet vs default Opus)
- Multiple images can be passed in one command

**Nix-managed configs:** If `~/.claude/settings.json` is a symlink to nix store, it's read-only. Either:
- Use explicit `--model` flag per command, OR
- Update your nix config to set `"model": "sonnet"` and rebuild

**Note:** Uses Claude Code's separate API quota. Returns natural language — may need parsing.

### Option B: Delegate to subagent

Use `delegate_task` with `acp_command: "claude"` to spawn a Claude Code subagent for complex OCR tasks:

```python
delegate_task(
    goal="Extract text and describe the content of the image at /path/to/image.jpg",
    context="Use Claude Code's vision capabilities or tesseract OCR to extract all text from the image.",
    toolsets=["terminal"],
    acp_command="claude"
)
```

**When to use:** Multi-step processing needed, parsing required, or when you want the subagent to handle tool failures gracefully.

**Note:** Subagent may use tesseract OCR (`tesseract <image> stdout`) as a fallback if Claude's vision fails.

## Method 2: Browser Accessibility Tree

For web pages (not local images), extract text content without vision:

```bash
browser_snapshot(full=true)
```

**Note:** `browser_vision` requires an active browser session (`browser_navigate` must be called first). If you get "No browser session" errors, use Method 1 for local images or navigate first for web images.

Returns the full accessibility tree which often contains the text needed.

