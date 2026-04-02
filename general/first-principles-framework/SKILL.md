---
name: first-principles-framework
description: "Unified first-principles methodology with three modes. Analysis decomposes problems to foundational elements with Rails debugging patterns. Foundation Building creates educational documents from observations to laws. Summarization preserves logical structure of first-principles documents. Trigger keywords: first principles, fundamental truth, decompose, root cause, observation to law, foundation document, first-principles summary."
---

Apply first-principles thinking across three modes: analyzing problems, building educational foundations, and summarizing first-principles documents.

## Mode 1: Analysis (Problem Decomposition)

1. **Identify**: State the problem in one sentence without jargon
2. **Deconstruct**: Basic components? Core constraints? Assumed vs actual requirements? Fundamental truths?
3. **Question**: "Is this actually required, or just how it's always been done?" "What would happen if we removed this constraint?"
4. **Rebuild**: Start with core truths → add only necessary elements → test each assumption → stack verified principles into solution

### Rails/Stimulus Debugging Decomposition

**Rails request flow**: Request → Routing → Before filters → Action → Response

**Stimulus lifecycle**: Controller registration → DOM connection → Target binding → Action binding → Event handling → State management → Cleanup

**Minimal reproduction**: Start minimal, add layers until bug appears (Model in console → Controller without auth → AJAX reaching controller → JavaScript forming request).

| Category | Fundamental Truth | Questionable Wisdom |
|----------|------------------|---------------------|
| ActiveRecord | SQL returns data matching conditions | "Always use includes" |
| Controllers | Actions must return HTTP responses | "Never render in callbacks" |
| Stimulus | Controllers have lifecycle methods | "Put everything in connect()" |
| Testing | Tests verify expected behavior | "Mock everything external" |
| Performance | Fewer queries = faster | "N+1 is always bad" |

**Common debugging patterns**: Multi-Tenant Data Isolation (where is current tenant set?), JavaScript Lifecycle (controller connecting to modal or parent?), State Machine Issues (primary or derived state wrong?), Test Failures After Refactoring (behavior or just implementation changed?).

## Mode 2: Foundation Building (Teaching Documents)

Create educational documents building from observations through laws to cross-domain applications. **Always observations-first, then formulas — never formula-first.**

Structure: Key Strategic Insight → Core Question → Mental Model → Laws/Principles (each: observation → problem → formal statement → plain language → implications → daily life → cross-domain) → Knowledge Network Connections

Every concept needs cross-domain connections and daily life examples.

## Mode 3: Summarization

Summarize first-principles documents (signals: "First Principles" in title, numbered laws, Observation/Problem/Law patterns, cross-domain tables) while preserving logical progression from observations to laws to applications.

| Document Complexity | Summary Length |
|--------------------|----------------|
| 2-3 laws, focused | 150-250 words |
| 4-6 laws, multiple domains | 300-500 words |
| Comprehensive foundation | 500-750 words |

## Key Rules

- Many conventions exist because they work — reject selectively, not wholesale
- Laws are the core value of first-principles documents — always preserve them in summaries
- Include cross-domain applications — first-principles documents exist because principles transfer
