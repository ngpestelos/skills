---
name: structured-research
version: 1.0
description: "Systematic first-principles research via web search producing actionable knowledge documents with layered summarization and source citations. Auto-activates when researching topics, gathering evidence, or producing research documents. Trigger keywords: research, investigate, deep dive, literature review, evidence gathering."
allowed-tools: Read, Grep, Glob, Bash, WebSearch, WebFetch
---

# Structured Research

> **Purpose**: Systematic, first-principles research on any topic. Produces actionable knowledge with layered summarization and source citations.

## Phase 1: First-Principles Decomposition

Before searching, deconstruct:
- **Core subject** and context specificity (geographic, temporal, demographic)
- **Actionability goal** — what decisions does this support?
- **Questioned assumptions** — prioritize context-specific over generic
- **Source strategy**: Tier 1 (intl orgs, government, systematic reviews) → Tier 2 (academic, reputable news) → Tier 3 (avoid)

## Phase 2: Search Execution

Query pattern: `[Authority] + [Topic] + [Context] + [Year]`. Execute 3-5 parallel searches from different angles. Quick mode: 2-3 Tier 1 searches only.

## Phase 3: Layered Summarization

Extract in reverse order (most actionable first):

| Layer | Content | Test |
|-------|---------|------|
| L3 — Executive Summary | Single most important finding, magnitude, trend | 2-minute understanding |
| L2 — Key Highlights | Metrics with citations, systemic factors, responses, challenges | By category |
| L1 — Context | Historical patterns, structure, geographic detail, policy timeline | Depth |

## Phase 4: Citations

Every claim needs source attribution with full URLs. Label: verified fact → cite, logical inference → `[Inference from X]`, speculation → `[Hypothesis/Unverified]`.

## Phase 5: Discoverability

Score 1-10: layered accessibility (3), context specificity (2), citation quality (2), cross-references (2), actionability (1). Document gaps.

## Quick Mode

3-5 bullet summary, 2-3 key sources with URLs, follow-up checklist. Skip Phases 1 and 5.
