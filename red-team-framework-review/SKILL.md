---
name: red-team-framework-review
description: "Systematic adversarial review of strategic frameworks and thesis documents. Challenges assumptions, identifies correlated failure modes, checks demand evidence, and surfaces survivorship bias. Auto-activates when reviewing strategy documents, competitive positioning, or multi-pillar frameworks. Trigger keywords: red-team, stress-test, challenge assumptions, adversarial review, devil's advocate, what's wrong with this."
metadata:
  version: "1.0.1"
---

# Red-Teaming Strategic Frameworks

Systematically challenge claims, assumptions, and internal consistency to surface risks the author's confirmation bias hides.

## Challenge Checklist

For every falsifiable claim in the framework, apply all four lenses:

1. **Shelf life**: Treat "X can't do Y" as temporal. In what timeframe could this break? If it breaks, which pillars fall with it?
2. **Evidence**: Revenue targets, market rates, competitive advantages — each needs external validation (competitor analysis, market rates, saturation data), not just internal logic.
3. **Correlated failure**: Which elements depend on the same external condition? Under one adverse scenario, how many pillars fail simultaneously?
4. **Retrospective fitting**: Were strengths mapped to strategy before or after design? Could the same strengths justify a completely different strategy?

## Methodology

1. **Extract claims**: List every falsifiable assertion (capability limits, revenue targets, timeline assumptions, durability claims)
2. **Test each claim** against the four lenses above
3. **Render verdict**: Strongest element, weakest element, biggest risk, and whether the framework is falsifiable as written

Before presenting, invoke the `reality-checker` agent to verify factual claims.

## Output Structure

1. **What the Framework Gets Right** — strengths first; pure attack pieces lose credibility
2. **Critical Weaknesses** — cite source documents, quantify assumption shelf lives
3. **Summary Verdict** — end with an actionable corrective, not just the problem
4. **Cross-References** — source document -> specific vulnerability

Distinguish unfalsifiable from wrong — some frameworks aren't incorrect, they're untestable.

The most valuable red-team finding isn't "this is wrong" — it's "this is unfalsifiable as written," because unfalsifiable frameworks cannot self-correct.
