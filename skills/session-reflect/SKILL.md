---
name: session-reflect
version: 1.0
description: "Summarize the current conversation session to answer 'where were we?' after interruptions or complex threads. Auto-activates when reflecting on session, asking where we left off, or needing orientation. Trigger keywords: reflect, where were we, session summary, what were we doing."
allowed-tools: Read, Grep, Glob, Bash
---

# Session Reflect

> **Purpose**: Answer "Where were we?" by summarizing the current conversation session.

## Steps

Review conversation history and provide:

1. **Current Context**: What are we working on right now?
2. **Key Points**: Main topics, problems, or themes covered
3. **Progress Made**: What's been accomplished or decided
4. **Next Steps**: What we were about to do or still need to address
5. **Open Questions**: Unresolved items or pending decisions

Keep conversational and focused — no document creation, just orientation.
