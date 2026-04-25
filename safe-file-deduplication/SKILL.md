---
name: safe-file-deduplication
description: "Multi-phase methodology for safely deduplicating large file collections using content-based analysis. Covers analysis, planning, execution with dry-run, verification, and rollback. Trigger keywords: file deduplication, duplicate files, remove duplicates, archive cleanup, content-based deduplication, mass file operations, safe deletion, .webloc, URL deduplication, hash dedup."
license: MIT
metadata:
  author: ngpestelos
  version: "1.1.1"
---

# Safe Multi-Phase File Deduplication

Deduplicate large file collections using content-based analysis with multiple safety layers.

**Critical**: Files with -1, -2 suffixes may contain different content. Never deduplicate based on filename alone.

## File Selection Priority
When multiple files have identical content:
1. File WITHOUT numeric suffix (base name)
2. If all have suffixes, keep OLDEST (earliest mtime)
3. Break ties with LOWEST suffix number

### Multi-Phase Workflow

| Phase | Mode | Action |
|-------|------|--------|
| 1. Preparation | Setup | Create backup, set up scratchpad |
| 2. Analysis | Read-only | Scan files, extract content IDs, build mapping |
| 3. Plan | Read-only | Apply selection logic, generate deletion plan |
| 4. Execute | Write | Dry-run first, then live with 'DELETE' confirmation |
| 5. Verify | Read-only | Re-scan, confirm no duplicates, verify counts |
| 6. Cleanup | Write | If verified: delete archive. If problems: rollback |

Each phase outputs JSON consumed by the next.

## Content Identifiers by File Type

| File Type | Content Identifier | Keep Priority |
|-----------|-------------------|---------------|
| .webloc | Extract URL from plist | Base name, then oldest |
| HTML/PDF/webarchive | SHA-256 hash | Base name, then oldest |
| Photos (JPG, PNG) | SHA-256 hash | Largest (highest quality) |
| Documents (PDF, DOCX) | SHA-256 hash | Most descriptive name, then newest |
| Videos (MP4, MOV) | Hash first 1MB + file size | Highest resolution |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Missing files during execution | Re-run analysis; verify existence before moving |
| Filename conflicts in archive | Auto-append `_conflictN` counter |
| Parse errors | Skip and log; review `parse_errors` in manifest |
| Verification fails | Check execution log; rollback from archive |

