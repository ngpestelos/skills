---
name: configuring-dynamic-attribution
description: "Guides updating AI tool templates to use dynamic placeholders for model names instead of hardcoded values. Auto-activates when working with commit templates, co-author attributions, or model-specific references. Trigger keywords: dynamic attribution, model detection, commit template, co-author, placeholder, hardcoded model, attribution template."
metadata:
  version: 1.0.0
---

# Configuring Dynamic Model Attribution

Guides updating AI tool templates to use dynamic placeholders for model names instead of hardcoded values. Ensures accurate co-author attributions across model changes.

## Required Patterns

**Use placeholders for model-specific values**
Replace hardcoded model names with placeholders like `[current model name]` to enable runtime resolution.

```markdown
## Dynamic Attribution

Generate the appropriate co-author attribution based on the AI tool and current model being used:
- **OpenCode**: `Co-Authored-By: [current model name] <noreply@x.ai>`
- **Claude Code**: `Co-Authored-By: Claude [current model/version] <noreply@anthropic.com>`
```

**Document detection logic**
Include instructions for determining the current model at runtime.

```markdown
## Detection Logic

To determine the current model:
- For OpenCode: Use the model name provided in the session environment (e.g., grok-code-fast-1)
- For Claude Code: Use the current Claude model version
```

## Forbidden Patterns

**Hardcode specific model names**
Avoid static references that become outdated when models change.

```markdown
## Dynamic Attribution

Use the appropriate co-author attribution based on the AI tool being used:
- **OpenCode**: `Co-Authored-By: Grok <noreply@x.ai>`  # Static, becomes incorrect
- **Claude Code**: `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`  # Version-specific
```

## Trigger Keywords
- dynamic attribution
- model detection
- commit template
- co-author
- placeholder
- hardcoded model
- attribution template

## Violation Detection Commands
```bash
# Find hardcoded model attributions
grep -r "Co-Authored-By: [A-Za-z].* <noreply@" .claude/commands/ .opencode/commands/
```

## Integration Notes
- Applied in commit.md for /commit command
- Supports portability between OpenCode and Claude Code
- Related to AI tool configuration and commit best practices
