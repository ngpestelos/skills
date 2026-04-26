---
name: hermes-profile-review
description: "Structured review workflow for an existing Hermes profile: discovery, tier findings by severity, surface to user, execute approved subset. Use when asked to review/audit/check a Hermes profile (SOUL.md + runtime + cron + skills referenced). Distinct from hermes-profile-creation (new profile) and hermes-profile-continuity (adding state). Trigger keywords: review profile, audit profile, review SOUL.md, check profile, hermes profile review, profile drift, review <name>, audit <name>."
metadata:
  category: hermes
  version: "1.1.0"
---

# Reviewing a Hermes Profile

Walk through a profile's SOUL.md and runtime, surface drift and design questions tiered by severity, let the user pick what to fix, then execute.

## Workflow

### 1. Discovery

Read in parallel. For uncertain scope, delegate to a single Explore agent so synthesis stays in your context window.

- `~/src/hermes-config/profiles/<name>/SOUL.md` (full)
- `~/src/hermes-config/profiles/<name>/config.yaml` if present
- `~/.hermes/profiles/<name>/` runtime — `config.yaml`, `cron/jobs.json`, `memories/MEMORY.md`, `memories/USER.md`, recent `sessions/`
- Any skill referenced in SOUL.md — verify it exists (`find ~/.claude/skills ~/src/skills -name <skill> -type d`)

### 2. Scan for drift symptoms

- **Stale facts** — hardcoded ages, "current year" refs, references to past schools / homes / jobs that derived from a snapshot date
- **Unicode artifacts** — `���` (mangled em-dashes), zero-width chars, BOM in non-BOM files. Often invisible in rendering but break exact-match Edits
- **Dead refs** — paths / files / skills referenced but not present
- **TZ traps** — `%Z` token in `date` format strings; on this system `Asia/Manila` mislabels as "PST" but the offset is correct
- **Embedded scripts** — shell snippets pasted into SOUL.md that have rotted vs. their canonical version in PARA scripts
- **Threshold mismatches** — numbers in SOUL.md disagreeing with numbers in linked protocol docs (e.g., gap thresholds, retention windows)
- **Continuity-section divergence** — should be byte-identical across all profiles. Diverging one without the others is a smell

### 3. Tier findings

- **Worth fixing** — concrete defects, low cost, no design call. Just ship.
- **Surface as questions** — design choices the user should weigh in on (e.g., "add cross-session state?", "bump memory caps?"). Don't decide unilaterally.
- **Not worth fixing** — flagged for transparency. Cosmetic, cross-profile-spanning, or borderline.

### 4. Present and decide

Show the tiered list. Don't bundle into a single all-or-nothing plan — keep tiers visible so the user picks subsets. If items are independent, ask numbered choices (e.g., "1. Paraphrase 2. Defer 3. Proceed 4. Apply broadly") so a one-line answer covers them all.

### 5. Execute approved items

- Edit SOUL.md (preserve indentation; watch for unicode artifacts when matching old strings)
- Adding state files / scripts? Use `hermes-profile-continuity` skill
- Registering cron jobs: `hermes -p <name> cron create --name <n> --deliver <target> "<schedule>" "<prompt>"` — flags **before** positionals, otherwise argparse rejects the prompt body. Available flags are `--name`, `--deliver`, `--repeat`, `--skill`, `--script` (no `--terminal` or `--mode`).

### 6. Restart and ship

- `hermes -p <name> gateway restart`
- Commit + push (commit-without-asking is fine for routine forward-progress in `hermes-config` / `~/src/skills` / `~/src/PARA`)

## Pitfalls

- **Don't over-engineer.** A review is an audit, not a redesign. If you find six things, fix the three that matter and surface the others.
- **Don't skip discovery.** Drift symptoms only show up when you read carefully. Skipping to "what should we add?" misses the easiest wins.
- **Don't touch the Continuity section** unless cross-profile-aligning. Role-specific changes go in role-specific sections.
