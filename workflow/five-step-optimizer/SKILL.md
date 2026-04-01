---
name: five-step-optimizer
description: Apply Elon Musk's Five-Step Algorithm to systematically optimize any process, system, or workflow through questioning, elimination, optimization, acceleration, and automation in strict sequence. Use when discussing process improvement, workflow optimization, system simplification, or eliminating unnecessary complexity.
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# Five-Step Optimizer

Applies Elon Musk's Five-Step Algorithm to optimize processes, systems, and workflows. Key insight: **most people work this backwards** — optimizing and automating things that shouldn't exist.

Execute in strict sequence. Each step depends on completing the previous one.

## Step 1: Make Requirements Less Dumb

**Ask**: "Is this requirement actually necessary? Why does it exist? Who created it? Is it still valid?"

- Question every requirement — especially from smart people (authority makes bad requirements harder to challenge)
- "The requirement is dumb" until proven otherwise
- Output: requirements marked [Validated] or [Questionable] with rationale

## Step 2: Delete

**Ask**: "Can we eliminate this entirely?"

- Remove components/steps rather than optimizing unnecessary elements
- Target removing 10% initially. If you never add anything back, you didn't delete enough
- "The best part is no part. The best process is no process."
- Output: items deleted with impact assessment

## Step 3: Optimize

**Ask**: "How can we improve what remains?"

- Only optimize what survived Steps 1-2. Optimizing something that shouldn't exist is the most common mistake
- Output: improvements to remaining elements

## Step 4: Accelerate

**Ask**: "How can we speed this up?"

- Acceleration amplifies whatever exists — good or bad. Only accelerate after optimization
- Output: speed/throughput improvements

## Step 5: Automate

**Ask**: "What can we automate?"

- Automation comes LAST. Automating a flawed process locks in the flaws
- If someone suggests automating first, redirect to Step 1
- Output: automation candidates from validated, optimized, accelerated process

## Common Step 2 Deletions (Coaching/Framework Skills)

When optimizing skills or methodology documents, these categories are consistently deletable:

- **Decorative quotes** — literary/philosophical attributions that don't change execution
- **Generic advice Claude already knows** — "search before creating," "use evidence not self-perception"
- **Output templates** — Claude generates structured output naturally; templates constrain without adding value
- **Key Rules that restate the steps** — if a rule says the same thing as a step, it's redundant
- **Example lists** — static examples anchor instead of inspire; Claude generates better contextual ones
- **"When to use" sections** — duplicates frontmatter trigger keywords
- **`allowed-tools` constraints** — artificially restricts the skill from using Write/Bash when needed
