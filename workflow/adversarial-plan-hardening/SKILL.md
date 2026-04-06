---
name: adversarial-plan-hardening
description: Iterative red-team loop for implementation plans. Run adversarial passes, resolve BLOCKERs with version bumps, fold WARNINGs in-place, stop at 0 BLOCKERs, then prepare handoff brief. Trigger keywords: red-team loop, multiple passes, harden plan, plan hardening, iterate red-team, adversarial refinement, clean pass, handoff brief.
version: 1.0.0
---

# Adversarial Plan Hardening

Iterate red-team passes on an implementation plan until it reaches a clean pass (0 BLOCKERs), then prepare a handoff brief for the execution agent.

## When to Use

- Before executing any multi-phase implementation plan
- After the first red-team pass returns BLOCKERs
- When handing off a plan to a different agent (Replit, CI, human)

## The Loop

```
Plan v{N} → Red-team Pass → Findings
  ├─ BLOCKERs found → Create v{N+1} resolving all findings → repeat
  ├─ WARNINGs only → Fold in-place (no version bump) → DONE
  └─ Clean pass → DONE
```

### Step 1: Run Red-Team Pass

Invoke the `red-team-plan` skill on the current plan version. Each pass after the first must instruct the agent: "Do NOT re-report issues already resolved in previous passes."

### Step 2: Triage Findings

- **Any BLOCKER** → create a new plan version (v5→v6) resolving ALL findings (BLOCKERs + WARNINGs). Append a "Pass N" section to the Red-Team History with resolved findings.
- **WARNINGs only, no BLOCKERs** → fold fixes into the current version in-place. No version bump. Append pass to Red-Team History.
- **Clean pass (0 findings)** → done. Proceed to Step 3.

### Step 3: Prepare Handoff Brief

When the plan is clean, produce a deployment-ready document for the execution agent:

1. **Agent-specific preamble** — rules the execution agent must follow (e.g., "never run db:push without asking," "one phase at a time")
2. **Relative file paths** — adjust paths to the execution agent's working directory
3. **STOP gates** — explicit "stop and report" instructions between phases
4. **Dangerous operations flagged** — mark every irreversible action (schema changes, production writes)
5. **Strip red-team history** — the execution agent doesn't need resolved findings
6. **Condense** — remove annotations that only matter for plan review, not execution

## Rules

- Never skip a BLOCKER. Every BLOCKER must be resolved before execution.
- Version bump on BLOCKERs, fold in-place on WARNINGs-only. Don't create a new version for cosmetic fixes.
- Each pass must verify against the actual codebase (Glob, Grep), not just review the plan text.
- Rotate models across passes when possible — different models catch different issues.
- Stop iterating when a pass returns 0 BLOCKERs. Diminishing returns after 2 consecutive clean-ish passes.
