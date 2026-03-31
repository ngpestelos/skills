---
name: root-cause-investigation
description: Dual-mode investigation framework combining Five Whys (systemic root cause analysis) and Peeling the Onion (psychological layer exploration) for complete problem diagnosis across technical and human dimensions.
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# Root Cause Investigation

## Mode 1: Five Whys (Systemic Root Cause)

Ask "Why?" iteratively until reaching an actionable root cause. Five is a heuristic -- stop when actionable. Fewer than 5 stays at symptom level; more than 5 risks circularity.

### Template

```markdown
## 5 Whys: [Problem]

| Why # | Question | Answer |
|-------|----------|--------|
| 1 | Why did [problem] happen? | [Immediate cause] |
| 2 | Why did [answer 1] happen? | [Proximate cause] |
| 3 | Why did [answer 2] happen? | [Contributing factor] |
| 4 | Why did [answer 3] happen? | [Systemic issue] |
| 5 | Why did [answer 4] happen? | **[ROOT CAUSE]** |

**Root Cause**: [Summary]
**Corrective Action**: [Prevents recurrence]
**Wrong Fix** (treats symptom): [What NOT to do]
```

### Examples

- **Software**: Page slow -> Query 3s -> Full table scan -> Missing index -> **Migration failed silently, no CI check** -> Add migration success check to CI
- **Product**: Users churned -> Feature hard to find -> Buried in settings -> **PM assumed "advanced" without research** -> Require user research for UX decisions
- **Personal**: Didn't finish report -> Morning consumed by meetings -> Didn't decline optional ones -> **FOMO driving calendar choices** -> Establish attendance criteria

### Variations

- **Appreciative 5 Whys**: For successes -- "Why did this work so well?" Identifies what to replicate.
- **Branching 5 Whys**: When multiple answers exist at a level, explore each branch separately.

### Common Mistakes

1. **Stopping Too Early**: "We don't have budget" is rarely root cause -- keep going
2. **Accepting Vague Answers**: "Communication breakdown" is not specific enough -- demand mechanisms

---

## Mode 2: Peeling the Onion (Psychological Layers)

Systematically explore human motivations by repeatedly asking **"I understand, but why is that?"** to strip away surface answers. The phrase validates (prevents defensiveness) then pushes deeper.

### Layer Model

| Layer | Type | Signal |
|-------|------|--------|
| 1 | Surface | Obvious, socially acceptable |
| 2 | Rationalization | Logical justification |
| 3 | Belief | Underlying assumption or worldview |
| 4 | Emotion | Feeling driving the belief |
| **Core** | Value/Need | Fundamental motivation (safety, belonging, esteem, autonomy). Answers become circular or values-based. |

### Template

```markdown
## Peeling the Onion: [Subject/Decision]

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

### Examples

| Scenario | Surface | Core | Insight |
|----------|---------|------|---------|
| Product | "I want a faster app" | "I need to feel in control of my time" | Design for perceived control, not just speed |
| Personal | "I want a promotion" | "I need to prove I'm capable" | Address self-doubt; promotion may not resolve it |
| Conflict | "You didn't respond to my email" | "I'm worried about my position on this team" | Address job security, not email response time |

---

## Combining Both Modes

Use Five Whys for the systemic problem, then Peeling the Onion for the human factors that allowed it.

**Example** -- Bug shipped to production:
- **Five Whys**: No test coverage -> No testing requirement -> **No CI/CD enforcement** (systemic fix)
- **Peeling the Onion**: Developer skipped tests -> Time pressure -> Fear of missing deadline -> **Need for approval from manager** (address performance anxiety)
