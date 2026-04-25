---
name: qmd-local-search
description: "Core patterns for using QMD (Quick Markdown) semantic search. Auto-activates when discussing local search, semantic search, vector search, QMD MCP tools, or index management. Covers MCP tool usage, search type selection, index rebuild protocol, and troubleshooting. Trigger keywords: qmd, semantic search, vector search, local search, qmd_query, qmd_search, qmd_vsearch, embedding, collection, database corruption, SQLite error, UNIQUE constraint, rebuild index, failed to reconnect, qmd-mcp-server, model download, 404."
metadata:
  version: "1.0.1"
---

# QMD Local Search

Core patterns for QMD semantic search. Project-specific skills extend this with collection tables and domain patterns.

## MCP Tools

| Tool | Purpose | Best For |
|------|---------|----------|
| `qmd_search` | BM25 keyword search | Exact terms/names, fastest |
| `qmd_vsearch` | Vector semantic search | Concepts, themes, related content |
| `qmd_query` | Hybrid + LLM re-ranking | Complex questions, best quality (slowest) |
| `qmd_get` | Retrieve document by path | Fetching specific files |
| `qmd_multi_get` | Batch document retrieval | Multiple files at once |
| `qmd_status` | Index health check | Verifying configuration |

Use `collection:` parameter to scope searches. If `qmd_*` tools are missing, use CLI via Bash or restart Claude Code to reload MCP.

## Pitfalls

- **Always re-embed after adding documents**: `qmd update && qmd embed` — without this, new content is invisible to vector search
- **Never run concurrent `qmd update`/`qmd embed`** — use `qmd-safe-update` wrapper which handles locking
- **Match search type to query** — don't use `qmd_query` for simple keyword lookups; it's slower for no benefit
- **Collection path must match actual folder name** — the path argument to `qmd collection add` must be the literal directory name on disk (e.g., `1 Areas`, `2 Resources`), NOT an alias or shorthand. Using incorrect paths creates empty collections silently (0 files indexed)

## Adding Collections

Correct pattern:
```bash
qmd collection add "1 Areas" --name "areas"
qmd collection add "2 Resources" --name "resources"
qmd collection add "0 Projects" --name "projects"
```

The `--name` parameter sets the collection alias for queries. The path (first argument) must match the actual folder name exactly — spaces, numbers, and case matter.

## Index Rebuild Protocol

When you see UNIQUE constraint errors or suspect corruption:

```bash
rm ~/.cache/qmd/index.sqlite
qmd update
qmd embed    # ~10-15 min for large indices
qmd status   # Check "Pending: 0"
```

## Troubleshooting

### "Failed to reconnect" Error

**Symptom**: `/mcp` shows `qmd` status "failed" or "failed to reconnect"

**Fix**: Use `qmd-mcp-server` wrapper instead of `qmd mcp` — the wrapper bypasses a `process.exit(0)` in the CLI entry point:
```json
{ "command": "qmd-mcp-server", "args": [] }
```

### Model Download Failure (vsearch/query broken)

**Symptom**: `qmd vsearch`/`qmd query` hangs then 404s downloading a model. `qmd search` (BM25) works fine.

**Fix**: Update QMD flake input — hardcoded model URLs break when HuggingFace renames files:
```bash
cd ~/src/dotfiles && nix flake update qmd
sudo darwin-rebuild switch --flake .#<hostname>
```
No index rebuild needed — embeddings remain valid.

### Project-Level MCP Configuration

User-scope `~/.claude/.mcp.json` servers do NOT load when a project has its own `.mcp.json`. Add `{ "command": "qmd-mcp-server", "args": [] }` to the project's `.mcp.json` `mcpServers`.
