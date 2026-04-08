---
name: api-endpoint-metadata-verification
description: Systematic approach to debugging missing metadata in API integrations. Auto-activates when discussing API response issues, missing attribution, incomplete data, or MCP server debugging. Covers endpoint comparison, response structure verification, and data enrichment patterns. Trigger keywords: API missing metadata, incomplete API response, unknown source, API attribution, export vs detail endpoint, MCP server missing data, enrich API data. (global)
---

# API Endpoint Metadata Verification

Prevent missing metadata bugs by verifying API endpoint responses contain required fields before implementing transformation logic.

## Steps

### 1. Inspect Actual Response
```python
response = requests.get(endpoint, headers=headers, params={"limit": 2})
print(json.dumps(response.json()["results"][0], indent=2))
print("Available fields:", list(response.json()["results"][0].keys()))
```

### 2. Compare Endpoints

Check for `/export/`, `/detailed/`, `/full/` variants. Compare fields vs. requirements:

| Field | `/highlights/` | `/export/` | Required? |
|-------|----------------|------------|-----------|
| Highlight text | Direct | Nested | Yes |
| Source title | Missing | Book level | **Yes** |
| Author | Missing | Book level | **Yes** |

### 3. Enrich Nested Data

Copy parent metadata to child records:
```python
for parent in parents:
    parent_metadata = extract_parent_fields(parent)
    for child in parent.get("children", []):
        child.update(parent_metadata)
        process_child(child)
```

### 4. Verify Output
```bash
grep -l "Unknown Source" output_directory/*.md | wc -l  # Should be 0
```

## Key Rules

- Always fetch sample responses before implementing — never trust docs alone
- Choose rich endpoints over minimal ones when you need metadata
- Investigate missing metadata rather than accepting defaults
- Verify data availability before writing transformation code

## Origin: Readwise Highlights (January 2026)

`/highlights/` returned only `['id', 'text', 'book_id', 'updated', 'readwise_url']` — no attribution. Switched to `/export/` (books with nested highlights), enriched each highlight with parent book metadata. Fixed 71 imports.

Reference implementation: `readwise-mcp-server/server.py:886-973`

## Optimization History

- **March 13, 2026**: Applied five-step optimizer. Deleted Purpose blockquote (~2 lines), Trigger section (~5 lines, duplicates frontmatter), Core Principles (~5 lines, merged into key rules), Forbidden Patterns with wrong/right code (~16 lines, merged into key rules), full Readwise example code block (~8 lines, condensed to summary), Output section (~4 lines), Integration section (~8 lines), footer (~2 lines). Preserved methodology steps, comparison table, enrichment pattern, verification. 132 → 58 lines (56%).
