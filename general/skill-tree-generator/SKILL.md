---
name: skill-tree-generator
description: "Generates prerequisite dependency trees for efficiently learning or re-learning a concept. Maps trunk (fundamentals) → branches (core skills) → leaves (applications) with learning sequence and ZPD calibration. Trigger keywords: skill tree, learning path, prerequisites, what do I need to learn first, how to learn, study plan, dependency map, learning order, re-learn, brush up on."
---

# Skill Tree Generator

Given a target concept or skill, generate a prerequisite dependency tree enabling efficient learning or re-learning.

## Theoretical Foundation

| Theory | Applied Principle |
|--------|------------------|
| **Musk / Ausubel** | Trunk before leaves — fundamentals anchor details |
| **Piaget** | Calibrated disequilibrium — not too easy, not too hard |
| **Bruner** | Spiral: enactive → iconic → symbolic (increasing depth) |
| **Vygotsky** | Teach within ZPD — gap between can-do and can-do-with-help |

**Unified prediction**: Learning fails when new material cannot connect to existing cognitive structure. The skill tree makes that structure visible.

## 6 Steps

### Step 1: Define the Target
"What concept or skill do you want to learn?" Clarify: concept, skill, or domain tree.

### Step 2: Assess Current Level
Use Dreyfus shortcut:
- **Novice**: No exposure → start from trunk
- **Beginner/Competent**: Some exposure → identify branch gaps
- **Proficient/Expert**: Re-learning → focus on specific branches/leaves

### Step 3: Decompose into Tree

```
TARGET CONCEPT
│
├── TRUNK (Fundamentals — must learn first)
│   ├── Prerequisite 1 — [why foundational]
│   └── Prerequisite 2 — [why foundational]
│
├── BRANCH A: [Core Sub-Skill]
│   ├── Depends on: [trunk items]
│   ├── Leaf A1: [specific application]
│   └── Leaf A2: [specific application]
│
├── BRANCH B: [Core Sub-Skill]
│   └── Depends on: [trunk + optionally Branch A]
│
└── BRANCH C: [Core Sub-Skill] (parallel with A)
```

**Trunk**: If missing, everything above is meaningless. **Branches**: Core capabilities. **Leaves**: Specific applications. **Independent branches**: Can be learned in parallel.

### Step 4: Sequence for Learning

```
Phase 1: TRUNK
  □ Prerequisite 1 — [resource suggestion]
  □ Prerequisite 2 — [resource suggestion]

Phase 2: BRANCHES (parallel where no dependency)
  □ Branch A — depends on trunk
  □ Branch B — depends on trunk + Branch A
  □ Branch C — parallel with A

Phase 3: LEAVES (as needed)
  □ Leaf A1 — after Branch A
```

### Step 5: Calibrate to ZPD
- **Below ZPD** (already knows): Skip or review-only
- **Within ZPD** (can learn with guidance): Productive zone — prioritize
- **Above ZPD** (prerequisites missing): Blocked — trace back

### Step 6: Spiral Passes (Optional, for re-learning)
```
Pass 1 (Enactive): Build something simple using the concept
Pass 2 (Iconic): Draw diagrams, map relationships visually
Pass 3 (Symbolic): Study formal theory, read papers/textbooks
```

## Key Rules

- Always decompose into trunk/branch/leaf layers — no flat prerequisite lists
- Always assess current level before sequencing — avoid teaching what's known
- Mark dependencies explicitly — which items block which others
- Identify parallel branches for efficiency
- Suggest concrete resources where possible
- No aspirational timelines disconnected from available hours
