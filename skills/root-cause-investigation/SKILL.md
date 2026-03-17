---
name: root-cause-investigation
description: Dual-mode investigation framework combining Five Whys (systemic root cause analysis) and Peeling the Onion (psychological layer exploration) for complete problem diagnosis across technical and human dimensions.
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# Root Cause Investigation

> **Purpose**: Investigate root causes through two complementary modes -- Five Whys for systemic/technical problems and Peeling the Onion for human motivations and psychological drivers.

## Mode 1: Five Whys (Systemic Root Cause)

**Origin**: Toyota Production System (Taiichi Ohno) -> IDEO Method Cards -> Design Thinking

Ask "Why?" iteratively until reaching an actionable root cause. Five is a heuristic -- stop when you reach something actionable. Fewer than 5 often stays at symptom level. More than 5 may be too abstract or circular.

### Template

```markdown
## 5 Whys Analysis: [Problem]

**Problem Statement**: [Clear description of what went wrong]

| Why # | Question | Answer |
|-------|----------|--------|
| 1 | Why did [problem] happen? | [Symptom/immediate cause] |
| 2 | Why did [answer 1] happen? | [Proximate cause] |
| 3 | Why did [answer 2] happen? | [Contributing factor] |
| 4 | Why did [answer 3] happen? | [Systemic issue] |
| 5 | Why did [answer 4] happen? | **[ROOT CAUSE]** |

**Root Cause**: [Summary]
**Corrective Action**: [Prevents recurrence]
**Wrong Fix** (treats symptom): [What NOT to do]
```

### Domain Examples

- **Software**: Page slow -> Query 3s -> Full table scan -> Missing index -> **Migration failed silently, no CI check** -> Add migration success check to CI
- **Product**: Users churned -> Feature hard to find -> Buried in settings -> **PM assumed "advanced" without research** -> Require user research for UX decisions
- **Personal**: Didn't finish report -> Morning consumed by meetings -> Didn't decline optional meetings -> **FOMO driving calendar choices** -> Establish meeting attendance criteria

### Variations

- **5 Whys + 1 How**: After root cause, add "How do we prevent this?"
- **Appreciative 5 Whys**: For successes -- "Why did this work so well?" Identifies what to replicate.
- **Branching 5 Whys**: When multiple answers exist, explore each branch separately.

### Common Mistakes

1. **Stopping Too Early**: "We don't have budget" is rarely root cause -- keep going
2. **Blaming People**: Ask "Why did the system allow that mistake?" not "Who made the mistake?"
3. **Accepting Vague Answers**: "Communication breakdown" is not specific enough

---

## Mode 2: Peeling the Onion (Psychological Layers)

**Origin**: Paul Adams, developed at Google Research for field interview training

Systematically explore human motivations by repeatedly asking **"I understand, but why is that?"** to strip away surface answers and reach core emotional or values-based truth. The phrase validates (prevents defensiveness) then pushes deeper.

### Layer Model

| Layer | Type | Characteristics |
|-------|------|-----------------|
| 1 | Surface | Obvious, rational, socially acceptable |
| 2 | Rationalization | Logical justification |
| 3 | Belief | Underlying assumption or worldview |
| 4 | Emotion | Feeling driving the belief |
| **Core** | Value/Need | Fundamental human motivation (safety, belonging, esteem, autonomy). You've arrived when answers become circular or values-based. |

### Template

```markdown
## Peeling the Onion Analysis: [Subject/Decision]

**Initial Question**: [What behavior/preference are we exploring?]

| Layer | Response |
|-------|----------|
| 1 (Surface) | [Surface answer] |
| 2 (Rationalization) | [Logical justification] |
| 3 (Belief) | [Underlying belief] |
| 4 (Emotion) | [Emotional driver] |
| **Core** | **[Fundamental motivation]** |

**Insight**: [What does the core reveal?]
**Implications**: [How should this change our approach?]
```

### Application Examples

| Scenario | Surface | Core | Insight |
|----------|---------|------|---------|
| Product | "I want a faster app" | "I need to feel in control of my time" | Design for perceived control, not just speed |
| Personal | "I want a promotion" | "I need to prove I'm capable" | Address self-doubt; promotion may not resolve it |
| Conflict | "You didn't respond to my email" | "I'm worried about my position on this team" | Address job security, not email response time |

---

## Combining Both Modes

Use Five Whys to diagnose the systemic problem, then Peeling the Onion to understand the human factors that allowed or created it.

**Example** -- Bug shipped to production:
- **Five Whys**: No test coverage -> No testing requirement -> **No CI/CD enforcement** (systemic fix)
- **Peeling the Onion**: Developer skipped tests -> Time pressure -> Fear of missing deadline -> **Need for approval from manager** (human insight: address performance anxiety)
