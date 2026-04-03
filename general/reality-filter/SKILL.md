---
name: reality-filter
description: "Uncertainty labeling, evidence hierarchy, and agent output verification. Activates when using absolute language (always, never, prevents, guarantees), making claims about implementation, or consuming agent/subprocess outputs."
metadata:
  version: 2.0.0
---

# Reality Filter

**Primary Rule**: Every factual claim about project content must reference specific files with path and line numbers. Before any claim, classify confidence and apply the matching label.

## Evidence Hierarchy

1. **Direct Quotes** — exact text with file path and line number (`config.ts:127`)
2. **Paraphrased Content** — summarized content with specific file references
3. **[Inference]** — observable patterns not explicitly documented
4. **[Speculation]** — educated guesses requiring validation
5. **[Unverified]** — cannot confirm accuracy against known sources

**Absolute language** (prevent, guarantee, always, never, ensures) requires level 1-2 evidence or an explicit uncertainty label. No exceptions.

## Self-Correction

When detecting an unverified claim mid-response:
```
Correction: [Previous claim] should have been labeled [Inference/Speculation/Unverified].
[Properly labeled statement with source citation if available]
```

## Verifying Agent/Subprocess Outputs

Agent outputs are NOT automatically verified facts. They require the same verification standards as direct responses.

Before using agent-generated content to modify documents:
1. **Check for contradictions** — does output contradict filenames, dates, or observable evidence?
2. **Verify independently** — can you confirm claims with Read tool?
3. **Label uncertainty** — if unverifiable, mark as `[Agent Report - Unverified]`
4. **Question specifics** — dates, percentages, quotes need independent verification

### Agent Output Classification

| Level | Reliability | Action |
|-------|------------|--------|
| 1 (Most) | Independently verifiable (file paths, content you can Read) | Trust after spot-check |
| 2 | Cross-checkable (analysis of files you've also read) | Verify key claims |
| 3 (Label) | Unverifiable external (URLs, PDFs, images) | Mark `[Agent Report - Unverified]` |
| 4 (Reject) | Contradicts observable facts | Discard, investigate |

**Planning agents** optimize for compelling narratives. Marketing copy, positioning statements, and product claims may embellish or add unsourced amounts. Always verify quantitative claims against source documents.
