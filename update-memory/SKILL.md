---
name: update-memory
description: "Persist session learnings to memory files. Auto-activates when updating memory, saving learnings, or persisting session context. Trigger keywords: update memory, save memory, persist learnings, remember this."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Update Memory

Run mid-session or before ending to capture session learnings.

## Steps

1. **Scan session** for: project progress, decisions made, feedback given, references discovered, user preferences
2. **Check existing memory** — read MEMORY.md index. Update in place if a file covers the topic, create new if not
3. **Write memory files** with frontmatter:
   ```yaml
   ---
   name: {{name}}
   description: {{one-line description}}
   type: {{user, feedback, project, reference}}
   ---
   {{content — for feedback/project: rule/fact, then Why: and How to apply: lines}}
   ```
4. **Update MEMORY.md index** — one-line pointer per new file, under 150 chars
5. **Report** — list what was saved or updated, one line each

## Rules

- Don't save code patterns, git history, or anything derivable from the codebase
- Don't duplicate what's in CLAUDE.md
- Convert relative dates to absolute (e.g., "yesterday" → "2026-03-29")
- Update stale memories rather than creating duplicates
