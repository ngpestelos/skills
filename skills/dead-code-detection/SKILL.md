---
name: dead-code-detection
description: "Systematic methodology for identifying orphaned files and dead code after refactoring. Auto-activates when cleaning up after refactoring, verifying old implementations can be safely removed, periodic codebase hygiene, or asking what can be deleted after a feature migration."
allowed-tools: Read, Grep, Glob, Bash
---

# Dead Code Detection

> **CRITICAL**: Always verify BOTH app/ and test/ directories. Code unused in app/ may still be tested.

## Verification Process

Steps 1-2 run in parallel, then Step 3:

**Step 1 — Reference search** (app + test):
Use Grep to search for the filename, partial name, class name, or method across `app/` and `test/` (include `*.erb`, `*.rb`, `*.js`). Exclude self-references. Also check JS imports in `app/javascript/`.

**Step 2 — Git history**:
`git log --oneline --all -5 -- path/to/file` — sanity check for recent activity.

**Step 3 — Dynamic render check + test gate** (MANDATORY for partials):

Use the **Grep tool** (NOT bash grep) to build an exclusion list:
```
Pattern: render.*\#\{
Scope: app/**/*.{erb,rb}
```

For each match targeting `shared/`:
1. Trace the variable to its source (controller method, case statement, model attribute)
2. Enumerate ALL possible values
3. Add `prefix_#{value}` for each value to an exclusion list
4. Partials matching exclusions are NOT orphans — skip them

**Then run the test gate** — even if Step 3 finds no dynamic renders matching a candidate:
1. Trace the candidate partial → parent view → controller action
2. **Run that controller's integration test file before deleting**
3. `Missing partial` error = partial is alive
4. No test file for the rendering path = cannot confirm dead — skip it

> 2026-03-20: Dynamic render check was documented but tests weren't run before committing.
> 4 partials deleted, tests broke. The test gate catches what static analysis misses.

### Common dynamic render sources

| Source | Example | How to enumerate |
|--------|---------|-----------------|
| Controller case statement | `determine_address_partial` → `'one_shipping'` | Read the method |
| Whitelist array | `valid_subtabs = %w[checkout shipping]` | Read the array |
| Model attribute | `shipping_method_type` → `'bulk'` | Check model validations/DB enum |
| User param (unbounded) | `params[:view_type]` | Exclude ALL matching partials |

## Dead Code Patterns

| # | Pattern | Detection | Risk |
|---|---------|-----------|------|
| 1 | Orphaned partials | Reference search → zero matches + dynamic render check + test gate | Low |
| 2 | Replaced helper modules | `grep "include.*Helper" app/helpers/application_helper.rb` | Medium |
| 3 | Old controller actions | `rake routes \| grep controller_name` | Medium |
| 4 | Legacy JS controllers | `grep -r "data-controller.*name" app/views/` (exclude `<%= %>` interpolation) | Low |
| 6 | Obsolete tests after removal | `grep -r "removed-controller" test/` | Low |
| 8 | Orphaned service dependencies | Transitive dependency check (see below) | Medium |
| 9 | Single-purpose services | 1 caller + <25 lines + no test file → inline | Low |
| 12 | Mailer templates | `grep -r "template_name" app/views/ app/mailers/` | Medium |

**Chain detection**: When a file has only 1 reference, check if that parent is also orphaned.

### Pattern 8: Orphaned Dependencies After Service Consolidation

```
OLD: Job -> ServiceA.call -> ServiceB.call -> ServiceC.call
NEW: Job with inlined logic (ServiceA/B/C removed)
MISSED: ServiceC still exists but has zero callers
```

**Transitive dependency check**:
```bash
grep -o "[A-Z][a-zA-Z]*::[A-Z][a-zA-Z]*\.call" "$SERVICE_FILE"
for dep in ServiceB ServiceC; do
  grep -r "$dep" app/ --include="*.rb" | grep -v "$SERVICE_FILE"
done
```

## Commit Format

`Remove dead code: <description>` — include: zero references verified via grep, why it became dead, what replaced it.
