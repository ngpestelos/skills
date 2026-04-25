---
name: optimization-eval-scripts
description: Reusable scripts at repo root for gating skill optimizations
type: reference
originSessionId: 52a48115-a243-4f1c-adfe-67135741a789
---
Two scripts at `/Users/ngpestelos/src/skills/` validate skill edits before commit:

- `check-optimization.sh <skill-name> [baseline-ref]` — Tier 0 mechanical check. Verifies frontmatter `name` unchanged, no semantic keyword loss in description, all fenced code blocks preserved verbatim, inline command/path spans preserved, version bumped in SKILL.md and marketplace.json. Supports `--files <old> <new>` for synthetic fixture testing.
- `eval-optimization.sh <skill-name> [baseline-ref]` — Tier 1 LLM-as-judge. Calls `claude -p --model sonnet --json-schema` with adversarial framing. Returns JSON `{verdict, losses, trigger_concerns, confirmations}`. Cross-model: Sonnet judges Opus's optimizations.

Combined gating logic (used in Phase B sweep, 2026-04-25):

| `check.sh` | Tier 0 | Tier 1 | Action |
|---|---|---|---|
| FAIL | * | * | Revert (syntax broken) |
| PASS | PASS | PASS | Auto-commit |
| PASS | PASS | FAIL | Human review (judge may flag legitimate removals) |
| PASS | FAIL | PASS | Human review (Tier 0 noise) |
| PASS | FAIL | FAIL | Revert (cross-validated regression) |

Cost: ~$0.13/judge call on Sonnet. ~$20 across 158 skills.

Plan/triage docs at `~/.claude/plans/actually-before-we-cut-purring-liskov.md` and `~/.claude/plans/skills-optimizer-triage.md`.
