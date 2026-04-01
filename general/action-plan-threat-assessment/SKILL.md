---
name: action-plan-threat-assessment
description: "Stress-tests execution plans by identifying weaknesses, threats, and dangerous combinations per action item. Creates interaction matrices and orders defensive actions by urgency. Trigger keywords: weaknesses, threats, SWOT, stress-test execution, what could go wrong, action plan risks, execution risks, defensive actions."
---

# Action Plan Threat Assessment

Stress-test execution plans for operational risks. Produces weakness-threat interaction matrices and urgency-ordered defensive actions.

## Principles

1. **Test execution, not thesis** — Red-teaming tests whether the strategy is correct. This tests whether the *specific action items* will work.
2. **Interaction effects are more dangerous than individual risks** — A single W or T is manageable. W+T combinations are often catastrophic.

## Steps

### Step 1: Inventory Action Items
List every action item. Each gets assessed independently.

### Step 2: Assess Weaknesses (W) and Threats (T)

**Internal Weaknesses** (controllable — mitigate through redesign):

| Question | Type |
|---|---|
| Exceeds available bandwidth given energy cap? | Bandwidth fragmentation |
| Cannibalizes a higher-priority action? | Cannibalization |
| Requires behavior the personality profile resists? | Personality misalignment |
| Assumes capability that hasn't been demonstrated? | Untested assumption |
| Could become preparation avoiding market contact? | Preparation-as-protection recursion |
| Claims outcome X without conversion tracking? | Signal-to-income gap |

**External Threats** (environmental — mitigate through contingency):

| Question | Type |
|---|---|
| Target market being flooded by AI or competitors? | Market saturation |
| Others adopting same positioning simultaneously? | Positioning arms race |
| Expected traction timeline matches reality? | Timeline mismatch |
| Financial pressure forces premature abandonment? | Income pressure |
| Geographic location creates rate/perception ceiling? | Geographic rate ceiling |
| Gatekeepers block this channel? | Gatekeeper risk |

For each: specific risk, affected action items, concrete mitigation.

### Step 3: Build Interaction Matrix
Identify the 5-8 most dangerous W+T combinations:

| Combination | Risk | Why Dangerous |
|---|---|---|
| W[x] + T[y] | [Short name] | [Why worse than either alone] |

### Step 4: Order Defensive Actions
First defensive action must be executable today — if it's "research which platform," the assessment has become preparation-as-protection. Order remainder by urgency.

**Always include one meta-threat that flags the assessment itself as potential avoidance.**

## Optimization History

- **March 13, 2026**: Five-step optimizer pass 1. 264 → 88 lines (67%).
- **April 1, 2026**: Five-step optimizer pass 2. Deleted "consult existing analyses" step (generic norm), Core Principles #2 and #4 (restated by structure), week-specific urgency tiers (arbitrary), 4/6 key rules (implicit), discovery footnote. Merged W and T into one step. 88 → 42 lines (52%).
