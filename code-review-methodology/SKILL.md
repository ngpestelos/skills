---
name: code-review-methodology
description: "Code review methodology for uncommitted changes. Priority framework and scope constraint. References security-patterns skill for detailed checklist. Trigger keywords: code review, review changes, PR review, uncommitted changes, git diff, convention check."
---

# Code Review Methodology

Review uncommitted changes (`git diff HEAD`) against project conventions.

**Review ONLY uncommitted changes.** Never flag pre-existing issues. Only files in `git status`, only changed lines in `git diff HEAD`.

For security patterns (XSS, CSRF, PII, SQL injection, multi-tenant), use the `security-patterns` skill.

## Priority Framework

| Priority | Examples |
|----------|---------|
| **CRITICAL** (fix now) | XSS, PII logging, CSRF missing, tenant isolation breach, SQL injection |
| **HIGH** (fix before deploy) | Console statements, hardcoded URLs, framework violations, nil guards |
| **MEDIUM** (tech debt) | N+1 queries, memory leaks, missing error handling |
| **LOW** (quality) | Style/formatting, POSIX newlines, code organization |

## Optimization History

- **March 13, 2026**: Five-step optimizer pass 1. 245 → 80 lines (68%).
- **March 23, 2026**: Five-step optimizer pass 2. 80 → 37 lines (54%).
- **April 1, 2026**: Five-step optimizer pass 3. Deleted security checklist (duplicates security-patterns skill). 37 → 14 lines (62%).
