---
name: First-Principles Debugger
description: "Systematic first-principles methodology for debugging complex issues that resist conventional approaches. Auto-activates when: bug persists after multiple fix attempts, 'it worked before' with no obvious change, cross-layer issues spanning Rails/Stimulus/database, or 'impossible' behavior contradicting expectations. Trigger keywords: root cause, first principles, doesn't make sense, should work but doesn't, mysterious bug, works sometimes, inconsistent behavior, what's actually happening."
allowed-tools: Read, Grep, Glob, Bash
---

# First-Principles Debugger

## When to Use

**Use this**: Bug persists after multiple fix attempts, "it worked before" with unknown change, cross-layer bugs (Rails + Stimulus + DB), behavior that contradicts expectations.

**Don't use this**: Clear error with specific line number, documented framework issue, simple typo, time-sensitive bug with obvious workaround. Use conventional debugging instead.

## Method

### Step 1: Define the Problem Precisely

State observed vs. expected behavior in one jargon-free sentence.

```markdown
**Observed**: [Exact symptoms with specific details]
**Expected**: [What should happen based on requirements/design]
**Environment**: [Rails version, browser, tenant context]
**Reproducibility**: [Always/Sometimes/Rare - with conditions]
**Error Messages**: [Exact text, not paraphrased]
```

- Bad: "The modal is broken"
- Good: "BrandingLogoController destroy returns 422 from modal, but 200 from page refresh"

### Step 2: Deconstruct to Fundamentals

Ask systematically:
1. **What are the basic components involved?** (controllers, models, views, JS, database)
2. **What are the core constraints?** (HTTP protocol, Rails conventions, Stimulus lifecycle, SQL behavior)
3. **What are the assumed requirements?** (Which come from code vs. inherited assumptions?)
4. **What are the fundamental truths?** (Framework behaviors, language guarantees, protocol requirements)

### Step 3: Question Assumptions, Then Rebuild

**Distinguish fundamental truths from conventional wisdom**:

| Category | Fundamental Truth | Conventional Wisdom (Questionable) |
|----------|------------------|-----------------------------------|
| ActiveRecord | SQL queries return data matching conditions | "Always use includes for associations" |
| Controllers | Actions must return HTTP responses | "Never use render in callbacks" |
| Stimulus | Controllers have lifecycle methods | "Put everything in connect()" |
| Testing | Tests verify expected behavior | "Mock everything external" |
| Performance | Fewer queries = faster | "N+1 is always bad" |

**Key questions**:
- "Is this required by Rails/Ruby, or just a convention?"
- "What would happen if we removed this code?"
- "How do we know this is true in THIS context?"
- "Which 'requirements' are actually historical artifacts?"

**Then rebuild using only verified fundamentals — layer by layer until the bug appears**:

1. Verify the lowest layer works (model in console)
2. Add the next layer (controller without auth)
3. Add the next layer (request routing via logs)
4. Add the next layer (JavaScript request formation)

Stop at the layer where behavior diverges from expectation. That's where the bug lives.

### Step 4: Validate

```markdown
[ ] Does the fix solve the original problem?
[ ] Is the solution simpler than the original code?
[ ] Does it reveal the actual root cause?
[ ] Can it be implemented without side effects?
[ ] Does it work across all relevant contexts (tenants, users, states)?
```

## Test Failures After Refactoring

When tests fail after refactoring, ask first-principles questions before updating assertions:

1. **Fundamental**: Tests verify behavior, not implementation
2. **Fundamental**: Refactoring shouldn't change behavior
3. **Question**: Did the BEHAVIOR actually change, or just implementation?
4. **Question**: Was the test testing behavior or implementation details?

```ruby
# Testing implementation detail (fragile)
assert controller.instance_variable_get(:@products).count == 5

# Testing behavior (resilient)
assert_select '.product-card', count: 5
```

## Depth Calibration

**Too shallow**: "It's a Rails bug" (assumption, not verified)
**Right depth**: "Rails responds with 422 because validation failed; validation fails because..."
**Too deep**: "We need to understand Ruby's object model to fix this form"

**Rule**: Stop decomposing when further depth doesn't change the solution. Balance "theoretically optimal" with "framework-aligned" — conventions often encode hard-won lessons.

## Output

Produce a structured analysis:

```markdown
## First-Principles Analysis: [Issue Description]

**Conventional Understanding**: [How this is typically explained]

**Fundamental Elements**:
1. [Core component/constraint] - [Why fundamental]
2. [Core component/constraint] - [Why fundamental]

**Assumptions Questioned**:
- [Assumption] - [Fundamental or inherited?]

**Root Cause**: [Actual issue, traced to fundamentals]

**Solution**: [Fix based on fundamental understanding]

**Lessons Learned**: [What this reveals about the system]
```
