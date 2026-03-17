---
name: dead-code-detection
description: "Systematic methodology for identifying orphaned files and dead code after refactoring. Auto-activates when cleaning up after refactoring, verifying old implementations can be safely removed, periodic codebase hygiene, or asking what can be deleted after a feature migration."
allowed-tools: Read, Grep, Glob, Bash
---

# Dead Code Detection

> **CRITICAL**: Always verify BOTH app/ and test/ directories. Code unused in app/ may still be tested.

## Verification Process

Steps 1-2 can run in parallel, then Step 3:

**Step 1 — Reference search** (app + test):
Use Grep to search for the filename, partial name, class name, or method across `app/` and `test/` (include `*.erb`, `*.rb`, `*.js`). Exclude self-references. Also check JS imports in `app/javascript/`.

**Step 2 — Git history**:
Check `git log --oneline --all -10 -- path/to/file` for recent activity and `git log -1 --format="%ai %an"` for last author.

**Step 3 — Dynamic render enumeration** (MANDATORY):

> Discovered 2026-03-14: Deleted 93 "orphaned" partials; tests broke because 18 were
> rendered via `"shared/prefix_#{variable}"`. Shell-level grep silently failed on `\#{`.

Use the **Grep tool** (NOT bash grep) to find all dynamic renders:
```
Pattern: render.*partial.*\#\{
Scope: app/**/*.{erb,rb}
```

For each match targeting `shared/`:
1. Trace the variable to its source (controller method, case statement, model attribute)
2. Enumerate ALL possible values
3. Add `prefix_#{value}` for each value to an exclusion list
4. Partials matching exclusions are NOT orphans — skip them

### Common dynamic render sources

| Source | Example | How to enumerate |
|--------|---------|-----------------|
| Controller case statement | `determine_address_partial` → `'one_shipping'` | Read the method |
| Whitelist array | `valid_subtabs = %w[checkout shipping]` | Read the array |
| Model attribute | `shipping_method_type` → `'bulk'` | Check model validations/DB enum |
| User param (unbounded) | `params[:view_type]` | Exclude ALL matching partials |

## Dead Code Patterns

> **11 Production-Verified Patterns** — detection command is in each row.

| # | Pattern | Detection | Risk |
|---|---------|-----------|------|
| 1 | Orphaned partials after migration | `grep -r "partial_name" app/ test/` → zero matches | Low |
| 2 | Replaced helper modules | `grep "include.*Helper" app/helpers/application_helper.rb` | Medium |
| 3 | Old controller actions | `rake routes \| grep controller_name` | Medium |
| 4 | Legacy JS controllers | `grep -r "data-controller.*name" app/views/` (exclude `<%= %>` interpolation) | Low |
| 5 | Deprecated test files | `find test/views/ -name "*_test.rb"` | Low |
| 6 | Obsolete tests after removal | `grep -r "removed-controller" test/` | Low |
| 8 | Orphaned service dependencies | Transitive dependency check (see below) | Medium |
| 9 | Single-purpose services | 1 caller + <25 lines + no test file → inline | Low |
| 10 | Test env bypass masking failures | `grep -r "Rails.env.test?" app/controllers/` | High |
| 11 | Never-integrated partials | Only self-references; only creation commit in git log | Low |
| 12 | Mailer templates | `grep -r "template_name" app/views/ app/mailers/` | Medium |

**Pattern 1 chain detection**: When a file has only 1 reference, check if that parent is also orphaned.

```bash
# Search by partial NAME, not filename.
for file in app/views/shared/_*.html.erb; do
  name=$(basename "$file" .html.erb | sed 's/^_//')
  count=$(grep -r "$name" app/ test/ --include="*.erb" --include="*.rb" --include="*.js" | grep -v "^$file:" | wc -l)
  [ "$count" -eq 0 ] && echo "ORPHAN: $name"
done
```

**Pattern 11 vs Pattern 1**: Pattern 1 = previously used, became orphaned (git log shows active usage). Pattern 11 = never used (only creation commit exists).

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

### Pattern 10: Test Environment Bypass

`grep -r "Rails.env.test?" app/controllers/ --include="*.rb" -A5`

**Red flags**: Test-specific CSS classes in assertions, missing partial dependencies, 4+ years without updates, `rescue StandardError` bypass.

## Commit Format

`Remove dead code: <description>` — include: zero references verified via grep, why it became dead, what replaced it.
