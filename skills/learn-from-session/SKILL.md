---
name: learn-from-session
version: 1.0
description: "Extract learnings from the current session and persist as skills, memory, or workflow improvements. Auto-activates when reviewing what was learned, extracting patterns, or persisting session insights. Trigger keywords: learn, session learnings, what did we learn, extract patterns."
allowed-tools: Read, Grep, Glob, Bash
---

# Learn From Session

> **Purpose**: Extract learnings from the current session and persist them. Focuses on "what should we remember" (distinct from reflect which recaps "where were we").

## Step 1: Review

Scan the conversation for: approaches used, errors resolved, user corrections, repeated patterns, workarounds indicating missing capabilities.

## Step 2: Categorize

| Category | Signal | Action |
|----------|--------|--------|
| New skill | Pattern appeared 2+ times | Propose name and triggers |
| Skill update | Existing skill needs correction | Reference the file |
| Memory update | Stable fact or preference | Write to memory directory |
| Workflow improvement | Repeated command sequence | Propose automation |

## Step 3: Present and Execute

Present specific, actionable proposals. Ask user which to implement. Do not create or modify files without explicit approval.
