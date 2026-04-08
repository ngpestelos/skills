---
name: subagent-driven-development
description: Execute implementation plans by dispatching fresh subagents per task with two-stage review (spec compliance then code quality)
version: 1.1.0
trigger: execute plan, dispatch subagents, parallel implementation, plan execution, delegate tasks
---

# Subagent-Driven Development

Execute implementation plans by dispatching fresh subagents per task with systematic two-stage review.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration.

## When to Use

- Implementation plan exists (tasks are defined)
- Tasks are mostly independent
- Quality and spec compliance matter

## The Process

### 1. Read and Parse Plan

Read the plan file once. Extract ALL tasks with full text and context. Create a tracking list. **Never make subagents read the plan file** — provide the full task text directly in their context.

### 2. Per-Task Workflow

For each task, three sequential dispatches:

**Step 1 — Implementer subagent**: Fresh context with complete task spec, project conventions, and TDD instructions (write failing test → implement → verify pass → commit). Include scene-setting context so the subagent understands where the task fits.

**Step 2 — Spec compliance reviewer**: Verify implementation matches the original spec exactly. Checklist: all requirements implemented? File paths match? Function signatures match? Nothing extra added (no scope creep)? Output: PASS or list of specific gaps. **If gaps found:** fix and re-review until PASS.

**Step 3 — Code quality reviewer**: After spec compliance passes. Check: project conventions, error handling, naming, test coverage, edge cases, security. Output: Critical/Important/Minor issues + APPROVED or REQUEST_CHANGES. **If issues found:** fix and re-review until APPROVED.

Mark task complete only after both reviews pass.

### 3. Final Integration Review

After ALL tasks complete, dispatch one final reviewer: do all components work together? Any inconsistencies? All tests passing? Ready for merge?

### 4. Verify and Commit

Run full test suite, review all changes, final commit.

## Task Granularity

Each task = 2-5 minutes of focused work.

- **Too big**: "Implement user authentication system"
- **Right size**: "Create User model", "Add password hashing", "Create login endpoint", "Add JWT generation", "Create registration endpoint"

## Red Flags

- Start implementation without a plan
- Skip either review stage (spec compliance OR code quality)
- Start quality review before spec compliance is PASS
- Proceed with unfixed critical/important issues
- Dispatch parallel subagents for tasks touching the same files
- Make subagent read the plan file instead of providing full text in context
- Let implementer self-review replace actual review
- Move to next task while reviews have open issues

## Why This Works

**Fresh subagent per task**: Prevents context pollution from accumulated state. Each gets clean, focused context.

**Two-stage review**: Spec review catches under/over-building early. Quality review ensures well-built implementation. Issues caught before they compound.

**Cost trade-off**: More subagent invocations per task, but catches issues early — cheaper than debugging compounded problems later.
