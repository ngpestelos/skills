---
name: adversarial-agent-validation
description: "Three-agent adversarial validation pattern exploiting LLM sycophancy: Finder (find), Adversary (disprove), Referee (score). Applies to bug hunting, security audits, code review, document triage (archive/retain/extract). Trigger keywords: find bugs, adversarial review, three-agent, quality sweep, deep review, sycophancy exploit, should I archive, extract or retain, bug sweep, adversarial validation, knowledge extraction triage. (global)"
allowed-tools: Agent, Read, Grep, Glob, Bash
---

# Adversarial Agent Validation

## Core Insight

LLMs are sycophantic — they want to comply with your request. If you ask "find bugs," they'll find bugs even if they have to manufacture them. If you ask "disprove these bugs," they'll aggressively challenge even real ones.

**The trick**: weaponize sycophancy in both directions, then use a third agent to reconcile.

## Methodology

### The Three Agents

### Agent 1: Finder

**Goal**: Produce the superset of all possible issues.

**Incentive framing**:
- +1 point for low-impact findings
- +5 points for medium-impact findings
- +10 points for critical findings

**What to expect**: Enthusiastic, thorough, will inflate severity. This is by design — you want the broadest possible net. False positives are acceptable at this stage.

**Prompt pattern**:
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

**Goal**: Produce the subset of actual issues by aggressively disproving false positives.

**Incentive framing**:
- +N points for successfully disproving a finding (where N = the finding's claimed score)
- -2N penalty for incorrectly disproving a real finding

**What to expect**: Aggressive challenges. The asymmetric penalty (2x cost for incorrect disproof) makes it conservative — it won't challenge findings unless confident they're false.

**Prompt pattern**:
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

**Goal**: Score both agents and produce the final validated list.

**Incentive framing**:
- Points for accuracy against a (claimed) ground truth
- Penalized for both false positives and false negatives

**Prompt pattern**:
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

Run multiple Finder agents in parallel on different scopes, merge, then run Adversary and Referee.

```
1. Launch Finder agents in parallel (one per module/area)
2. Merge all findings, deduplicate
3. Launch Adversary on merged list
4. Launch Referee on both outputs
```

### Pattern C: Domain-Specific Variants

The three-agent pattern applies beyond bug-finding:

| Domain | Finder | Adversary | Referee |
|--------|--------|-----------|---------|
| **Bug hunting** | Find bugs | Disprove bugs | Validate findings |
| **Security audit** | Find vulnerabilities | Challenge exploitability | Assess real risk |
| **Code review** | Find code smells / issues | Defend design decisions | Judge merit |
| **Document review** | Find factual errors | Defend claims with evidence | Render verdicts |
| **Test coverage** | Find untested paths | Argue existing coverage suffices | Identify real gaps |
| **Architecture review** | Find design flaws | Defend architectural choices | Assess trade-offs |
| **Document triage** | Find extractable concepts/skills | Argue content is too narrow/stale | Decide: archive, retain, or extract |

### Pattern D: Document Triage (Archive / Retain / Extract)

Applies the three-agent pattern to knowledge management decisions. Prevents both over-extraction (manufacturing concepts from thin source material) and under-extraction (archiving documents that contain reusable patterns).

**Agent 1: Extractor (Finder)**

Incentivized to find maximum extractable value. Reads the document and identifies:

```
You are a knowledge extraction specialist. You earn points for findings:
- Reusable skill/pattern extractable to a SKILL.md: +10 points
- Atomic concept with 2+ cross-domain applications: +5 points
- Reference worth retaining in active Resources: +3 points
- Time-bound data or single-domain content (archive candidate): +1 point

Read [document]. For each finding, report:
1. What you found (concept, pattern, or skill)
2. Category (skill / atomic concept / active reference / archive-only)
3. Cross-domain reach (list domains where this applies)
4. Evidence (quote the specific passage)
5. Your claimed score
```

**What to expect**: Will find extractable concepts everywhere, inflate cross-domain reach, and argue against archiving. Good — this ensures nothing valuable is missed.

**Agent 2: Archivist (Adversary)**

Incentivized to challenge extraction claims. Argues content should be archived or is already covered.

```
You are a knowledge vault archivist. Your job is to challenge extraction claims.

Scoring:
- Successfully argue a finding is too narrow/stale/covered: +[finding's score] points
- Incorrectly dismiss a genuinely extractable concept: -2x the finding's score

For each finding from Agent 1, either:
A) DISMISS: Explain why this doesn't warrant extraction:
   - Too domain-specific (fails 2+ cross-domain test)
   - Time-bound data that will go stale
   - Already covered by existing note [name the note]
   - Narrative/anecdotal, not a transferable principle
B) CONFIRM: Acknowledge this is genuinely extractable

[Paste Extractor's output here]
```

**What to expect**: Aggressive pruning. Will claim concepts are too narrow, already covered, or just restatements of known ideas. The 2x penalty prevents it from dismissing genuinely novel concepts.

**Agent 3: Curator (Referee)**

Renders final triage verdict per finding.

```
You are a knowledge curator deciding the fate of [document].

Agent 1 (Extractor) found these extraction candidates:
[Extractor output]

Agent 2 (Archivist) challenged them:
[Archivist output]

For each finding, render a verdict:
- EXTRACT AS SKILL: Reusable pattern worth a SKILL.md file
- EXTRACT AS ATOMIC NOTE: Concept worth a standalone note in Topics/
- RETAIN: Document stays in active Resources (useful reference, not extractable)
- ARCHIVE: Content is time-bound, single-domain, or fully covered elsewhere

Then render the overall document verdict:
- EXTRACT: At least one finding warranted extraction → extract, then archive source
- RETAIN: No extraction warranted but document is a useful active reference
- ARCHIVE: No extraction warranted and content is stale/narrow → archive with progressive summary only
```

**When to use this pattern**: Documents where the triage decision is genuinely uncertain — large research docs, competitive analyses, multi-topic articles, conference talk notes. Skip for obviously narrow content (single SQL trick, market snapshot with dated numbers) or obviously extractable content (named framework with clear cross-domain transfer).

## Scope Guidance

**Good fit**: Bug sweeps, security audits, pre-release quality checks, document fact-checking, architecture reviews, document triage decisions — anywhere false positives are costly and thoroughness matters.

**Poor fit**: Simple linting (use tools), style preferences (subjective), tasks with clear pass/fail criteria (use tests).

**Scope sizing**: Each agent needs focused context. For large codebases, scope each run to a module, feature, or file group rather than the entire codebase.

## Output

Each pattern produces a structured report:

**Code-oriented patterns (A, B, C)**: Ranked list of confirmed findings with per-finding verdicts (CONFIRMED / DISMISSED / NEEDS INVESTIGATION), severity, evidence, and accuracy scores for Finder and Adversary agents.

**Document triage (Pattern D)**: Per-finding verdicts (EXTRACT AS SKILL / EXTRACT AS ATOMIC NOTE / RETAIN / ARCHIVE) plus an overall document verdict (EXTRACT / RETAIN / ARCHIVE) with reasoning.

## Key Principles (from source)

1. **Context minimization**: Give each agent only the files/information relevant to their scope
2. **Deterministic termination**: Each agent has clear output format and completion criteria
3. **Sycophancy as feature**: The compliance bias is the mechanism, not a bug to work around
4. **Asymmetric penalties**: The Adversary's 2x penalty for incorrect disproof is critical — it prevents aggressive dismissal of real issues
