---
name: codebase-explorer
description: "Interactive exploration of onboarded codebases for understanding architecture, conventions, and patterns. Supports ongoing Q&A across sessions, guided walkthroughs of key subsystems, and pattern extraction to vault. Complements /onboard (setup) and codebase-due-diligence (one-shot assessment). Trigger keywords: explore codebase, how does X work, where does Y live, walk me through, architecture question, code walkthrough, understand this project, explain this module, contribution guide, good first issue. (global)"
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit
---

# Codebase Explorer

Interactive Q&A for understanding onboarded codebases. Use after `/onboard` has set up CLAUDE.md.

## Modes

### Mode 1: Question (default)

User asks about the codebase. Answer by reading actual code, not guessing.

1. Parse the question into a search strategy (file patterns, grep terms, entry points)
2. Search in parallel: Glob for file patterns + Grep for key terms
3. Read the relevant files (prioritize: entry points, config, tests over implementation)
4. Answer with file paths and line numbers. Quote sparingly. Explain the *why*, not just the *what*.

Common questions and where to look:

| Question type | Start here |
|--------------|------------|
| "How does X work?" | Routes/entry point → controller/handler → service/model |
| "Where does Y live?" | Glob for filenames, Grep for class/module definitions |
| "What pattern does this use for Z?" | Grep for Z-related terms, read 2-3 examples, name the pattern |
| "How do I test here?" | Read test/ or spec/ structure, find a representative test, describe conventions |
| "What are the conventions?" | Linter config, CLAUDE.md, sample 3 recent PRs/commits |

### Mode 2: Walkthrough

User asks to walk through a subsystem. Produce a guided reading order.

1. Identify the subsystem boundary (directory, module, namespace)
2. Map the dependency graph within the subsystem (what calls what)
3. Present a reading order: start with the public interface, then internals, then tests
4. For each file in the reading order: 1-2 sentence summary of its role + key line numbers

Format:
```
## [Subsystem Name] Walkthrough

**Entry point**: `path/to/file.rb:42` — [what it does]
**Core logic**: `path/to/service.rb` — [what it does]
**Data layer**: `path/to/model.rb` — [what it does]
**Tests**: `test/path/to/test.rb` — [what the tests reveal about behavior]

### Reading order
1. Start at [entry point] — this is where requests arrive
2. Follow to [service] — this is where decisions happen
3. Check [model] — this is the data contract
4. Read [test] — this confirms your understanding
```

### Mode 3: Contribution Readiness

User wants to contribute. Assess readiness and find entry points.

1. Read CONTRIBUTING.md, .github/ templates, PR conventions
2. Identify: test framework, CI requirements, code style (linter config), branch strategy
3. Find good first contributions: grep for `TODO`, `FIXME`, `HACK`; check GitHub issues labeled `good-first-issue` or `help-wanted` if accessible
4. Present a contribution checklist:
   - [ ] Can run tests locally
   - [ ] Understand branch/PR conventions
   - [ ] Identified a specific change to make
   - [ ] Know which tests to add/modify

### Mode 4: Pattern Extraction

User identifies a reusable pattern during exploration. Bridge to `technical-pattern-extractor`.

1. Name the pattern and describe it in one sentence
2. Show 2-3 instances in the codebase that demonstrate it
3. Assess: is this project-specific or generalizable?
4. If generalizable, invoke `technical-pattern-extractor` skill to create dual output (vault note + skill file)

## Rules

- Always read code before answering. Never guess file locations or API shapes.
- Prefix uncertain claims with [Inference]. If you can't find it in code, say so.
- When the project has a CLAUDE.md, read it first for project-specific conventions.
- Save discoveries to project memory automatically when they reveal non-obvious architecture decisions.
- Keep answers focused. A codebase exploration answer should be 5-15 lines, not an essay. Point to files, let the user read.
