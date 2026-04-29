---
name: readwise-import
description: Import Readwise content (tweets, articles, highlights, books, daily review) into the PARA vault via MCP server. Supports incremental import, backfill to a target date, book/keyword search, and state inspection. Trigger phrases - "import readwise", "backfill readwise", "readwise tweets", "daily highlights", "readwise state", "sync readwise".
version: 1.1.0
author: Nestor Pestelos
license: MIT
category: general
metadata:
  hermes:
    tags: [Readwise, Import, MCP, PARA, Tweets, Highlights]
    related_skills: [readwise-mcp-usage]
---

# Readwise Import

Route a Readwise import request to the correct MCP tool. The server handles deduplication, state, file writing, and naming.

## MCP Tool Routing

| Mode | MCP Tool | Required / Key Params |
|------|----------|-----------------------|
| `daily` | `mcp__readwise__readwise_daily_review` | — |
| `recent` | `mcp__readwise__readwise_import_recent` | `category` (default: tweet), `limit` |
| `recent` + backfill | `mcp__readwise__readwise_backfill` | `target_date` (required), `category` (default: tweet) |
| `book` | `mcp__readwise__readwise_book_highlights` | `title` or `book_id` |
| `search` | `mcp__readwise__readwise_search_highlights` | `query`, `limit` |
| `highlights` | `mcp__readwise__readwise_import_recent_highlights` | `limit` |
| `highlights` + backfill | `mcp__readwise__readwise_backfill_highlights` | `target_date` (required) |
| `state-info` | `mcp__readwise__readwise_state_info` | — |
| `init-ranges` | `mcp__readwise__readwise_init_ranges` | — |
| `reset-state` | `mcp__readwise__readwise_reset_state` | — |

**Default / `combined` mode** (no mode specified): call `readwise_import_recent` (tweets) then `readwise_daily_review` in sequence. This mode does NOT import highlights.

## Excluding Highlights

By default, highlights are NOT imported. To ensure highlights are excluded:
- Use `recent` mode with a specific `category` (e.g., `tweet`, `article`) — imports content only, no highlights
- Use `combined` mode (default) — imports tweets + daily review only
- Use `daily` mode — daily review only
- **Avoid** `highlights` mode, `book` mode, or `search` mode — these explicitly import highlights

## Steps

1. **Map request to mode**:
   - "recent" / "sync tweets" → `recent` (no highlights)
   - "backfill" / "back to [date]" → `recent` + backfill (no highlights) or `highlights` + backfill (includes highlights)
   - "daily" → `daily` (no highlights)
   - "book [title]" → `book` (includes highlights)
   - "search [query]" → `search` (includes highlights)
   - "highlights" → `highlights` (includes highlights)
   - "state" / "what's synced" → `state-info`
   - none of the above → `combined` (no highlights)

2. **Extract params**:
   - `target_date`: MUST be `YYYY-MM-DD`. Convert `20260401`, "Apr 1", "April 1 2026" → `2026-04-01`. Passing `YYYYMMDD` causes a retry loop.
   - `category`: for `recent`, default `tweet`. Valid: `article`, `pdf`, `epub`, `email`, `video`, `rss`, `all`.
   - `title` / `book_id`: prefer `title` if given as a string.
   - `query`, `limit`: pass through if specified.

3. **Call the MCP tool** from the routing table.

4. **Report**: `imported`, `skipped`, `pages` (backfill), `reached_target` (backfill). The server reports file paths itself.

## Critical Rules

- No manual dedup or file writing — the MCP server handles both. Do not pre-check the filesystem or post-write files from responses.
- Backfill `target_date` must be in the past.
- `reset-state` and `init-ranges` only run when explicitly requested. After `init-ranges`, verify with a force backfill; calculated boundaries can miss gaps.

## Troubleshooting: MCP/CLI Timeouts

If MCP tools or Claude Code CLI timeout (common with 120s+ operations), use direct API fallback:

```python
import subprocess, json

def fetch_readwise_direct(category="tweet", limit=50, token="YOUR_TOKEN"):
    url = f"https://readwise.io/api/v3/list/?category={category}&limit={limit}"
    curl_cmd = ['curl', '-s', '-H', f'Authorization: Token {token}', url]
    result = subprocess.run(curl_cmd, capture_output=True, text=True, timeout=60)
    return json.loads(result.stdout)
```

**Token location:** Check `.claude/scripts/readwise-backfill.py` or state files for existing token.
**Deduplication:** Scan `2 Resources/Readwise/Documents/` for existing `document_id` in frontmatter.
**File naming:** Use `sanitize_filename()` pattern from existing scripts.

## Related

- `readwise-mcp-usage` — Readwise API/MCP internals (Reader v3 vs Highlights v2, cursor pagination, rate limits)
