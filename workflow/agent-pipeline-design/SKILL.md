---
name: agent-pipeline-design
description: "Architectural patterns for multi-phase agent pipelines that survive context limits, delegate safely, and gate on quality. Applies when designing skills that orchestrate plan→execute→review flows."
version: 1.1.0
---

# Designing Agent Pipelines

Patterns for building multi-phase autonomous pipelines where an orchestrator skill
delegates heavy work to subagents while preserving its own context for coordination.

## Core Architecture: Inline vs Subagent

Every phase must be classified:

| Phase type | Run as | Why |
|---|---|---|
| Needs orchestrator judgment (plan creation, file exploration) | Inline | Requires accumulated context from earlier reads |
| Heavy execution (implementation, test suites) | Subagent | Preserves orchestrator context window |
| Adversarial review (red-team, code review) | Subagent | Fresh context = no implementation bias |
| Lightweight coordination (PR creation, state updates) | Inline | Needs results from all prior phases |

## Delegation via claude -p

When an upstream agent (cron, webhook, parent process) invokes Claude Code:

```bash
claude -p "Read .claude/skills/<skill>/SKILL.md and follow its instructions for: <task>" \
  --allowedTools '<scoped list>' \
  --cwd <project root>
```

Three non-negotiable constraints:
1. **Explicit skill read** — `-p` mode does not auto-discover skills from context
2. **Scoped permissions** — enumerate specific `Bash(cmd:*)` patterns, never `Bash(*)`
3. **`--cwd` at repo root** — subagents inherit root skills only when launched from root

## State Management

One state file per pipeline, not per phase:
- Write state only after the first phase produces something worth resuming from
- Track `current_phase` (not per-phase status objects) — simpler resume logic
- Read upstream tool state as read-only — never extend another tool's state file

## Skill-to-Skill Delegation

Skills are instructions, not executable code. To invoke one skill from another:
- For subagent phases: include "Read `.claude/skills/<name>/SKILL.md` and execute it" in the Agent tool prompt
- For inline phases: read the skill file and follow its steps directly
- Pass plan/data content directly in the prompt — but skill files can be read by the agent (they're stable references, not session-specific data)
- Reviewer agents report only. The orchestrator decides whether to fix — never give the reviewer write access.

Avoid keyword routing tables for subproject detection — they go stale as the codebase evolves. Prefer explicit naming (e.g., "in <subproject-name>") or path inference.
