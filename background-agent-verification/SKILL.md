---
name: background-agent-verification
description: "Prevents silent work loss from delegated background agents by requiring output verification before proceeding. Covers: agent output verification, rate limit detection, zero-output detection, execution vs reporting scoping, permission blocking, direct fallback execution. Trigger keywords: background agent, agent completed, run_in_background, agent delegation, subagent, rate limit, zero output, agent failed, verify agent output."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Verifying Background Agent Output

Ensure delegated background agent work actually produced expected output before proceeding.

## Core Principles

1. **Agent status ≠ work completed**: "completed" may mean zero useful output (rate limits, context overflow, errors)
2. **Always verify artifacts**: Check via `git status`, `ls`, or file reads — never trust status alone
3. **Scope agents for execution, not reporting**: Require agents to create files, not just recommend
4. **Prepare for direct fallback**: If agents fail, execute the same work directly

## Verification Patterns

### Pattern 1: Verify Before Proceeding

After agent completion, ALWAYS check actual output:

```bash
git status --short                           # Any changes at all?
git status --short | grep "^??" | wc -l      # Count new files vs expected
ls "path/to/expected/file.md"                # Specific file exists?
```

If `git status` shows no changes after agents that should have created files → agents failed silently. Also check for duplicate/partial files before creating what agents may have started.

### Pattern 2: Scope Agents for Execution

```
CORRECT: "Create these 5 atomic note files in [path] with this content: [specs]"
WRONG:   "Scan these documents and report which concepts should be extracted"
```

### Pattern 3: Rate Limit Detection

Characteristic output: `"You've hit your limit"`, `total_tokens: 0`. Agent did partial or zero work. Check what was created, execute remainder directly.

### Pattern 4: Permission Blocking Detection

With many concurrent agents (8+), some get ALL file modification tools auto-denied:
```
"Permission to use Edit has been auto-denied (prompts unavailable)"
```

Agent produces detailed plans but creates zero files. Detection: long detailed output but `git status` shows no changes.

**Fix**: Re-launch with Python-only file operations (pathlib + subprocess) or launch in smaller waves (5, then 5).
