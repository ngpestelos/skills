---
name: optimizer-eval-gating
description: Skill optimization passes must run through eval gating, not blind sweeps
type: feedback
originSessionId: 52a48115-a243-4f1c-adfe-67135741a789
---
When running a five-step-optimizer pass on multiple skills, gate each edit through Tier 0 (mechanical preservation) + Tier 1 (cross-model LLM judge). Pilot a small mixed-risk sample before scaling.

**Why:** User explicitly chose this approach over a blind sweep on 2026-04-25 ("I don't want to optimize and end up with degraded performance"). Initiative ran 158 skills through eval gating; gating caught 6 cross-validated regressions and surfaced ~16 issues for human-in-the-loop fixes that would have shipped silently otherwise. Optimizer agents have repeatable biases (collapsing similar code blocks, dropping numbered principles whose content isn't fully covered elsewhere, picking wrong description when frontmatter has duplicates) that the eval reliably caught.

**How to apply:** Before optimizing >3 skills in one pass:
1. Build/reuse `check-optimization.sh` and `eval-optimization.sh` (see reference_optimization_eval_scripts.md).
2. Run a 10-15 skill pilot covering risk tiers; validate the eval catches injected canary regressions before scaling.
3. For full sweeps, use batches of ~8 with one commit per batch (granular reverts possible).
4. Stratify out workflow-critical skills (Tier H) for hand-review; don't auto-sweep them.
5. Apply combined gating logic — never auto-revert on Tier 1 alone (judge has known false positives on legitimate AGENTS.md-compliant cleanups like `allowed-tools` removal).
