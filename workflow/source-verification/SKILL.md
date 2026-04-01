---
name: source-verification
description: "Verifies external sources cited in drafts before publication. Prevents circular verification via WebFetch and enforces evidence tiers for attributed claims. Trigger keywords: verify sources, fact-check, cited claim, publication ready, source URL, WebFetch verification, dead link."
---

# Source Verification

Verify every attributed claim traces to a live, independently confirmable source before publication.

## The WebFetch Trap

WebFetch processes content through an AI model. When a page is dead/paywalled, the model generates plausible content matching your prompt — circular verification.

**Detection signals**: Content perfectly matches expectations, quotes align word-for-word with draft, no unexpected details, page returns error on second fetch.

**Rule**: Never use WebFetch as sole verifier. If WebFetch only confirmed what you prompted for, treat as unverified.

## Source Tiers

| Tier | Description | Action |
|------|------------|--------|
| 1 | Live primary source (paper with DOI, author's post, book with page ref) | Cite with confidence |
| 2 | Live credible secondary source (news, podcast with timestamp) | Cite as "as reported by" |
| 3 | Single offline secondary (Wayback Machine archive exists) | Cite with archive link, flag |
| 4 | Unverifiable (dead source, no archive, WebFetch-only) | **Cut or rewrite without attribution** |

## Verification Protocol

1. **Classify**: Primary vs. secondary? URL live?
2. **Cross-reference**: Appears in 2+ independent sources? Flag single-source as fragile.
3. **WebFetch check**: Did it contain info you did NOT already know? If not, treat as unverified.
4. **Quote exactness**: Can you confirm exact wording from live source?
5. **Assign tier**: Tier 1-2 proceed, Tier 3 flag with archive, Tier 4 cut.

## Verification Table

```markdown
| Claim | Source | Tier | Status | Action |
|-------|--------|------|--------|--------|
| Karpathy "never felt this behind" | X post, Dec 26 2025 | 1 | Live | Keep |
| Cherny profiler anecdote | 36kr article | 4 | Dead, no archive | Cut |
```

## Pre-Publication Checklist

- [ ] Source URL visited by user (not just WebFetch) OR published book/paper
- [ ] All claims classified Tier 1, 2, or 3
- [ ] No Tier 4 claims remain
- [ ] Quotes confirmed against live source
- [ ] WebFetch was not sole verifier for any claim
