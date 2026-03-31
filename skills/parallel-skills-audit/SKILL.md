---
name: parallel-skills-audit
version: 1.0
description: "Triage all skills then spawn parallel agents to deep-audit flagged ones. Auto-activates when batch auditing skills or optimizing multiple skills at once. Trigger keywords: parallel audit, batch audit, audit all skills, bulk optimize skills."
allowed-tools: Read, Grep, Glob, Bash
---

# Parallel Skills Audit

> **Purpose**: Triage all skills, then spawn parallel agents to deep-audit flagged skills.

## Step 1: Triage

Run skills-audit triage mode. Collect the status table.

## Step 2: Filter and Confirm

Collect skills flagged `LARGE` (>300 lines) or `DUP` (both scopes). Apply scope filter if provided. Sort by line count descending.

Present: "Found N skills to audit in batches of M. Proceed?" Wait for confirmation.

## Step 3: Batch Dispatch

For each batch (default 5 concurrent):

Spawn parallel background agents. Each agent prompt:
```
Deep audit the skill at {skill_path} ({line_count} lines).
Read SKILL.md and references/. Then:
1. Spec check: frontmatter (name, description ≤1024), body (<500 lines, <5000 tokens)
2. Five-step optimize: question, delete obvious/duplicate/hypothetical, tighten
3. Decompose: if >300 lines, extract to references/
4. Fix frontmatter, report results
IMPLEMENT all changes. Return: skill name, before/after lines, what was deleted.
```

Report batch results: Skill | Before | After | Reduction. Ask before next batch.

## Step 4: Summary

Cumulative results table. Total: skills processed, lines removed.
