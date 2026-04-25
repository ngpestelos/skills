---
name: root-cause-investigation
description: Dual-mode investigation framework combining Five Whys (systemic root cause) and Peeling the Onion (psychological layers) for complete problem diagnosis across technical and human dimensions.
allowed-tools: Read, Grep, Glob
metadata:
  version: "2.0.1"
---

# Root Cause Investigation

| Mode | Investigates | Best For |
|------|-------------|----------|
| Five Whys | Systemic causes (technical, process) | Post-mortems, debugging, process failures |
| Peeling the Onion | Human motivations (psychological) | User research, conflict resolution, self-reflection |

**Combined**: Five Whys diagnoses systemic problem → Peeling the Onion reveals human factors that allowed/created it.

## Mode 1: Five Whys

Ask "Why?" iteratively until reaching an actionable root cause. Five is a heuristic — stop when actionable. Fewer than 5 often stays at symptom level.

```markdown
## 5 Whys Analysis: [Problem]

**Problem Statement**: [What went wrong]

| Why # | Question | Answer |
|-------|----------|--------|
| 1 | Why did [problem] happen? | [Symptom] |
| 2 | Why did [answer 1] happen? | [Proximate cause] |
| 3 | Why did [answer 2] happen? | [Contributing factor] |
| 4 | Why did [answer 3] happen? | [Systemic issue] |
| 5 | Why did [answer 4] happen? | **[ROOT CAUSE]** |

**Corrective Action**: [Prevents recurrence]
**Wrong Fix** (treats symptom): [What NOT to do]
```

Example: Page slow → full table scan → missing index → migration failed silently → **no migration check in CI** → Add migration check.

## Mode 2: Peeling the Onion

Ask **"I understand, but why is that?"** repeatedly to reach core emotional or values-based truth.

| Layer | Type | Characteristics |
|-------|------|-----------------|
| 1 | Surface | Obvious, rational, socially acceptable |
| 2 | Rationalization | Logical justification |
| 3 | Belief | Underlying assumption or worldview |
| 4 | Emotion | Feeling driving the belief |
| **Core** | Value/Need | Fundamental human motivation |

```markdown
## Peeling the Onion: [Subject/Decision]

| Layer | Response |
|-------|----------|
| 1 (Surface) | [Surface answer] |
| 2 (Rationalization) | [Logical justification] |
| 3 (Belief) | [Underlying assumption] |
| 4 (Emotion) | [Emotional driver] |
| **Core** | **[Fundamental motivation]** |

**Insight**: [What does the core reveal?]
**Implications**: [How should this change approach?]
```

## Rules

- Ask "Why did the system allow that mistake?" not "Who made the mistake?"
- "Communication breakdown" is never specific enough — what exactly wasn't communicated?
- Don't stop too early — "We don't have budget" is rarely root cause
- Peeling the Onion: pause and validate between layers — rapid-fire "why" feels like interrogation
- Label inferred motivations as `[Inference]` per Reality Filter
