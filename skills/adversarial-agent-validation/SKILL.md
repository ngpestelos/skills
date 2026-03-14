---
name: adversarial-agent-validation
description: "Three-agent adversarial validation pattern exploiting LLM sycophancy: Finder (find), Adversary (disprove), Referee (score). Applies to bug hunting, security audits, code review, document triage (archive/retain/extract). Trigger keywords: find bugs, adversarial review, three-agent, quality sweep, deep review, sycophancy exploit, should I archive, extract or retain, bug sweep, adversarial validation, knowledge extraction triage. (global)"
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Adversarial Agent Validation

## Core Insight

LLMs are sycophantic — they comply with your request. Ask "find bugs" and they'll find bugs even if manufactured. Ask "disprove these bugs" and they'll aggressively challenge even real ones.

**The trick**: weaponize sycophancy in both directions, then use a third agent to reconcile.

## The Three Agents

### Agent 1: Finder

Produces the superset of all possible issues. Will inflate severity — this is by design.

```
You are a [bug finder / security auditor / code reviewer]. You earn points for findings:
- Low impact: +1 point
- Medium impact: +5 points
- Critical: +10 points

Your goal is to maximize your score. Examine [target] thoroughly.

For each finding, report:
1. Location (file:line)
2. Description
3. Severity (low/medium/critical)
4. Evidence (code snippet or reproduction steps)
5. Your claimed score for this finding
```

### Agent 2: Adversary

Produces the subset of actual issues by aggressively disproving false positives. The 2x penalty for incorrect disproof makes it conservative — it won't challenge findings unless confident.

```
You are an adversarial reviewer. Your job is to disprove the findings below.

Scoring:
- Successfully disprove a finding: +[finding's score] points
- Incorrectly disprove a real finding: -2x the finding's score

For each finding, either:
A) DISPROVE: Explain why this is not a real issue (with evidence)
B) CONFIRM: Acknowledge this is a real issue you cannot disprove

[Paste Finder's output here]
```

### Agent 3: Referee

Scores both agents and produces the final validated list.

```
You are a neutral referee scoring two agents' work on [target].

Agent 1 (Finder) reported these issues:
[Finder output]

Agent 2 (Adversary) challenged them:
[Adversary output]

For each finding, render a verdict:
- CONFIRMED: Real issue, Adversary failed to disprove
- DISMISSED: Not a real issue, Adversary successfully disproved
- NEEDS INVESTIGATION: Insufficient evidence either way

Provide a final ranked list of confirmed issues by severity.
Score Agent 1 and Agent 2 on accuracy.
```

## Implementation Patterns

### Pattern A: Sequential (Simple)

Run three agents in sequence, passing output forward. Best for small-to-medium scope.

```
1. Launch Finder agent on target → collect output
2. Launch Adversary agent with Finder's output → collect output
3. Launch Referee agent with both outputs → final report
```

### Pattern B: Parallel Finder + Sequential Review

Run multiple Finder agents in parallel on different scopes, merge, then review.

```
1. Launch Finder agents in parallel (one per module/area)
2. Merge all findings, deduplicate
3. Launch Adversary on merged list
4. Launch Referee on both outputs
```

### Domain Variants

| Domain | Finder | Adversary | Referee |
|--------|--------|-----------|---------|
| **Bug hunting** | Find bugs | Disprove bugs | Validate findings |
| **Security audit** | Find vulnerabilities | Challenge exploitability | Assess real risk |
| **Code review** | Find code smells | Defend design decisions | Judge merit |
| **Document review** | Find factual errors | Defend claims with evidence | Render verdicts |
| **Test coverage** | Find untested paths | Argue coverage suffices | Identify real gaps |
| **Architecture review** | Find design flaws | Defend architectural choices | Assess trade-offs |
| **Document triage** | Find extractable concepts | Argue content is too narrow/stale | Decide: archive, retain, or extract |

## Scope Guidance

**Good fit**: Bug sweeps, security audits, pre-release quality checks, architecture reviews, document triage — anywhere false positives are costly and thoroughness matters.

**Poor fit**: Simple linting (use tools), style preferences (subjective), tasks with clear pass/fail criteria (use tests).

**Scope sizing**: Each agent needs focused context. For large codebases, scope each run to a module, feature, or file group rather than the entire codebase.
