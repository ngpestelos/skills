---
name: hermes-profile-continuity
description: "Add cross-session state to a Hermes profile so it stops re-doing work or re-flagging the same issues every restart. For monitoring, observation, or stateful agent roles where a fresh wake-up means losing context the model needs to compare across time. Trigger keywords: hermes profile memory, cross-session state, re-flagging gaps, persistent state, profile continuity, monitoring state, OODA state, profile state file."
metadata:
  category: hermes
  version: "1.1.0"
---

# Adding Cross-Session State to a Hermes Profile

Hermes profiles wake fresh each session — SOUL.md is the only context that persists. Profiles whose role is to monitor or compare across time (life-areas monitor, anomaly detector, recurring-task watcher) need a state file to stop re-flagging the same issues every restart.

## When to use

A profile keeps re-raising the same observation across sessions, re-summarizing data it already covered, or failing to notice escalation (a gap that was 3 days last week is 7 days now, but the model only sees "7" with no comparison).

## Anti-patterns

- **Don't put monitoring state in `MEMORY.md` / `USER.md`.** Hermes manages those (char limits, auto-flush via `flush_min_turns` / `nudge_interval`). Profile-specific state competes with general ops state and gets evicted unpredictably.
- **Don't encode pruning in SOUL.md.** "Drop entries older than 30 days" as a soft instruction relies on the model self-disciplining — crashes mid-edit, format drift, context pressure all defeat it. Bounded enforcement requires a deterministic external script.
- **Don't pre-design archive + rollup + format-spec.** Ship deletion-based simplicity first. The vault has all the source data; the state file is just short-term continuity. Add archive when the simple version actually fails.
- **Don't touch the Continuity section.** It's byte-identical across all profiles. Diverging one establishes a precedent without aligning others. Put the new protocol in the role-specific section instead (e.g., inside "How You Work").

## The pattern

### 1. State file in the vault

`~/src/PARA/1 Areas/Hermes/<ProfileName>.md`. Format:

```markdown
<!--
<PROFILE> STATE FILE
Each entry is `## YYYYMMDD` H2 header followed by freeform bullets. Newest first.
Pruning: <path-to-prune-script> drops entries >30 days old. Cron, not the profile.
-->

# <Profile> State

## YYYYMMDD
- entry content
```

YYYYMMDD with no dashes — matches vault filename convention.

### 2. Deterministic prune script

`~/src/PARA/scripts/prune-<profile>-state.sh`. Requirements:
- Drops `## YYYYMMDD` entries older than N days (default 30)
- Idempotent (second run on already-pruned file is a no-op)
- Atomic (writes via tempfile + rename — a crash leaves the original intact)
- BSD/GNU `date` portable
- Optional `-n` dry-run flag

Reference: `~/src/PARA/scripts/prune-selma-state.sh`.

### 3. SOUL.md changes

Add an "Operational Protocol — Cross-Session State" subsection inside the existing role-specific section. Three rules:

- **Read at session start:** open the state file, scan top 5-10 entries, note open flags.
- **Compare before raising:** if the same flag (keyed on **stream**, not just area — see below) was raised within N days, mark **STILL OPEN since [original YYYYMMDD]** in output, not NEW. If previously-flagged data now has fresh entries past the flag date, mark **RESOLVED on [YYYYMMDD]**.
- **Write at end of run:** prepend a new `## YYYYMMDD` entry. One per run per day; if invoked twice on the same date, update the existing entry rather than adding another.

Close with: "Pruning is not your job. A scheduled script handles it. Do not attempt to prune from inside your protocol."

If the profile monitors an area with multiple sub-cadences (e.g., daily + weekly + ad-hoc), name the streams (`<Area>-daily`, `<Area>-weekly`, `<Area>-adhoc`) and key the STILL OPEN comparison on stream, not area. Different streams produce different signals.

### 4. Schedule the prune

Register as a Hermes cron job (preferred — visible in `~/.hermes/profiles/<name>/cron/`) or a launchd plist. Daily, ideally aligned with `session_reset.at_hour` from `config.yaml`.

## Verification

1. Seeded prune test: file with old + recent dates → older dropped, recent kept; second run is a no-op.
2. Trigger the profile twice in a day — confirm the second invocation marks flags as STILL OPEN, not NEW.

## Reference implementation

Selma (Life Areas Monitor), shipped 2026-04-26: `profiles/selma/SOUL.md` (Operational Protocol inside the OODA section), `~/src/PARA/1 Areas/Hermes/Selma.md` (state file), `~/src/PARA/scripts/prune-selma-state.sh` (prune script).
