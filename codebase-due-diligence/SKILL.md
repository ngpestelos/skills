---
name: codebase-due-diligence
description: Phased methodology for understanding unfamiliar codebases, from rapid onboarding to comprehensive technical analysis. Produces actionable knowledge documents and feeds reusable patterns to technical-pattern-extractor. Auto-activates when joining new projects, conducting technical due diligence, or exploring unfamiliar codebases. Trigger keywords: new codebase, onboarding, due diligence, technical assessment, understand codebase, explore project, architecture review, codebase analysis, unfamiliar project, ramp up, getting started. (project)
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Codebase Due Diligence

Systematic exploration of unfamiliar codebases producing actionable knowledge. Get it running first, understanding follows.

## Steps

### Step 1: Reconnaissance

Find and read in priority order:

| Priority | File Pattern | Purpose |
|----------|--------------|---------|
| Critical | README.md, CLAUDE.md, `.claude/`, `.cursor/` | Project overview, setup, AI-specific conventions |
| Critical | Directory structure, entry points | Mental model, where execution starts |
| High | Config files (Gemfile, package.json, etc.) | Dependencies, framework detection |
| High | Test location | Executable specification — tests reveal behavior faster than code |
| Medium | CI/CD config | Quality gates, deployment |

### Step 2: Environment Setup

Get it running. If blocked > 30 min on any step, document what you tried and ask for help.

### Step 3: Architecture & Convention Mapping

Map: directory-to-responsibility, request lifecycle, core data models/relationships, dependency graph (internal + external). Sample 3-5 recent files/commits for style, test patterns, error handling, and linter config.

### Step 4: Risk Zone Classification

| Zone | Characteristics |
|------|-----------------|
| **Safe (Green)** | High test coverage, isolated, well-documented (utilities, presenters, serializers) |
| **Moderate (Yellow)** | Some coverage, has dependencies (business logic, controllers, services) |
| **Danger (Red)** | Low coverage, core infrastructure, cascading deps (auth, payments, migrations) |

Check: test coverage %, technical debt markers (TODO/FIXME/HACK), security vulnerabilities, bus factor (git blame).
