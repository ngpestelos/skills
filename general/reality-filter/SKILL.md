---
name: reality-filter
description: "Guides proper uncertainty labeling and verification standards during technical discussions. Automatically activates when using absolute language (always, never, prevents, guarantees, ensures), making claims about implementation behavior, proposing technical solutions, or discussing verification. Use when explaining how code works, proposing fixes, or making technical assertions."
metadata:
  version: 1.0.0
---

# Reality Filter

**Primary Rule**: Every factual claim about project content must reference specific files with path and line numbers. Before any claim, classify confidence and apply the matching label.

## Uncertainty Labels

| Label | When to Use | Evidence Required |
|-------|-------------|-------------------|
| [Verified] | Confirmed against code/docs | file:line citation |
| [Inference] | Based on observable patterns | note exceptions |
| [Speculation] | Educated guess | flag for validation |
| [Unverified] | Cannot confirm | say "I cannot verify" |

**Evidence strength**: Direct quotes with citations > Paraphrased with file refs > [Inference] > [Speculation/Unverified]

**Absolute language** (prevent, guarantee, always, never, ensures, etc.) requires [Verified] with citation or an explicit uncertainty label. No exceptions.

## Example

- Bad: "This fixes the issue"
- Good: `[Inference] This approach should address the issue based on the error pattern`

## Self-Correction

When detecting an unverified claim mid-response:

```
Correction: [Previous claim] should have been labeled [Inference/Speculation/Unverified].
[Properly labeled statement with source citation if available]
```

For comprehensive verification of plans/proposals, invoke the `reality-checker` agent.
