---
name: research
version: 1.0
description: "Systematic first-principles research via web search producing actionable knowledge documents with layered summarization (executive summary, highlights, context) and source citations. Decomposes topics, executes parallel searches, and scores discoverability. Auto-activates when researching topics, gathering evidence, or producing research documents. Trigger keywords: research, investigate, deep dive, literature review, evidence gathering, web search, fact check, source verification."
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

## Special Case: SaaS Customer Support Research

For companies that obscure contact methods (common with modern SaaS):

**Search strategy:**
- Query: `"how to contact [company] support" OR "[company] customer service"`
- Check: Help Center structure, support ticket URLs, chatbot workflows
- Look for: Tiered support (free vs paid), "I still need help" escalation paths

**Common patterns:**
| Pattern | Indicators | Approach |
|---------|------------|----------|
| Chatbot-gated tickets | Help center chat widget | Start chat → request human → submit ticket |
| Email-only | No phone listed | `support@` or `help@` domain, expect auto-response |
| Tiered support | Free vs Pro plans | Paid users get priority/ticket access |
| Store-mediated | iOS/Android app purchases | Must refund through Apple/Google, not vendor |
| Community-only | Forums, Reddit | No official support channel |

**Verify claims:** Search `[company] "no phone support"` or `[company] pissedconsumer` to confirm limitations.

**Output:** Contact method table with URLs, support tier distinctions, and escalation workflows.

## Special Case: Financial Platform Phone Verification Research

For Stripe, Wise, PayPal, and bank KYC verification — standard VoIP numbers often fail.

**Key distinction:**
- **VoIP numbers** (MySudo, Hushed, Google Voice, TextNow) → frequently blocked for fraud prevention
- **Non-VoIP/real SIM numbers** (MobileSMS.io, carrier-backed services) → 95-99% acceptance

**Search strategy:**
- Query: `"[service] verification VoIP blocked" OR "virtual phone number [service] 2025"`
- Check: Reddit r/beermoney, r/privacytoolsIO for recent success/failure reports
- Look for: "non-VoIP", "real SIM", "carrier-backed" providers

**Provider comparison approach:**
| Type | Examples | Stripe Success | Cost Structure |
|------|----------|----------------|----------------|
| VoIP privacy apps | MySudo, Hushed | ⚠️ 50-70% | $2-5/mo |
| Non-VoIP rentals | MobileSMS.io | ✅ 99%+ | $3.50/SMS or $30/mo |
| Burner VoIP | Burner (standard) | ❌ Low | $5/mo |
| Burner Verified | Burner + upgrade | ⚠️ Moderate | $5/mo + fees |

**Critical questions:**
1. Is this for one-time verification or ongoing account access? (Temporary numbers risk lockout)
2. Does the platform require two-way SMS/calls or receive-only?
3. Is there a "Verified Number" upgrade that converts VoIP to carrier-backed?
4. **Does the provider's ToS explicitly block financial platforms?** (Critical: Some non-VoIP services like SMSPool prohibit banking/fintech use even though the technology works)

**Verify claims:** Search `[provider] "didn't work" Stripe` or `[provider] SMS verification Reddit 2025`

**ToS verification (Critical):** Search `[provider] terms of service banking OR financial OR "prohibited services"` — some providers explicitly ban financial platform verification despite offering non-VoIP numbers.

**Known ToS blockers (as of 2026):**
| Provider | Technology | Stripe Works? | Issue |
|----------|-----------|---------------|-------|
| **SMSPool** | Non-VoIP real SIM | ❌ **Blocked by ToS** | Explicitly prohibits banking, PayPal, crypto exchanges, Stripe |
| MobileSMS.io | Non-VoIP real SIM | ✅ Yes | No financial restrictions |

**SMSPool specifics:**
- Pricing: $0.02–$0.59/SMS (cheapest option)
- Technology: Real SIM numbers (non-VoIP)
- **Critical limitation:** ToS explicitly lists "financial platforms — banking apps, PayPal, crypto exchanges" as prohibited uses
- Risk: Account termination on SMSPool, potential fraud flags on target platform
- **Verdict:** Excellent for social/consumer apps, **do not use for Stripe/banks**

**Lesson:** Non-VoIP ≠ Financial-compatible. Always verify ToS restrictions separately from technical capabilities.

**Output:** Provider comparison with technology type, platform-specific success rates, pricing tiers, **ToS restrictions for financial use**, and lockout risk assessment.
