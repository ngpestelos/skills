---
name: adversarial-agent-validation
description: "Three-agent adversarial validation pattern exploiting LLM sycophancy: Finder (find), Adversary (disprove), Referee (score). Applies to bug hunting, security audits, code review, document triage. Trigger keywords: find bugs, adversarial review, three-agent, quality sweep, deep review, bug sweep, adversarial validation, knowledge extraction triage."
version: "2.1"
license: MIT
metadata:
  author: ngpestelos
  version: "2.1"
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

Arbitrates conflicts using evidence quality, not argument eloquence.

```
You are a neutral referee. Review the Finder's findings and Adversary's challenges.

**Decision criteria for each finding:**
- CONFIRMED: Evidence supports the issue; Adversary failed to disprove or evidence is weak
- DISMISSED: Adversary provided conclusive counter-evidence; issue is false positive
- NEEDS INVESTIGATION: Genuine uncertainty—evidence is ambiguous, requires domain expert or runtime verification

**For NEEDS INVESTIGATION items, specify:**
- What information is missing
- Who/what can provide it (code owner, test suite, log analysis, etc.)
- Whether it blocks the review or can be deferred

**Output format:**
1. Final verdict table: Finding | Severity | Verdict | Rationale (1-2 sentences)
2. Ranked by severity (Critical → Medium → Low)
3. Agent accuracy scores: Finder [X/X findings valid], Adversary [X/X disprovals correct]
4. Action items: What to fix now vs. investigate later

Agent 1 (Finder): [output]
Agent 2 (Adversary): [output]
```

## Worked Example: Authentication Module Review

### Agent 1: Finder Output

```
F1: auth_controller.rb:42 — Missing rate limiting on login endpoint
    Severity: Critical (+10)
    Evidence: No throttle or lockout mechanism visible; brute-force vulnerability
    Score claimed: 10

F2: session_store.rb:18 — Session token uses predictable random
    Severity: Critical (+10)
    Evidence: Uses rand() instead of SecureRandom; session hijacking risk
    Score claimed: 10

F3: password_validator.rb:33 — Allows 4-character passwords
    Severity: Medium (+5)
    Evidence: Minimum length check missing or set to 4
    Score claimed: 5
```

### Agent 2: Adversary Output

```
F1: DISPROVE — Rate limiting is enforced at middleware layer (config/initializers/rack_attack.rb:12)
    Evidence: Rack::Attack configured with 5 requests per 20 seconds per IP

F2: CONFIRM — File clearly shows rand(36**32).to_s(36); exploitable predictability
    Evidence: Line 18 uses insecure PRNG; no wrapper or override visible

F3: DISPROVE — Minimum length is 8 via Devise configuration (config/initializers/devise.rb:145)
    Evidence: devise.rb sets config.password_length = 8..128; validator delegates to this
```

### Agent 3: Referee Output

```
Final Verdicts:
| Finding | Severity | Verdict | Rationale |
|---------|----------|---------|-----------|
| F1 (rate limiting) | — | DISMISSED | Adversary provided conclusive counter-evidence; defense in depth exists at middleware layer |
| F2 (session token) | Critical | CONFIRMED | Finder evidence stands; Adversary confirmed no rebuttal possible; rand() is objectively insecure |
| F3 (password length) | — | DISMISSED | Configuration overrides validator; Finder examined wrong abstraction layer |

Agent Scores:
- Finder: 1/3 valid (33%) — over-reported but caught real issue F2
- Adversary: 3/3 correct (100%) — accurate disprovals, proper confirmation

Action Items:
- FIX NOW: Replace rand() with SecureRandom.hex(32) in session_store.rb:18
- DEFERRED: None (F1/F3 dismissed with evidence)
```

## Implementation

### Sequential Mode (Recommended)

Best for small-to-medium scope. Single conversation, three prompts.

```
Step 1: Run Finder prompt → copy output
Step 2: Paste into Adversary prompt → copy output  
Step 3: Paste both into Referee prompt → receive final verdicts
```

