---
name: cron-auto-sync-hardening
description: Prevent compound silent failures in cron-driven git auto-sync. Inline `git add -A && commit && pull --rebase && push` chains piped to /dev/null fossilize conflict markers when a rebase is left half-finished — subsequent ticks pile new auto-sync commits on top. Trigger keywords: cron auto-sync, git rebase stuck, .git/rebase-merge stale, silent sync failure, compound auto-sync, fossilize conflicts, cron git divergence.
allowed-tools:
  - Bash
  - Edit
  - Read
  - Write
metadata:
  version: "1.1.0"
---

# Cron Auto-Sync Hardening

> **Purpose**: Stop cron-driven git auto-sync from silently piling commits on top of half-finished rebases.

## The Failure Mode

Common inline cron pattern:
```
*/30 * * * * cd ~/repo && git add -A >/dev/null 2>&1 && (git diff --cached --quiet || git commit -m "chore: auto-sync" >/dev/null 2>&1) && git pull --rebase >/dev/null 2>&1 && git push >/dev/null 2>&1
```

When `git pull --rebase` hits a conflict, `.git/rebase-merge/` is left behind. The next cron tick's `git add -A` happily stages everything (including stale state), commits as "auto-sync", and continues. The rebase is never `--continue`'d or `--abort`'d. Each subsequent tick piles another commit. `>/dev/null 2>&1` ensures none of this surfaces until you manually `cd` into the repo and discover it's `N ahead / M behind` with leaked rebase metadata.

## The Fix Shape

Replace the inline chain with a script that pre-flights and logs:

```bash
#!/usr/bin/env bash
# auto-sync-repo.sh <repo-path>
set -uo pipefail
REPO="${1:?usage}"
LOG="${AUTO_SYNC_LOG:-$HOME/.hermes/logs/auto-sync.log}"
mkdir -p "$(dirname "$LOG")"
log() { printf '%s [%s] %s\n' "$(date -u +%FT%TZ)" "$(basename "$REPO")" "$*" >> "$LOG"; }

cd "$REPO" || { log "ERROR cannot cd"; exit 1; }

# Pre-flight 1: refuse if a rebase is mid-flight
[ -d .git/rebase-merge ] || [ -d .git/rebase-apply ] && { log "SKIP rebase in progress"; exit 0; }

# Pre-flight 2: refuse if there are unmerged paths
[ -n "$(git ls-files -u)" ] && { log "SKIP unmerged paths"; exit 0; }

# Then the normal add/commit/pull/push chain, with stderr appended to $LOG (not /dev/null)
```

Cron becomes: `*/30 * * * * /path/to/auto-sync-repo.sh /path/to/repo`

If you find a repo already in the stuck state (`.git/rebase-merge/` present, or back-to-back "auto-sync" commits in `git log --oneline origin/master..HEAD`), recover with: `git rebase --continue` (working tree clean) → `git pull --rebase` → `git push`. Each step is `git reflog`-reversible.

## See Also

- **`git-sync-failure-diagnosis`** — when sync FAILS (network/timeout) vs silently corrupts.
- **`para-vault-auto-sync`** — PARA-specific stash/lock handling.
- **`background-job-observability`** — broader pattern for surfacing silent cron failures.
