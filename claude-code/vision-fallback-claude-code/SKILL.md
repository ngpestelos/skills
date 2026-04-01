---
name: vision-fallback-claude-code
description: "Fallback patterns when vision analysis fails due to API limits. Two methods: Claude Code CLI delegation and browser accessibility tree. Trigger: vision API limits exceeded, 403 errors, monthly quota reached, image extraction failed."
version: 2.0.0
author: ngpestelos
license: MIT
---

# Vision Fallback

When vision analysis fails (403, quota exceeded, rate limited), use these fallbacks:

## Method 1: Claude Code CLI

```bash
claude "Analyze this image and extract [specific details]: [image path]"
```

Uses Claude Code's separate API quota. Returns natural language — may need parsing.

## Method 2: Browser Accessibility Tree

For web pages (not local images), extract text content without vision:

```bash
browser_snapshot(full=true)
```

Returns the full accessibility tree which often contains the text needed.

## Optimization History

- **April 1, 2026**: Five-step optimizer pass 1. Deleted "When to Use" (duplicates frontmatter), obvious steps (try normal first, parse output, update document), considerations table, troubleshooting. 73 → 14 lines (81%).
