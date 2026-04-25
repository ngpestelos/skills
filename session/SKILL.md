---
name: session
description: "Structured dump of the current conversation session — files read and written, searches performed, tools invoked, agents spawned, and open items. Omits empty sections for a concise overview. Auto-activates when asking for session summary, context dump, or what tools were used. Trigger keywords: session, session context, session dump, what did we do, files touched, session summary, tools used, context dump."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Session Context

> **Purpose**: Structured summary of the current conversation session — files, searches, tools, and topics. Complementary to session-recap (which covers history before this session).

## Steps

Scan conversation history and generate:

| Section | Content |
|---------|---------|
| Session focus | 1-sentence summary of primary activity |
| Files Read | Paths with line ranges if partial |
| Files Written/Edited | Paths, created vs edited |
| Searches | WebSearch queries, Grep patterns, Glob patterns |
| Skills/Commands Invoked | Any Skill tool calls |
| Agents Spawned | Type, description, status |
| Bash Commands | Count (standard) or full list (verbose) |
| Key Topics | File names, concepts, entities discussed |
| Open Items | Unanswered questions, unfinished work |

Omit empty sections. Concise, scannable.
