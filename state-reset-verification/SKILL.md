---
name: state-reset-verification
description: "Safe methodology for verifying deduplication works independently of state files through backup-reset-test-restore workflow. Trigger keywords: state reset, verify deduplication, state file testing, filesystem deduplication, state independence, reset verification."
metadata:
  version: "1.0.1"
---

# State Reset Verification for Deduplication Systems

Safely verify that deduplication mechanisms work independently of state files without risking duplicate content creation.

## Core Principles

1. **Backup Before Destruction** — State files contain optimization data (synced ranges, timestamps, cursors) that took significant API calls to build.
2. **Filesystem as Source of Truth** — If deduplication is filesystem-based (scanning existing documents rather than checking state), resetting state should NOT cause duplicates.
3. **Verification Through Counting** — Document counts before/after are the definitive test. Logs can mislead; unchanged counts prove no duplicates.
4. **Preserve Optimizations When Possible** — After verification, restore original state to keep optimization data unless reset is intentional.

## Workflow

### Step 1: Backup Current State

```bash
cp /path/to/state.json /path/to/state.json.backup
ls -lh /path/to/state.json.backup  # Verify backup exists
```

### Step 2: Count Existing Documents

```bash
BEFORE=$(find "/path/to/documents" -name "*.md" -type f | wc -l)
echo "Before reset: $BEFORE documents"
```

### Step 3: Reset State to Minimal Values

Clear tracking arrays, null out timestamps, reset progress flags:
```json
{"last_import_timestamp": null, "synced_ranges": [], "backfill_in_progress": false}
```

### Step 4: Run Import/Sync Operation

- **Dry-run** (safest): Zero risk, reports what would be imported vs skipped
- **Real import**: Higher confidence, requires count verification

### Step 5: Verify No Duplicates Created

```bash
AFTER=$(find "/path/to/documents" -name "*.md" -type f | wc -l)
echo "Before: $BEFORE, After: $AFTER"
```

- `count_after == count_before` → Deduplication works independently of state
- `count_after > count_before` → Check if increases are genuinely new documents or duplicates

### Step 6: Restore or Keep Reset State

**Restore** when: Verification successful AND state contains valuable optimization data.
**Keep reset** when: Intentionally starting fresh OR original state was corrupted.

## Key Rules

- Never modify state files without a recoverable backup
- Record document counts before AND after — don't trust import logs alone
- Use dry-run mode when available before real import
- Keep backup until verification completes — don't delete early
- Verify whether deduplication is state-based or filesystem-based before assuming safety
