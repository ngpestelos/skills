---
name: adversarial-plan-hardening
description: Iterative adversarial review loop for implementation plans. Run passes, resolve BLOCKERs with version bumps, fold WARNINGs in-place, stop at 0 BLOCKERs, prepare handoff brief. Trigger keywords: red-team loop, multiple passes, harden plan, plan hardening, adversarial refinement, clean pass, handoff brief.
version: 1.1.0
---

# Adversarial Plan Hardening

Iterate adversarial review passes on an implementation plan until it reaches a clean pass (0 BLOCKERs), then prepare a handoff brief for the execution agent.

## The Loop

```
Plan v{N} → Adversarial Pass → Findings
  ├─ BLOCKERs found → Create v{N+1} resolving all findings → repeat
  ├─ WARNINGs only → Fold in-place (no version bump) → DONE
  └─ Clean pass → DONE
```

### Step 1: Run Adversarial Pass

Run an adversarial review of the current plan version. Each pass must verify claims against the actual codebase (Glob, Grep), not just review plan text. After the first pass, instruct the reviewer: "Do NOT re-report issues already resolved in previous passes."

Rotate models across passes when possible — different models catch different issues.

### Step 2: Triage Findings

- **Any BLOCKER** → create a new plan version resolving ALL findings (BLOCKERs + WARNINGs). Append a "Pass N" section to the plan's Red-Team History.
- **WARNINGs only** → fold fixes in-place. No version bump. Append pass to history.
- **Clean pass** → proceed to Step 3.

Never skip a BLOCKER. Every BLOCKER must be resolved before execution.

### Step 3: Prepare Handoff Brief

When the plan is clean, produce a deployment-ready document for the execution agent:

1. **Agent-specific preamble** — rules the execution agent must follow
2. **STOP gates** — explicit "stop and report" between phases
3. **Dangerous operations flagged** — mark every irreversible action
4. **Condense** — adjust file paths to execution context, strip red-team history, remove review-only annotations
