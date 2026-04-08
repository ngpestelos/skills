---
name: repo-flattening
description: "Flatten a two-level category/name directory structure to flat name/ in a git repo. Covers pre-flight collision detection, bulk git mv, updating shell discovery scripts, JSON path registries, and Markdown links. Trigger keywords: flatten directory, remove category dirs, flat structure, restructure repo, two-level to flat."
metadata:
  version: "1.1"
allowed-tools: Read, Grep, Glob, Bash
---

# Repo Directory Flattening

Convert `<category>/<name>/item` → `<name>/item` across a git repo, preserving history.

## Pre-flight Checklist

Before any `git mv`:

1. **Detect name collisions** — the same skill/module name may exist in multiple categories:
   ```bash
   for cat in category1 category2 ...; do ls "$cat/" 2>/dev/null; done \
     | sort | uniq -d
   ```
   Resolve each: pick the canonical copy, `git rm -r` the other.

2. **Handle already-flat untracked dirs** — files already at root that would conflict with `git mv` targets. Compare versions, keep the more complete one, `git add` it.

3. **Remove symlinks** — no symlinks should exist in the repo root. `rm` them before the glob-based tooling picks them up.

4. **Record baseline** — count symlinks in dependent install targets (e.g., `~/.claude/skills/`) before migration; verify restoration after.

## Step 1: Bulk `git mv`

```bash
git mv <category>/<name> <name>
```

Run for every skill/module. `git mv` moves the entire subtree (including subdirs like `references/`). After all moves, remove now-empty category dirs:

```bash
for cat in ...; do rmdir "$cat" 2>/dev/null && echo "Removed $cat/" || echo "not empty: $cat"; done
```

Use `rmdir` (not `rm -rf`) — failure means a `git mv` was missed.

## Step 2: Update Shell Discovery Scripts

Replace hardcoded category allowlists with a flat glob:

**Before (two-level):**
```bash
CATEGORIES="foo bar baz"
for category in $CATEGORIES; do
  for item_dir in "$SCRIPT_DIR/$category"/*/; do
    ...
  done
done
```

**After (flat):**
```bash
for item_dir in "$SCRIPT_DIR"/*/; do
  [ -d "$item_dir" ] || continue
  [ -f "${item_dir}ITEM_MARKER" ] || continue  # skip non-item dirs
  ...
done
```

The `[ -f "${item_dir}ITEM_MARKER" ]` guard replaces the implicit filtering that category nesting provided.

**Stale entry cleanup** — also update any loop that checks existence via `$SCRIPT_DIR/$category/$name`:
```bash
# Before
for category in $CATEGORIES; do
  [ -d "$SCRIPT_DIR/$category/$name" ] && found=1
done

# After
[ -d "$SCRIPT_DIR/$name" ]
```

## Step 3: Update JSON Registries

Strip the category prefix from all path fields:

```python
import json, re
with open('registry.json') as f:
    data = json.load(f)
for entry in data['items']:
    entry['source'] = re.sub(r'^\./[^/]+/', './', entry['source'])
with open('registry.json', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
```

`re.sub(r'^\./[^/]+/', './', src)` turns `./rails/foo` → `./foo`. Safe: only strips the first segment.

## Step 4: Update Markdown Links

```bash
sed -i '' -E 's|\(([a-z-]+)/([a-z0-9-]+)/?\)|(./\2/)|g' README.md
```

Also update any link-validation regex in scripts — a two-level pattern like `\([a-z-]+/[a-z0-9-]+/?\)` silently stops matching after migration.

## Step 5: Restore Dependent Symlinks

If the repo is installed via symlinks (e.g., `install.sh`), run it immediately after committing — all existing symlinks point to the old categorized paths and are dangling.

**Rollback**: `git revert HEAD && ./install.sh`

## Pitfalls

- **Collision resolution order matters** — resolve all duplicates before running `git mv`. Git will refuse to move `general/foo` → `foo` if `debugging/foo` was already moved there.
- **Hardcoded CATEGORIES in multiple scripts** — check every script that references the structure (e.g., `check.sh` and `install.sh` may have separate, out-of-sync lists).
- **Link validator regexes** — scripts that validate Markdown links often have the two-level pattern hardcoded. After migration they match nothing and report zero errors, giving false confidence.
- **JSON registry version fields** — if the migrated entry has a different version than the file on disk (e.g., from a parallel untracked edit), `check.sh` will flag a version mismatch. Update the registry version to match the file.
- **Stale symlinks blocking `rmdir`** — `rmdir` may fail on a category dir even after all real files are moved. Dangling symlinks inside won't appear in `git status`. Investigate with `ls -la <dir>/`, `rm` each symlink individually, then retry `rmdir`. Never use `rm -rf` here — if real content is present, you want the explicit failure.
- **Cross-location collisions (vault variant)** — when flattening a vault with both `vault-ops/<name>` and root `<name>`, two copies may exist at different versions. Resolution: (1) compare `version:` in frontmatter — keep higher semver; (2) if no version, compare `git log --follow` modification date — keep more recent; (3) if identical, delete either. `git rm -r` the losing copy before `git mv` to avoid move conflicts.

## Discovery Context

- **Date**: 2026-04-08
- **Repo**: `~/src/skills` — 154 skills across 13 category dirs → flat
- **Collision**: `root-cause-investigation` in both `debugging/` and `general/` — kept `general/` (more complete). `scanned-document-extraction` in `general/` (v1.1.0, tracked) and root (v1.2.0, untracked) — kept root copy.
