---
name: adversarial-agent-validation
description: "Three-agent adversarial validation pattern exploiting LLM sycophancy: Finder (find), Adversary (disprove), Referee (score). Applies to bug hunting, security audits, code review, document triage. Trigger keywords: find bugs, adversarial review, three-agent, quality sweep, deep review, bug sweep, adversarial validation, knowledge extraction triage."
version: "2.0"
license: MIT
metadata:
  author: ngpestelos
  version: "2.0"
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Adversarial Agent Validation

## Core Insight

LLMs are sycophantic — ask "find bugs" and they manufacture them; ask "disprove these bugs" and they challenge real ones. **Weaponize sycophancy in both directions**, then reconcile with a third agent.

## The Three Agents

### Agent 1: Finder

Produces the superset of all possible issues. Will inflate severity — by design.

```
You are a [bug finder / security auditor / code reviewer]. Scoring: Low +1, Medium +5, Critical +10. Maximize your score examining [target].

For each finding report: (1) Location file:line, (2) Description, (3) Severity, (4) Evidence, (5) Claimed score.
```

### Agent 2: Adversary

Disproves false positives. The 2x penalty for incorrect disproof makes it conservative.

```
You are an adversarial reviewer. Disprove the findings below.
Scoring: Successfully disprove = +[finding's score]. Incorrectly disprove a real finding = -2x score.

For each finding: (A) DISPROVE with evidence, or (B) CONFIRM as real.

[Paste Finder output]
```

### Agent 3: Referee

```
You are a neutral referee. For each finding, verdict: CONFIRMED / DISMISSED / NEEDS INVESTIGATION.
Provide a final ranked list by severity. Score both agents on accuracy.

Agent 1 (Finder): [output]
Agent 2 (Adversary): [output]
```

## Implementation

**Sequential**: Finder -> Adversary -> Referee. Best for small-to-medium scope.

**Parallel**: Multiple Finders on different modules, merge + deduplicate, then Adversary + Referee.

## Domain Variants

| Domain | Finder | Adversary | Referee |
|--------|--------|-----------|---------|
| Bug hunting | Find bugs | Disprove bugs | Validate findings |
| Security audit | Find vulnerabilities | Challenge exploitability | Assess real risk |
| Code review | Find code smells | Defend design decisions | Judge merit |
| Document triage | Find extractable concepts | Argue content is stale | Archive/retain/extract |
| Architecture review | Find design flaws | Defend choices | Assess trade-offs |

## Scope Guidance

**Good fit**: Bug sweeps, security audits, architecture reviews, document triage — anywhere false positives are costly.

**Poor fit**: Linting (use tools), style preferences (subjective), clear pass/fail (use tests).

**Sizing**: Scope each agent run to a module or feature, not the entire codebase.
