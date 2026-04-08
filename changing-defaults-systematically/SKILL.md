---
name: changing-defaults-systematically
description: "Systematically change configuration defaults and constants while ensuring zero regressions. Auto-activates when changing default values, updating constants, optimizing settings, or modifying hardcoded values. Covers: finding all references, updating code/tests/docs, comprehensive validation, atomic commits. Trigger keywords: change default, update default, modify constant, change configuration, update setting, optimize default, change constant value."
metadata:
  version: 1.0.0
---

# Changing Defaults Systematically

Prevents partial updates — the #1 cause of regressions when changing constants/defaults. Ensures every reference (code, tests, docs, hardcoded literals) is found and updated atomically.

## Workflow

### 1. Identify the Constant

- Find the definition. Note if it's public API or internal.
- Check where it's applied (config logic, defaults, overrides).

### 2. Search for ALL References

Search for both the **constant name** and its **literal value** — hardcoded literals are the most commonly missed:

```bash
grep -r "CONSTANT_NAME" src/ test/
grep -rE '"30m"|'\''30m'\''' src/ test/ docs/
```

### 3. Update in Order

1. **Constant definition** (source of truth)
2. **Config application logic** (where the constant is consumed)
3. **Test expectations** (assertions against the old value)
4. **Documentation** (README, guides, inline comments, examples)

### 4. Validate and Commit

- Run the full test suite (unit + integration).
- Grep for the old literal value to confirm zero remaining references.
- Commit all changes atomically with rationale in the message.

## Forbidden Mistakes

| Mistake | Consequence |
|---------|-------------|
| Skip literal value search | Hardcoded references silently remain |
| Update constant but not tests | Tests fail on next run |
| Update code but not docs | Stale documentation misleads |
| Commit piecemeal | Reviewer misses connections; partial deploy risk |
| Run only unit tests | Integration regressions missed |
