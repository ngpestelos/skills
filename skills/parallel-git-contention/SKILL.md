---
name: parallel-git-contention
description: "Prevents silent incomplete staging when parallel agents run concurrent git operations (git rm, git add, git mv). Auto-activates when spawning multiple agents that modify git-tracked files. Trigger keywords: parallel agents git, concurrent git rm, incomplete staging, git index lock, batch git operations, parallel file deletion."
---

# Parallel Git Index Contention

When multiple agents run `git rm`, `git add`, or `git mv` concurrently, git's index lock causes most operations to silently fail. Only the agent that acquires the lock succeeds per cycle.

## The Problem

**Incident**: Mar 23, 2026 — 5 parallel agents each ran `git rm` on ~12K files (60K total). Only ~3K were staged. The 57K remaining files were deleted from disk but NOT from git index. Required a single-threaded `git rm --force` cleanup pass to fix.

**Root cause**: Git uses `.git/index.lock` — only one process can write the index at a time. Concurrent `git rm` calls that fail to acquire the lock exit silently (returncode 0, no stderr) rather than retrying.

## Rules

1. **Never run git write operations from parallel agents.** Agents should only read/write files on disk. All git staging (`git rm`, `git add`, `git mv`) must happen in the main session AFTER agents complete.

2. **Pattern**: Agents do file I/O → main session does git operations sequentially.

3. **For bulk deletions**: Use Python `pathlib.unlink()` in agents, then `git add -u <directory>` once in main session.

4. **For bulk creates/moves**: Agents write files, main session runs `git add` on the output directory.

5. **Verification**: After any parallel agent batch, run `git status --short | wc -l` to confirm expected staging count before committing.

## Anti-Pattern

```python
# WRONG: git rm inside parallel agent
subprocess.run(['git', 'rm', '--quiet'] + batch, ...)
```

```python
# RIGHT: unlink in agent, git add -u in main session
for f in files: f.unlink()
# Then in main session: git add -u "2 Resources/Readwise/Highlights/"
```

## Optimization History

- **March 23, 2026**: Created from batch highlight compilation session. 5 agents, 60K files, only 3K staged.
