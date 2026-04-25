---
name: eval-gated-bulk-edits
description: "Methodology for safely running bulk LLM-driven content edits across many files using mechanical + LLM-judge gating, canary regression injection, and pilot-then-scale phasing. Trigger keywords: bulk optimization, bulk edit, eval gating, batch refactor, automated content edits, optimizer regression, pilot then scale, canary regression, cross-model judge, combined gating."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
metadata:
  version: "1.1.0"
---

# Eval-Gated Bulk Edits

Use when applying LLM-driven edits to >10 files where mistakes are non-obvious. Skip for small batches (<10), pure mechanical transforms (formatters, linters), or changes verifiable with tests.

## The four ingredients

### 1. Pilot-then-scale phasing

Optimize a small mixed-risk sample (8-15 files) first. Run the full eval against the pilot output. Calibrate the optimizer prompt and the eval based on what surfaces. Only then sweep the rest in batches.

The pilot's job is to validate the eval, not the optimizer.

### 2. Two-tier eval

- **Tier 0 — mechanical preservation**: a script that diffs old vs new and asserts invariants (every code block preserved verbatim, no semantic keyword loss, numeric thresholds present, version bumped). Cheap, 100% coverage. Known false positives.
- **Tier 1 — LLM-as-judge**: prompt a fresh model with old + new + adversarial framing ("list specifically what was lost; do not say 'looks good'"). Use `--json-schema` for structured output.

### 3. Cross-model judge

Optimizer on Opus → judge with Sonnet (or reverse). Same-model judging compounds sycophancy. Different model + adversarial prompt breaks the loop.

### 4. Canary regression injection

Validate the eval, not just the optimizer. Inject 3 deliberate regressions (drop a keyword, delete a code block, paraphrase a verbatim command) into separate copies. If both eval tiers don't catch them, the eval is broken — fix it before trusting it.

## Combined gating decision

| `check.sh` | Tier 0 | Tier 1 | Action |
|---|---|---|---|
| FAIL | * | * | Revert (syntax broken) |
| PASS | PASS | PASS | Auto-commit |
| PASS | PASS | FAIL | Human review (judge false-positives on legitimate cleanups) |
| PASS | FAIL | PASS | Human review (Tier 0 noise) |
| PASS | FAIL | FAIL | Revert (cross-validated regression) |

Never auto-revert on Tier 1 alone. Cross-validation is what makes the gate trustworthy.

## Workflow per batch

1. `BASELINE_REF=$(git rev-parse HEAD)`
2. Spawn one optimizer subagent with the batch's file list and explicit "NEVER cut" rules.
3. Run mechanical, Tier 0, Tier 1 (parallel).
4. Apply combined gating: revert failures, manually fix human-review cases.
5. Commit batch + push (granular reverts possible later).
6. Sanity-check by hand every 5 batches.

## Costs

LLM judge ~$0.13/call on Sonnet with project CLAUDE.md loaded. Budget ~$0.13 × file count + pilot overhead. For 150 files, ~$20.

If cost matters: `--bare` mode with `ANTHROPIC_API_KEY` halves cost; or fall back to Haiku after pilot validates the canaries are still caught.
