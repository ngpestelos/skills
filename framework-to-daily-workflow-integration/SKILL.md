---
name: framework-to-daily-workflow-integration
description: "Embeds abstract strategic frameworks into existing daily/weekly workflow commands as lightweight rituals. Auto-activates when user wants to operationalize a framework, make a concept part of their daily routine, or integrate theory into practice. Trigger keywords: operationalize, daily workflow, make this part of my routine, integrate into morning, daily ritual, weekly audit."
---

## Core Principles

1. **Weight by frequency**: Daily = lightweight (1-2 minutes, 1 question max). Weekly = full audit. Monthly = strategic review.
2. **Embed, don't create**: Add steps to existing commands (`/morning`, `/daily-summary`, `/weekly-review`) rather than creating standalone commands nobody will run.
3. **Data before analysis**: Daily touchpoints generate data. Weekly audit analyzes that accumulated data.

## The Integration Pattern

### Step 1: Identify the Framework's Natural Rhythm

| Timescale | Weight | Integration Point | Purpose |
|-----------|--------|-------------------|---------|
| Daily AM | Light (~2 min) | `/morning` | Set intention, scan signals |
| Daily PM | Light (~2 min) | `/daily-summary` | Review against intention |
| Weekly | Full (~15 min) | `/weekly-review` | Audit patterns, assess system health |

### Step 2: Design the Daily Touchpoints

**Morning (Observe + Orient)**:
- Automated data gathering (no user effort): read yesterday's logs, check active items, scan calendar
- Ask exactly ONE question that sets the day's orientation
- Record answer under a consistent heading (`## [Framework] Morning`)

**Evening (Decide + Act)**:
- Compare morning intention to actual work (aligned/drifted/pivoted)
- Note decisions made (kill/promote/continue/defer)
- Plant one "tomorrow seed" — an observation to carry forward
- Append to Work Log under consistent heading (`[FRAMEWORK] REVIEW`)

### Step 3: Design the Weekly Audit

**Phase A (Evidence Gathering)**:
- Collect all daily touchpoint entries from the week
- Count adoption rate (how many days had entries?)
- Extract patterns: alignment rate, recurring drifts, decisions made

**Phase B (Reflection Writing)**:
- Inner loop: What cycled this week? What was tested, killed, promoted?
- Outer loop: What compounded? Is the compounding thesis still valid?
- System health: Is the framework producing insight or just overhead?

### Step 4: Wire the Data Flow

```
Morning journal entry
    ↓
Evening Work Log section (references morning entry)
    ↓
Weekly evidence brief (aggregates all daily entries)
    ↓
Weekly reflection section (analyzes the aggregate)
```

## Forbidden Patterns

- Creating a standalone `/framework-name` command instead of embedding (won't get run)
- Making daily touchpoints require more than 2 minutes of user interaction
- Weekly audit that only works if every daily entry exists (must degrade gracefully)
- Adding framework steps that duplicate existing command functionality

## Example: OODA Loop

| Command | Addition | Heading |
|---------|----------|---------|
| `/morning` | Step 2.5: Observe signals + ask "What matters most today?" | `## Morning OODA` |
| `/daily-summary` | Step 4.7: Decide/Act review + tomorrow seed | `OODA REVIEW` |
| `/weekly-review` | Phase A step 8 + Phase B OODA Loop Audit section | `## OODA Loop Audit` |
