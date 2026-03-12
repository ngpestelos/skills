---
name: five-step-optimizer
description: Apply Elon Musk's Five-Step Algorithm to systematically optimize any process, system, or workflow through questioning, elimination, optimization, acceleration, and automation in strict sequence. Use when discussing process improvement, workflow optimization, system simplification, or eliminating unnecessary complexity.
license: MIT
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Five-Step Optimizer

## Purpose

This skill applies Elon Musk's Five-Step Algorithm to systematically optimize processes, systems, and workflows. The key insight: **most people work this algorithm backwards**, optimizing and automating things that shouldn't exist.

## The Five-Step Algorithm

Execute in strict sequence - each step depends on completing the previous one:

### Step 1: Make Requirements Less Dumb

**Ask**: "Is this requirement actually necessary?"

- Question every requirement's validity before proceeding
- Requirements often come from smart people, making them harder to question
- "The requirement is dumb" until proven otherwise
- Ask: "Why does this exist? Who created it? Is it still valid?"

**Output**: List of requirements marked as [Validated] or [Questionable]

### Step 2: Delete the Part or Process Step

**Ask**: "Can we eliminate this entirely?"

- Remove components/steps rather than optimizing unnecessary elements
- Target: Remove 10% of requirements/parts
- If you never add anything back, you didn't delete enough
- "The best part is no part. The best process is no process."

**Output**: List of items deleted with rationale

### Step 3: Optimize

**Ask**: "How can we improve what remains?"

- Only optimize what survived steps 1-2
- Common mistake: optimizing something that shouldn't exist
- Focus exclusively on validated necessities

**Output**: Optimization improvements to remaining elements

### Step 4: Accelerate

**Ask**: "How can we speed this up?"

- Increase speed/throughput only after optimization
- Acceleration amplifies whatever exists - good or bad
- Accelerating an inefficient process creates faster waste

**Output**: Speed improvements to optimized elements

### Step 5: Automate

**Ask**: "What can we automate?"

- Automation comes LAST
- Automating a flawed process locks in the flaws
- "Don't automate something that shouldn't exist"

**Output**: Automation candidates from validated, optimized, accelerated process

## The Inversion Problem

**Most people work backwards**:

| Common Approach | Correct Approach |
|-----------------|------------------|
| "Let's automate this!" | "Should this exist?" |
| "How do we optimize?" | "Can we delete it?" |
| Accept requirements as given | Question every requirement |
| Speed up what exists | Simplify before speeding up |

## Application Template

```markdown
## Five-Step Analysis: [System/Process Name]

### Step 1: Question Requirements
**Current Requirements:**
1. [Requirement] - [Validated/Questionable] - [Rationale]

### Step 2: Delete
**Items Deleted:**
- [Item] - [Impact of removal]

### Step 3: Optimize
**Remaining Elements to Optimize:**
- [Element] - [Optimization approach]

### Step 4: Accelerate
**Speed Improvements:**
- [Element] - [How to accelerate]

### Step 5: Automate
**Automation Candidates:**
- [Element] - [Automation approach]

### Summary
- Requirements questioned: X
- Items deleted: Y
- Items optimized: Z
- Items accelerated: A
- Items automated: B
```

## Domain Applications

### Software Development
- Question inherited architectural patterns
- Delete dead code and unused features before refactoring
- Optimize remaining code paths
- Accelerate build/deploy pipelines
- Automate validated workflows

### Workflow Design
- Question each approval step's necessity
- Delete unnecessary handoffs
- Optimize remaining checkpoints
- Accelerate information flow
- Automate routine decisions

### Knowledge Work
- Question which meetings are necessary
- Delete low-value recurring tasks
- Optimize remaining work patterns
- Accelerate feedback loops
- Automate information routing

## Key Heuristics

**Deletion Test**: "If you're not occasionally adding things back, you're not deleting enough."

**The 10% Rule**: Target removing 10% of requirements/parts initially.

**Backwards Check**: If someone suggests automating first, redirect to Step 1.

**Validation Signal**: Requirements that survive questioning become stronger.
