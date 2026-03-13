---
name: claude-code-command-optimizer
description: Expertise in designing, debugging, and optimizing Claude Code custom commands for reliability within LLM constraints. Activates when troubleshooting stalling commands, optimizing long-form generation, designing complex workflows, enhancing commands with script extraction, fixing shell compatibility issues, replacing manual tracking with git-based context detection, modifying command defaults with backward compatibility, splitting commands into agent-delegated phases with handoff documents, reducing context window exhaustion, batching Edit operations, embedding stable reference frameworks, or reducing command token cost via mechanical trimming.
license: MIT
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Claude Code Command Optimizer

## Command Architecture Patterns

#### Pattern 1: Incremental Generation (Long-Form Content)
Commands generating 800-1,500+ lines timeout during Write. **Fix**: Write skeleton (~100-200 lines) with headers/placeholders, then Edit each section sequentially (~100-200 lines each).

#### Pattern 2: TodoWrite Progress Tracking
For multi-phase commands, create todo list tracking all phases. Mark each in_progress → completed. User sees real-time progress instead of silence.

#### Pattern 3: Phased Command Architecture
1. **Evidence Gathering**: Read-only ops (Grep, Glob, Read, Bash) — parallel where independent
2. **Analysis**: Process gathered data, identify patterns
3. **Generation**: Write once (skeleton), Edit multiple times (sections)
4. **Verification**: Quality checks and validation

#### Pattern 4: Script Extraction (November 2025)
Extract reusable bash logic into `.claude/bin/` scripts. **Shell compatibility**: use parameter expansion (shell-agnostic), not bash-specific regex (`[[ =~ ]]` / `BASH_REMATCH`). Use `case` + `${var#pattern}` instead.

#### Pattern 5: Git-Based Context Detection (November 2025)
Replace manual self-reporting with `git log --since="[timestamp]"` analysis. Parse commit count, timing, categories, themes, file types. Detect intensity signals (hyperfocus, late-night, sustained bursts). Dynamic time windows since last checkpoint.

#### Pattern 6: Git-Based Learning Systems (November 2025)
Extract learning from git history: Understand (Month 1) → Improve (Month 2-3) → Measure (Month 4-6) → Predict (Month 7+). Git as single source of truth, simple markdown reports.

#### Pattern 7: Default Behavior Modification (January 2026)
Change defaults while preserving previous behavior via explicit opt-in flags. `(no args)` → new default, explicit subcommand → unchanged. Update all: usage examples, subcommands, options, default instruction, implementation.

#### Pattern 8: Multi-Output Consistency (February 2026)
Commands creating local state + external tracking (Basecamp, GitHub) should sync both automatically. Local file = source of truth, external sync failure doesn't block, manual sync exists as recovery.

#### Pattern 9: Command Scope Reduction (February 2026)
**Signal**: Users "rarely use" it despite valuable concept, >200 lines, >3 menu options, metadata nobody acts on. **Fix**: Narrow data source, show content directly, remove numbered menus, delegate to specialized commands.

#### Pattern 10: Agent-Delegated Phase Splitting (February 2026)
When context exceeds 50% before writing begins: **Phase A** (subagent) gathers evidence → writes structured brief to temp file. **Phase B** (main session) reads brief + generates output in 3 batched Edits. Delete temp brief after.

#### Pattern 11: Command-Skill Delegation / Thin Orchestrator (February 2026)
Commands with inline methodology duplicating skill content → restructure as thin orchestration (what to do), skills define methodology (how). Replace inline content with skill links. **Target**: command ~150-200 lines, over 300 = extract more.

#### Pattern 12: Command Token Reduction Checklist (March 2026)
**Sections to cut**: Purpose (restates header), Execution (default behavior), Usage/Best-used-when (filler), Common Patterns (LLM infers), output templates, rules redundant with global CLAUDE.md, user-facing docs in agent commands.

**Compression**: Sub-header sections → inline bullets. Multi-paragraph → single sentence. Do/Don't lists → consolidated Rules. **Benchmark**: 40-87% reduction typical.

## Stalling Command Diagnostic

1. **Identify stall point** — timeout phase, expected output length
2. **Check structure** — single large Write (red flag >500 lines), missing TodoWrite, sequential-only calls
3. **Measure**: 800 lines ≈ safe, 1,500 ≈ risky, 2,000+ ≈ likely timeout
4. **Route to pattern**: Token limit → P1, slow gathering → parallelize, no progress → P2, context exhaustion → P10
