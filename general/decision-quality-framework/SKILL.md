---
name: decision-quality-framework
description: Unified framework for bias identification, pre-mortem failure analysis, and process-based quality scoring. Evaluates decisions through cognitive bias audit, prospective hindsight, and six-dimension scoring independent of outcome. Activates when reviewing decisions, evaluating risks, or assessing reasoning quality.
allowed-tools: Read, Grep, Glob
---

# Decision Quality Framework

Systematic decision evaluation combining cognitive bias identification, pre-mortem failure analysis, and process-based quality scoring. **Judge decisions by process quality, not outcome quality.**

## Part 1: Five-Bias Audit

| Bias | Detection Question | Mitigation |
|------|-------------------|------------|
| **Confirmation** | Have I actively sought disconfirming evidence? | Devil's Advocate, Red Team, "How could I prove myself wrong?" |
| **Sunk Cost** | If starting fresh today, would I make the same choice? | Zero-Based Thinking, Future-Only Analysis |
| **Availability** | Am I overweighting recent/memorable examples? | Base Rate Check, Historical Review |
| **Anchoring** | Have I formed independent assessment before comparing? | Multiple Anchors, Range Thinking |
| **Overconfidence** | When have I been wrong about similar judgments? | Reference Class Forecasting, Wide Confidence Intervals |

**Extended**: Planning Fallacy, Optimism Bias, Hindsight Bias, Groupthink, Authority Bias, Fundamental Attribution Error.

**Mistakes to avoid**: Using bias labels to dismiss opposing views, overcorrecting (opposite of intuition isn't always correct), performative auditing without genuine reflection, analysis paralysis (set time limits).

## Part 2: Pre-Mortem Analysis

Prospective hindsight: "Why did this fail?" is cognitively easier than "Could this fail?" (Gary Klein; increases failure identification by 30%).

### Method (30-40 min)

**Step 1** (2 min): Project 6-12 months ahead. Assume complete failure.

**Step 2** (10-15 min): Generate failure causes across categories:

| Category | Key Questions |
|----------|--------------|
| Execution | Resource constraints? Timeline assumptions? Dependencies? |
| External | Market changes? Competitor actions? Regulatory shifts? |
| Internal | Team gaps? Organizational resistance? Motivation erosion? |
| Assumptions | Core assumptions wrong? Flawed data? |
| Unknown Unknowns | Black swans? Cascade failures? |

**Step 3** (5-10 min): For each failure mode, identify early warning signals, detection methods, and timelines.

**Step 4** (10-15 min): For high-impact failures: Prevention → Detection → Response → Recovery. Prioritize by probability × severity × detectability.

**Step 5** (5 min): Integrate into risk register and monitoring plan.

## Part 3: Six-Dimension Quality Scoring

| Dimension | Key Question | Poor (1-3) | Excellent (9-10) |
|-----------|-------------|------------|-------------------|
| **Information** | Did we know what we needed? | Major gaps | All key data, uncertainties quantified |
| **Alternatives** | Right range of choices? | Single option | Comprehensive, non-obvious paths |
| **Values Alignment** | Reflects what we value? | Values unclear | Values hierarchy explicit |
| **Reasoning** | Sound thinking process? | Unchecked biases | Rigorous, biases mitigated |
| **Risk Assessment** | Understood what could go wrong? | No assessment | Pre-mortem complete, exit options clear |
| **Timing** | Right amount of time? | Rushed or paralyzed | Optimal Type I/II match |

**Overall Score** = Average of 6 dimensions.

### Minimum Thresholds

**Type II (irreversible)**: Overall 7+, no dimension below 5, Reasoning/Risk/Timing each 7+.
**Type I (reversible)**: Overall 5+ acceptable. Speed often matters more.

### Process vs. Outcome Matrix

|  | Good Outcome | Bad Outcome |
|--|-------------|-------------|
| **Good Process** | Deserved Success | Bad Luck (don't change process) |
| **Bad Process** | Good Luck (fix process) | Deserved Failure |

## Combined Workflow

**Full Review (30-45 min)**: Bias Audit (10-15 min) → Pre-Mortem (15-20 min) → Quality Score (5-10 min)

**Quick Review (10 min)**: Which 1-2 biases most relevant? → 3 most likely failure modes with one mitigation each → Enough info? Alternatives considered? Risks assessed? Appropriate time?
