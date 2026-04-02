---
name: skill-pattern-alignment
version: 1.1
description: "Refactor a skill to match an existing reference skill's structure, conventions, and patterns."
triggers:
  - "match this skill to"
  - "align this skill with"
  - "refactor to match"
  - "use same pattern as"
  - "skills should be consistent"
allowed-tools: Read, Grep, Write
---

# Skill Pattern Alignment

Refactor a skill to match an existing reference skill's structure and conventions.

## Steps

1. **Read reference skill** — Identify patterns:
   - Frontmatter structure
   - Section organization
   - Output conventions (`.firecrawl/`, `.cache/`)
   - Tool patterns (`npx` CLI vs API calls)

2. **Refactor target skill** — Apply patterns while preserving domain specifics:
   - Match section structure
   - Use same output conventions
   - Keep site-specific URLs, unique pitfalls, related skills

## Common Patterns

| Pattern | Example |
|---------|---------|
| Firecrawl CLI | `npx firecrawl scrape URL -o .firecrawl/file.md` |
| Environment loading | `set -a && source ~/.hermes/.env && set +a` |
| Section order | Quick Start → Extract → Key Findings → Pitfalls → Related Skills |
| Timestamped files | `.firecrawl/file-$(date +%Y%m%d).md` |

## Example

**Reference:** `gaswatchph-price-fetcher` → **Target:** `philippine-cinema-search`

Changes:
- `execute_code` API → `npx firecrawl scrape` CLI
- In-memory → `.firecrawl/ctc-movies.md` output
- Added Key Findings, Related Skills sections
