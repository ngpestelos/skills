---
name: skill-to-prompt-porter
description: Port Claude Code skills into standalone prompts for external LLMs (Grok, ChatGPT, Gemini) — methodology extraction, infrastructure stripping, modality adaptation
metadata:
  version: "1.0.1"
---

# Porting Skills to Standalone LLM Prompts

## Core Principles

1. **Methodology is portable, infrastructure is not**: Decision trees and quality standards transfer. Git, MCP, wiki-links do not.
2. **Preserve the quality floor**: Non-negotiable standards are the skill's real value — never drop them to simplify.
3. **Adapt modality, not methodology**: If original reads files, ported prompt processes screenshots or pasted text. Analysis stays identical.
4. **Self-contained means self-contained**: Works with zero context about vault, PARA, or Claude Code.

## Three-Layer Separation

| Layer | Action | Contents |
|-------|--------|----------|
| **Methodology** (KEEP) | Port entirely | Decision trees, quality standards, forbidden patterns, templates, grouping heuristics |
| **Infrastructure** (STRIP) | Remove completely | Git ops, MCP calls, wiki-link verification, README updates, archival, file paths, batch processing |
| **Modality** (ADAPT) | Transform for platform | Input/output interfaces |

### Modality Adaptation Table

| Original (Claude Code) | Adapted (External LLM) |
|------------------------|------------------------|
| `Read` tool on .md files | Screenshot, pasted text, URL |
| `Write` tool to create files | Raw markdown in chat |
| `Grep`/`Glob` for existing notes | User handles deduplication |
| Wiki-links `[[Note Name]]` | Plain text or omit |
| Archival workflow | Omit entirely |

## 7-Step Porting Workflow

1. **Read source skill** — classify every section as Layer 1/2/3
2. **Extract decision tree** — core analysis logic transfers verbatim
3. **Extract quality standards** — consolidate all REQUIRED/CRITICAL/FORBIDDEN into one section
4. **Extract forbidden patterns** — port ones that apply without infrastructure
5. **Build output template** — strip tool-specific fields, replace with platform equivalents
6. **Add input handling** — screenshot (transcribe first, describe visuals, flag incomplete), pasted text (accept as-is, ask for source), URL (fetch and extract metadata)
7. **Write prompt document** — single markdown file:

```markdown
# [Skill Name] Prompt

> **Usage**: [One-line instruction]

---

## System Prompt

[Instructions: input handling + methodology + output template + quality standards + forbidden patterns]

---

*Methodology adapted from [skill name].*
```

## Key Rules

- Never port infrastructure as instructions ("create a topic subdirectory" is meaningless in ChatGPT)
- Never drop quality standards to make the prompt shorter — standards ARE the value
- Never keep wiki-link syntax on platforms where it's meaningless
- Always add explicit input handling — screenshots need transcription instructions
- Collapse multi-phase workflows into single-pass: analyze input, produce output
