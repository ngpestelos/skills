---
name: safe-file-deduplication
description: "Multi-phase methodology for safely deduplicating large file collections using content-based analysis. Covers analysis, planning, execution with dry-run, verification, and rollback. Trigger keywords: file deduplication, duplicate files, remove duplicates, archive cleanup, content-based deduplication, mass file operations, safe deletion, .webloc, URL deduplication, hash dedup."
license: MIT
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Safe Multi-Phase File Deduplication

Deduplicate large file collections using content-based analysis with multiple safety layers.

## Core Principles

1. **Content over filename** — Files with -1, -2 suffixes may contain different content
2. **Multi-phase** — Separate analysis, planning, execution, verification
3. **Archive, don't delete** — All removals recoverable
4. **Read-only before write** — Complete analysis before any destructive ops

## Methodology

### File Selection Priority
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

### Quick Detection
```bash
find . -maxdepth 1 -name "*-[0-9]*.*" | wc -l
```
Recommend dedup when 500+ files with >1% suffix rate.

### Content Identifiers by File Type

| File Type | Content Identifier | Keep Priority |
|-----------|-------------------|---------------|
| .webloc | Extract URL from plist | Base name, then oldest |
| HTML/PDF/webarchive | SHA-256 hash | Base name, then oldest |
| Photos (JPG, PNG) | SHA-256 hash | Largest (highest quality) |
| Documents (PDF, DOCX) | SHA-256 hash | Most descriptive name, then newest |
| Videos (MP4, MOV) | Hash first 1MB + file size | Highest resolution |

### Safety Mechanisms

- **Backup**: `tar -czf backup.tar.gz source/` before changes
- **Archive, don't delete**: `shutil.move(file, archive_dir)`
- **Dry-run default**: Simulation first; live execution requires typing 'DELETE'

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Missing files during execution | Re-run analysis; verify existence before moving |
| Filename conflicts in archive | Auto-append `_conflictN` counter |
| Parse errors | Skip and log; review `parse_errors` in manifest |
| Verification fails | Check execution log; rollback from archive |

## Key Rules

- Never deduplicate based on filename alone — always check content
- Never permanently delete — always archive to timestamped directory
- Never skip verification phase after execution
- Never run single-phase all-in-one scripts — use multi-phase workflow
