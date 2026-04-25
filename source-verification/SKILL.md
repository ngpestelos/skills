---
name: source-verification
description: "Verifies external sources cited in drafts before publication. Prevents circular verification via WebFetch and enforces evidence tiers for attributed claims. Trigger keywords: verify sources, fact-check, cited claim, publication ready, source URL, WebFetch verification, dead link."
metadata:
  version: "1.0.1"
---

# Source Verification

Verify every attributed claim traces to a live, independently confirmable source before publication.

## Source Tiers

| Tier | Description | Action |
|------|------------|--------|
| 1 | Live primary source (paper/DOI, author's post, book+page) — URL visited directly by user, not just WebFetch | Cite with confidence |
| 2 | Live credible secondary (news, podcast+timestamp) | Cite as "as reported by" |
| 3 | Single offline secondary (Wayback Machine archive exists) | Cite with archive link, flag |
| 4 | Unverifiable (dead source, no archive, WebFetch-only) | **Cut or rewrite without attribution** |

## Verification Protocol

1. **Classify**: Primary vs. secondary? URL live?
2. **Cross-reference**: Appears in 2+ independent sources? Flag single-source as fragile.
3. **WebFetch check**: WebFetch generates plausible content for dead/paywalled pages. If output contained no info you did NOT already know, treat as Tier 4 unverified.
4. **Quote exactness**: Confirm exact wording from live source.
5. **Assign tier**: Tier 1-2 proceed, Tier 3 archive-link, Tier 4 cut.

## Verification Table

```markdown
| Claim | Source | Tier | Status | Action |
|-------|--------|------|--------|--------|
|       |        |      |        |        |
```
