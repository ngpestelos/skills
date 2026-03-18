---
name: changing-defaults-systematically
description: "Systematically change configuration defaults and constants while ensuring zero regressions. Auto-activates when changing default values, updating constants, optimizing settings, or modifying hardcoded values. Covers: finding all references, updating code/tests/docs, comprehensive validation, atomic commits. Trigger keywords: change default, update default, modify constant, change configuration, update setting, optimize default, change constant value."
metadata:
  version: 1.0.0
---

# Skill: Changing Defaults Systematically

## Overview

A systematic approach to changing configuration defaults and constants while ensuring zero regressions. Auto-activates when users request changes to default values, constants, or configuration settings.

**Problem it solves:**
- Developers often change constants/defaults without updating all usages
- Tests fail unexpectedly because expectations weren't updated
- Documentation becomes stale when defaults change
- No systematic approach to finding all references

**Pattern:**
A 5-step validation approach that ensures comprehensive updates across code, tests, and documentation.

## Core Principles

1. **Find All References** - Use grep/search to locate every usage of the constant name and literal value
2. **Update Atomically** - Change definition, usages, tests, and documentation together in a single commit
3. **Validate Comprehensively** - Run full test suite to catch regressions before committing
4. **Document Rationale** - Explain why the change was made and what impact it has

## Required Workflow

### Step 1: Identify the Constant/Default

- Find the constant definition in the codebase
- Note whether it's exported (public API) or internal
- Check if it's used in config application logic or defaults

### Step 2: Search for All References

Search for both the constant name AND its literal value:

```bash
# Find constant name references
grep -r "CONSTANT_NAME" src/

# Find literal value references (e.g., "30m")
grep -r '"30m"' src/
grep -r "'30m'" src/

# Check test files specifically
grep -r "30m" test/
grep -r "30m" __tests__/
```

### Step 3: Update All Locations

Update these in order:

1. **Core constant definition** - The exported constant or config default
2. **Config application logic** - Where the constant is used to set actual configuration
3. **Test expectations** - Any tests that assert against the old value
4. **Documentation** - README files, guides, inline comments, examples

### Step 4: Comprehensive Testing

```bash
# Run full test suite (adjust for your project)
npm test
pytest
cargo test
```

### Step 5: Atomic Commit

Create a single commit with all related changes:

```bash
git add -A
git commit -m "perf(component): optimize default X from Y to Z

Rationale: [explain why the change improves performance/behavior]

Updated:
- Constant definition
- Config application logic
- Test expectations
- Documentation"
```

## Forbidden Mistakes

- Change constant without updating tests -> tests fail
- Update tests without updating docs -> stale documentation
- Change one location but miss others -> inconsistent behavior
- Run only unit tests -> integration issues missed
- Commit changes piecemeal -> hard to review, easy to miss connections
- Forget to search for literal values -> hardcoded references remain

## Validation Checklist

Before committing, verify:

- [ ] Constant definition updated
- [ ] All code usages updated (grep shows no old references)
- [ ] Test expectations updated (grep for old value in test files)
- [ ] Documentation updated (README, guides, inline docs)
- [ ] Full test suite passes
- [ ] No hardcoded old values remain (searched for literal old value)
- [ ] Commit message includes rationale for change

## Integration

**Works with:**
- `/commit` - Use after making changes to create atomic commit

**Auto-activation triggers:**
User requests like:
- "Change the default X from Y to Z"
- "Update the timeout to 30 seconds"
- "Optimize the default interval"
- "Modify the DEFAULT_TIMEOUT constant"
