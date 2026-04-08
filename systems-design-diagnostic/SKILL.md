---
name: systems-design-diagnostic
description: Analyze projects, products, or organizations against four systems design archetypes that predict failure patterns (apenwarr/Freeman/Brooks/Christensen)
version: 1.0.0
trigger: systems design, hidden control, power structure, bootstrap problem, chicken-egg, rewrite proposal, second-system, innovator's dilemma, disruption risk, why projects fail
---

# Systems Design Diagnostic

Four archetypes that "will eventually kill your project if you do it wrong, but probably not right away." (apenwarr, drawing on Jo Freeman, Fred Brooks, Clayton Christensen)

## 1. Centralized vs. Distributed Control

Supposedly "flat" structures conceal informal, unaccountable control. The question is never whether control exists, but whether it is visible.

- **Detect**: Who actually decides? Do stated processes match actual patterns?
- **Red flag**: "We're flat" but certain people always win. Decisions in DMs, not meetings.
- **Fix**: Make hierarchy explicit — visible and debuggable, not eliminated.

## 2. Bootstrap Paradox (Chicken-Egg)

Product utility depends on adoption, but adoption depends on utility.

- **Detect**: What value does the first user get? What's the bootstrap strategy?
- **Red flag**: "It'll be great once everyone uses it." No Day 1 standalone value.
- **Strategies**: Subsidy (deep pockets), compatibility (work with existing), standalone value (useful without network), forced adoption (mandate/bundling).
- **The IPv6 test**: Technically superior + zero immediate value + no backward compatibility = 30+ years of minimal adoption.
- **Fix**: Design Day 1 value independent of network size.

## 3. Second-System Effect

Complete rewrites consistently fail: delayed feature parity, unexpected new problems, management pressure to ship incomplete.

- **Detect**: Is someone proposing a complete rewrite? Why not incremental refactoring?
- **Red flag**: "Old team didn't know what they were doing." "Only 6 months."
- **The Brooks Test**: Team deeply understands old system? Requirements genuinely changed? Platform truly obsolete? Rollback plan exists? Any "No" → prefer incremental.
- **Fix**: Strangler fig pattern — gradually replace while old system runs.

## 4. Innovator's Dilemma

Organizational incentives drive retreat from low-margin markets, creating vulnerability to disruption from below.

- **Detect**: Abandoning "unattractive" segments? Margin optimization driving strategy?
- **Red flag**: "That market isn't worth our time." Margin up, market share down.
- **The Intel/ARM test**: Intel optimized margins → ignored "inferior" ARM → ARM improved → ARM challenges Intel in core markets.
- **Fix**: Invest in "low-margin" segments as defensive strategy. Separate units with different incentive structures if needed.

## Quick Reference

| Archetype | One Question | Red Flag Answer | Right Fix |
|-----------|-------------|----------------|-----------|
| Control | "Who really decides?" | "It depends" | Make hierarchy explicit |
| Bootstrap | "Why would first user care?" | "Once everyone uses it..." | Design Day 1 value |
| Second-System | "Why not refactor instead?" | "Too much tech debt" | Strangler fig |
| Innovator's | "Why ignore that segment?" | "Not worth our time" | Invest in disruption defense |

## Audit Process

1. **Identify Context** (2 min) — What are you evaluating? Architecture, product strategy, org structure, or proposed change.
2. **Four-Archetype Checklist** (15-20 min) — For each: current state, detection findings, risk level (L/M/H), specific evidence.
3. **Prioritize and Act** (5 min) — Highest-risk archetype, concrete mitigation, follow-up date.