### Parallel Mode

For large codebases or multiple modules.

```
Step 1: Spawn multiple Finders (subagents or separate contexts) on different modules
Step 2: Merge outputs, deduplicate by location:line (same file+line = same issue)
Step 3: Single Adversary reviews merged list (or partition if too large)
Step 4: Single Referee adjudicates
```

**Deduplication rule:** Two findings with same file:line but different descriptions = merge descriptions, take highest severity. Same description, different locations = keep both, mark as pattern.

## Domain Variants

| Domain | Finder | Adversary | Referee |
|--------|--------|-----------|---------|
| Bug hunting | Find bugs | Disprove bugs | Validate findings |
| Security audit | Find vulnerabilities | Challenge exploitability | Assess real risk |
| Code review | Find code smells | Defend design decisions | Judge merit |
| Document triage | Find extractable concepts | Argue content is stale | Archive/retain/extract |
| Architecture review | Find design flaws | Defend choices | Assess trade-offs |

## Execution Mechanics

### Tooling Options

| Method | When to Use | Command/Pattern |
|--------|-------------|-----------------|
| **Single conversation** | Quick reviews, <200 LOC | Copy-paste prompts sequentially in same chat |
| **Subagents** | Large scope, need isolation | `delegate_task` with each agent as separate task |
| **File-based handoff** | Audit trails, team sharing | Write Finder output to file → read in Adversary task → write Referee verdicts |

### Subagent Pattern (Claude Code)

```bash
# Finder agent
claude -p "You are Finder. Scoring: Low +1, Medium +5, Critical +10. Examine src/auth.rb. Report all issues with file:line, description, severity, evidence, claimed score."

# Adversary agent (paste Finder output)
claude -p "You are Adversary. Scoring: +[finding score] for correct disproof, -2x for incorrect disproof. [paste Finder output]"

# Referee agent (paste both outputs)
claude -p "You are Referee. For each finding: CONFIRMED / DISMISSED / NEEDS INVESTIGATION with rationale. [paste both]"
```

### File-Based Handoff Pattern

```bash
# Phase 1: Finder writes to file
claude -p "You are Finder... Output findings to /tmp/audit_findings.md"

# Phase 2: Adversary reads file, writes response
claude -p "You are Adversary... Read /tmp/audit_findings.md, output challenges to /tmp/audit_adversary.md"

# Phase 3: Referee reads both, writes verdicts
claude -p "You are Referee... Read both files, output final report to audit_report_YYYYMMDD.md"
```

## Calibration & Expected Behavior

### Finder Inflation Rates

Based on observed behavior across code reviews:

| Code Quality | False Positive Rate | Typical Findings/100 LOC |
|--------------|---------------------|--------------------------|
| Production-grade | 50-70% | 2-4 findings |
| Legacy/untouched | 30-50% | 4-8 findings |
| Rapid prototype | 60-80% | 5-10 findings |

**Interpretation:** Expect to dismiss 1 in 2 Findings. This is by design—the superset captures edge cases single-pass review misses.

### Scoring Effectiveness

The -2x penalty for incorrect Adversary disproofs has been observed to:
- Reduce false dismissals by ~40% vs. no penalty
- Increase "CONFIRM as real" rate (conservative bias)
- Produce more detailed evidence requirements

**Adjust if:** Adversary is dismissing everything (penalty too low) or confirming everything (penalty too high). Range: -1.5x to -3x.

## Scope Guidance

**Good fit**: Bug sweeps, security audits, architecture reviews, document triage — anywhere false positives are costly.

**Poor fit**: Linting (use tools), style preferences (subjective), clear pass/fail (use tests).

**Sizing**: Scope each agent run to a module or feature, not the entire codebase.

**Maximum scope per agent:** ~500 LOC or single controller/model. Larger scopes cause Finding inflation and Adversary fatigue.
