---
name: onboard
description: "Initialize a project with CLAUDE.md, install dependencies, and produce an orientation summary of directory structure and key files. Detects language/framework automatically and skips steps already completed. Auto-activates when onboarding to a new codebase, setting up a project, or generating CLAUDE.md. Trigger keywords: onboard, new project, setup project, CLAUDE.md setup, project orientation, initialize project, codebase setup."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "1.0.1"
---

# Project Onboard

> **Purpose**: Initialize a project with CLAUDE.md, dependencies, and an orientation summary. Skip steps already done.

## Step 1: Validate and Detect

Run in parallel: resolve project path, detect language/framework, check git remote, check for existing CLAUDE.md, check nix config, check dependency state.

If CLAUDE.md exists, nix configured, and dependencies installed → skip to Step 4.

## Step 2: CLAUDE.md Setup

**Exists**: Read it, print 2-line summary, skip to Step 3.

**Missing**: Generate with: Tech Stack table, Development Environment, Common Commands (read actual Gemfile/package.json/Makefile — don't guess), Project Structure. Present to user, write on confirmation.

## Step 3: Dependencies

If not installed, present install commands. If no nix config, ask if user wants one.

## Step 4: Orientation

1. **Directory structure** — top-level with 1-line annotations
2. **Key files** — 5-7 files for fastest understanding (entry points: routes, main, index, cmd/)
3. **Recent activity** — `git log --oneline -10`
