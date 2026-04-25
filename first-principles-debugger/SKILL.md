---
name: first-principles-debugger
description: "Systematic first-principles methodology for debugging complex issues that resist conventional approaches. Auto-activates when: bug persists after multiple fix attempts, 'it worked before' with no obvious change, cross-layer issues spanning Rails/Stimulus/database, or 'impossible' behavior contradicting expectations. Trigger keywords: root cause, first principles, doesn't make sense, should work but doesn't, mysterious bug, works sometimes, inconsistent behavior, what's actually happening."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

### Step 1: Define the Problem Precisely

State observed vs. expected behavior in one jargon-free sentence.

```markdown
**Observed**: [Exact symptoms with specific details]
**Expected**: [What should happen based on requirements/design]
**Environment**: [Rails version, browser, tenant context]
**Reproducibility**: [Always/Sometimes/Rare - with conditions]
```

Bad: "The modal is broken" — Good: "BrandingLogoController destroy returns 422 from modal, but 200 from page refresh"

### Step 2: Deconstruct to Fundamentals

1. **What are the basic components involved?** (controllers, models, views, JS, database)
2. **What are the core constraints?** (HTTP protocol, Rails conventions, Stimulus lifecycle, SQL)
3. **What are the assumed requirements?** (From code, or inherited assumptions?)

### Step 3: Question Assumptions, Then Rebuild

For every assumption, ask: "Is this required by the framework/language, or just convention?" and "How do we know this is true in THIS context?"

**Rebuild using only verified fundamentals — layer by layer until the bug appears**:

1. Verify the lowest layer works (model in console)
2. Add the next layer (controller without auth)
3. Add the next layer (request routing via logs)
4. Add the next layer (JavaScript request formation)

Stop at the layer where behavior diverges from expectation. That's where the bug lives.

### Step 4: Validate

- Is the solution simpler than the original code?
- Does it reveal the actual root cause (not just suppress symptoms)?
- Does it work across all relevant contexts (tenants, users, states)?

## Depth Calibration

- **Too shallow**: "It's a Rails bug" (assumption, not verified)
- **Right depth**: "Rails responds with 422 because validation failed; validation fails because..."
- **Too deep**: "We need to understand Ruby's object model to fix this form"

Stop decomposing when further depth doesn't change the solution. Conventions often encode hard-won lessons — don't bypass them without evidence.

## Output

```markdown
## First-Principles Analysis: [Issue Description]

**Fundamental Elements**: [Core components/constraints involved]

**Assumptions Questioned**: [What was assumed vs. verified]

**Root Cause**: [Actual issue, traced to fundamentals]

**Solution**: [Fix based on fundamental understanding]
```
