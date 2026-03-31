---
name: commit-workflow
version: 1.0
description: "Organize uncommitted changes into atomic git commits with scope awareness. Auto-activates when committing changes, organizing commits, or preparing pushes. Trigger keywords: commit, git commit, atomic commit, push changes, organize commits."
allowed-tools: Read, Grep, Glob, Bash
---

# Commit Workflow

> **Purpose**: Commit in-scope files as atomic commits, confirm before including out-of-scope files, then push.

## Step 1: Analyze & Scope

Run in parallel: `git status`, `git log --oneline -5`.

Determine scope:
1. Build file list from Edit/Write tool calls in the current session
2. If no Edit/Write calls found (manual changes), treat all files as in-scope
3. If out-of-scope files exist in the working tree, list them and confirm before including

## Step 2: Create Atomic Commits

Group related files and for each group:
1. `git add` only relevant files (never `git add .` or `-A`)
2. Commit with heredoc format, imperative mood, <=50 char subject, explain "why" not "what"
3. Include `Co-Authored-By` line for the current model

## Step 3: Push

`git log --oneline -N` (N = new commits), then `git push`.

## Rules

- Never commit sensitive data, large binaries, or temp files (.DS_Store, .swp)
- Never commit out-of-scope files without user confirmation
