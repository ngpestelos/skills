---
name: decision-timing-assessor
description: Framework for determining optimal decision timing vs. information gathering needs. Auto-activates when evaluating when to decide, assessing reversibility, or considering delayed decisions. Trigger keywords: Type I decision, Type II decision, reversibility, when to decide, gather more information, Fabian strategy.
---

# Decision Timing Assessor

Some decisions benefit from speed; others from delay. The skill is knowing which is which.

## Quick Mode

Three questions (2 min): Can this be undone? What happens if I wait a week? What specific info am I waiting for? If reversible + no new info expected → decide now.

## Type I / Type II Classification

| | Type I (Reversible) | Type II (Irreversible) |
|---|---|---|
| **Nature** | Can be undone; low reversal cost | Cannot be undone, or very expensive |
| **Examples** | Feature decisions, tool selection, marketing experiments | Major career moves, large investments, architectural lock-in |
| **Information** | Decide with 70% | Decide with 90%+ |
| **Bias** | Toward action; learn by doing | Toward thoroughness; pre-mortem, regret minimization |
| **Speed** | Hours to days | Weeks to months |

**Hybrid**: Partially reversible (reversible with cost, time, or reputation damage). Treat as Type II during initial decision, factor escape hatch into risk assessment.

## Decision Timing Framework

### Step 1: Classify the Decision

1. **Reversibility**: If wrong, can we undo it? → Type I / Type II
2. **Stakes**: Worst-case outcome? → Manageable / Catastrophic

### Step 2: Assess Information Value

**Wait adds value when**: significant resolvable uncertainty, information actively incoming, high cost of being wrong, no expiring window.

**Wait destroys value when**: analysis paralysis with no new info expected, window closing, delay cost exceeds benefit, perfect information doesn't exist.

### Step 3: Apply Strategy

**Type I → Bias Toward Action**: Set deadline (hours/days), gather readily available info, decide, define success metrics, review and iterate.

**Type II → Thorough Analysis**: Gather comprehensive info, run bias audit + pre-mortem + regret minimization, seek outside counsel, sleep on it, document reasoning.

**Hybrid → Staged Commitment**: Smallest reversible commitment first, clear go/no-go criteria for next stage, preserve exit options as long as possible.

## The Fabian Strategy

Strategic delay when time is on your side. Tactics: "Let me think about it" under pressure, small steps keeping options open, let time erode bad options. Do NOT apply when: genuinely time-limited opportunity, delay has real costs, using delay to avoid discomfort rather than gain advantage.

## Optimization History

- **March 13, 2026**: First pass. Deleted Decision Timing Template, Integration with Other Skills, Common Mistakes, When to Apply, Strategic Wisdom quotes. 350 → 62 lines (82% reduction).
- **March 17, 2026**: Second pass. Deleted Value of Waiting pseudo-formula (bullets do the work), Option Value table (generic life advice), Key Principles (duplicated framework). Moved 2-min assessment to Quick Mode header for short-circuit. Compressed Fabian Strategy to single paragraph. Removed Step 1 items 3-4 (covered by Step 2 bullets). 62 → 42 lines (32% reduction).
