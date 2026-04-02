---
name: skill-pattern-alignment
version: 1.0
description: "Refactor a skill to match an existing reference skill's structure, conventions, and patterns. Use when skills in the same domain should share consistent design patterns."
triggers:
  - "match this skill to"
  - "align this skill with"
  - "refactor to match"
  - "use same pattern as"
  - "skills should be consistent"
allowed-tools: Read, Grep, Write
---

# Skill Pattern Alignment

Refactor a skill to match an existing reference skill's structure, conventions, and patterns.

## When to Use

- New skill in same domain as mature skill
- Multiple skills with inconsistent approaches
- Establishing conventions across skill library
- User requests: "make this like [other skill]"

## Steps

1. **Read reference skill** — Identify its patterns:
   - Frontmatter structure (`allowed-tools`, `requires_environment`)
   - Section organization (Quick Start → Extract → Key Findings → Pitfalls)
   - Output conventions (`.firecrawl/`, `.cache/`)
   - Tool usage patterns (`npx` CLI vs API calls)
   - Extraction approach (bash, python, both)

2. **Compare with target skill** — Map differences:
   - Missing sections?
   - Different tool patterns?
   - Inconsistent output locations?
   - Different environment handling?

3. **Refactor target skill** — Apply reference patterns:
   - Copy section structure
   - Match frontmatter style
   - Use same output conventions
   - Align extraction approaches

4. **Preserve domain specifics** — Keep unique content:
   - Site-specific URLs
   - Domain-specific pitfalls
   - Unique extraction patterns
   - Related skills links

## Common Patterns to Align

| Pattern | Example |
|---------|---------|
| Firecrawl CLI | `npx firecrawl scrape URL -o .firecrawl/file.md` |
| Environment loading | `set -a && source ~/.hermes/.env && set +a` |
| Output directory | `.firecrawl/` for web scraping |
| Section order | Quick Start → Extract → Key Findings → Pitfalls → Related Skills |
| Extraction | Bash grep first, Python for complex parsing |
| Timestamped files | `.firecrawl/file-$(date +%Y%m%d).md` |

## Example

**Reference:** `gaswatchph-price-fetcher` (Firecrawl-based fuel prices)  
**Target:** `philippine-cinema-search` (Firecrawl-based cinema info)

Changes:
- `execute_code` API calls → `npx firecrawl scrape` CLI
- In-memory extraction → `.firecrawl/ctc-movies.md` output
- Added Key Findings section with domain knowledge
- Added Related Skills link
