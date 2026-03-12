---
name: root-cause-investigation
description: Dual-mode investigation framework combining Five Whys (systemic root cause analysis from Toyota/IDEO) and Peeling the Onion (psychological layer exploration from Google Research) for complete problem diagnosis across technical and human dimensions.
license: MIT
metadata:
  author: ngpestelos
  version: "1.0"
---

# Root Cause Investigation

> **Purpose**: Investigate root causes through two complementary modes -- Five Whys for systemic/technical problems and Peeling the Onion for human motivations and psychological drivers.

## Mode 1: Five Whys (Systemic Root Cause)

**Origin**: Toyota Production System (Taiichi Ohno) -> IDEO Method Cards -> Design Thinking

Ask "Why?" iteratively until reaching an actionable root cause. Targets systemic causes in any domain -- technical, organizational, or personal.

### Process

```
Problem Statement
  -> Why? -> Answer 1 (symptom)
  -> Why? -> Answer 2 (proximate cause)
  -> Why? -> Answer 3 (contributing factor)
  -> Why? -> Answer 4 (systemic issue)
  -> Why? -> Answer 5 (ROOT CAUSE)
  -> Action to prevent recurrence
```

Five is a heuristic -- stop when you reach something actionable. Fewer than 5 often stays at symptom level. More than 5 may be too abstract or circular.

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

**Software**: Page slow -> Query takes 3s -> Full table scan -> Missing index -> **Migration failed silently, no CI check** -> Action: Add migration success check to CI

**Product**: Users churned -> Stopped using feature -> Feature hard to find -> Buried in settings -> **PM assumed "advanced" without research** -> Action: Require user research for UX decisions

**Personal**: Didn't finish report -> Ran out of time -> Morning consumed by meetings -> Didn't decline optional meetings -> **FOMO driving calendar choices** -> Action: Establish meeting attendance criteria

### Variations

- **5 Whys + 1 How**: After root cause, add "How do we prevent this?"
- **Appreciative 5 Whys**: For successes -- "Why did this work so well?" Identifies what to replicate.
- **Branching 5 Whys**: When multiple answers exist, explore each branch separately.

### Common Mistakes

1. **Stopping Too Early**: "We don't have budget" is rarely root cause -- keep going
2. **Blaming People**: Ask "Why did the system allow that mistake?" not "Who made the mistake?" Systems fail people, not the reverse
3. **Accepting Vague Answers**: "Communication breakdown" is not specific enough -- what specifically wasn't communicated?
4. **Single-Path Thinking**: When multiple causes exist, branch and explore each

### Quality Checklist

- [ ] Reached something actionable (not just blame)?
- [ ] Root cause is systemic (not individual error)?
- [ ] Fixing this prevents recurrence (not just treats symptom)?
- [ ] Considered multiple branches where relevant?
- [ ] Corrective action is specific and implementable?

---

## Mode 2: Peeling the Onion (Psychological Layers)

**Origin**: Paul Adams, developed at Google Research for field interview training

Systematically explore human motivations by repeatedly asking "I understand, but why is that?" to strip away surface answers and reach core emotional or values-based truth.

### The Key Phrase

**"I understand, but why is that?"**

- **"I understand"** - validates their answer (prevents defensiveness)
- **"but why is that?"** - pushes for deeper reasoning without dismissal

### Process

Start with surface question about observable behavior, preference, or stated need. After each answer, respond with the key phrase.

### Layer Model

| Layer | Type | Characteristics |
|-------|------|-----------------|
| 1 | Surface | Obvious, rational, socially acceptable |
| 2 | Rationalization | Logical justification |
| 3 | Belief | Underlying assumption or worldview |
| 4 | Emotion | Feeling driving the belief |
| **Core** | Value/Need | Fundamental human motivation |

### Recognizing the Core

You've reached it when:
- Answer becomes emotional or values-based
- Further "why" questions feel circular
- Person says "I don't know, it just is"
- You've hit a fundamental human need (safety, belonging, esteem, autonomy)

### Template

```markdown
## Peeling the Onion Analysis: [Subject/Decision]

**Initial Question**: [What behavior/preference are we exploring?]

| Layer | Question | Response |
|-------|----------|----------|
| 1 | [Initial question] | [Surface answer] |
| 2 | "I understand, but why is that?" | [Rationalization] |
| 3 | "I understand, but why is that?" | [Underlying belief] |
| 4 | "I understand, but why is that?" | [Emotional driver] |
| **Core** | "I understand, but why is that?" | **[Fundamental motivation]** |

**Insight**: [What does the core reveal?]
**Implications**: [How should this change our approach?]
```

### Application Examples

| Scenario | Surface | Core | Insight |
|----------|---------|------|---------|
| Product | "I want a faster app" | "I need to feel in control of my time" | Design for perceived control, not just speed |
| Personal | "I want a promotion" | "I need to prove I'm capable" | Address self-doubt; promotion may not resolve it |
| Conflict | "You didn't respond to my email" | "I'm worried about my position on this team" | Address job security, not email response time |

### Common Mistakes

1. **Moving Too Fast**: Rapid-fire "why" feels like interrogation. Pause, validate, build trust between layers
2. **Accepting First "Deep" Answer**: Don't stop at first emotional-sounding response -- continue to fundamental needs
3. **Interrogative Tone**: "But why? But why?" attacks. "I understand, but why is that?" invites
4. **Projecting Your Motivations**: Let their answers guide you to their unique core

---

## Combining Both Modes

| Mode | What It Investigates | Best For |
|------|---------------------|----------|
| Five Whys | Systemic causes (technical, process, organizational) | Post-mortems, debugging, process failures |
| Peeling the Onion | Human motivations (psychological, emotional, values) | User research, conflict resolution, self-reflection |

**Combined workflow**: Use Five Whys to diagnose the systemic problem, then Peeling the Onion to understand the human factors that allowed or created it.

**Example**: Bug shipped to production
- **Five Whys**: Why? -> No test coverage -> No testing requirement -> **No CI/CD enforcement** (systemic fix)
- **Peeling the Onion**: Why did the developer skip tests? -> Time pressure -> Fear of missing deadline -> **Need for approval from manager** (human insight: address performance anxiety)
