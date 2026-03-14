---
name: dead-code-detection
description: "Systematic methodology for identifying orphaned files and dead code after refactoring. Auto-activates when cleaning up after refactoring, verifying old implementations can be safely removed, periodic codebase hygiene, or asking what can be deleted after a feature migration."
license: MIT
compatibility: Ruby on Rails applications. Detection commands assume standard Rails directory structure.
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Dead Code Detection

> **CRITICAL**: Always verify BOTH app/ and test/ directories. Code unused in app/ may still be tested.

## Five-Step Verification Process

```bash
# Step 1: Reference Search (App Code)
grep -r "partial_name" app/ --include="*.erb" --include="*.rb"
grep -r "import.*filename" app/javascript/ --include="*.js"

# Step 2: Reference Search (Test Code)
grep -r "filename\|method_name" test/ --include="*.rb"

# Step 3: Git History Analysis
git log --oneline --all -10 -- path/to/file
git log -1 --format="%ai %an" -- path/to/file

# Step 4: Working Directory vs Committed State
git show HEAD:path/to/file

# Step 5: Dynamic Reference Check
grep -r "render.*\#{" app/views/ | grep "partial_name"
```

## Risk Assessment

| Risk Level | Characteristics | Action |
|------------|----------------|--------|
| **High** | Customer-facing, checkout, payments, emails | Extensive testing + manual verification |
| **Medium** | Multi-namespace usage, shared partials | Verify each context separately |
| **Low** | Zero references in app/ and test/, recent migration | Safe to remove after verification |

### Common False Positives (NOT Dead Code)

1. **Different Namespace**: `admin/_partial` vs `public/_partial`
2. **Dynamic Renders**: Partial name built via string interpolation
3. **External References**: Used by API, webhooks, or external services
4. **Mailer Templates**: May not appear in standard partial searches

## Dead Code Patterns

> **10 Production-Verified Patterns** covering orphaned partials, replaced helpers, unreachable actions, legacy JavaScript, deprecated tests, obsolete tests, orphaned service dependencies, service inlining, test environment bypass, and never-integrated partials.

### Quick-Reference Pattern Table

| # | Pattern | Detection | Risk |
|---|---------|-----------|------|
| 1 | Orphaned partials after migration | `grep -r "partial_name" app/ test/` → zero matches | Low |
| 2 | Replaced helper modules | `grep "include.*Helper" app/helpers/application_helper.rb` | Medium |
| 3 | Old controller actions | `rake routes \| grep controller_name` | Medium (check logs) |
| 4 | Legacy JS controllers | `grep -r "data-controller.*name" app/views/` | Low |
| 5 | Deprecated test files | `find test/views/ -name "*_test.rb"` | Low |
| 6 | Obsolete tests after removal | `grep -r "removed-controller" test/` | Low |
| 8 | Orphaned service dependencies | Transitive dependency check (see below) | Medium |
| 9 | Single-purpose services | 1 caller + <25 lines + no test file → inline | Low |
| 10 | Test env bypass masking failures | `grep -r "Rails.env.test?" app/controllers/` | High |
| 11 | Never-integrated partials | Only self-references; only creation commit in git log | Low |

**Pattern 1 chain detection**: When a file has only 1 reference, check if that parent is also orphaned.

```bash
for file in app/views/shared/_*.html.erb; do
  filename=$(basename "$file")
  count=$(grep -r "$filename" app/ test/ | wc -l)
  echo "$filename: $count references"
done
```

**Pattern 11 vs Pattern 1**: Pattern 1 = previously used, became orphaned (git log shows active usage). Pattern 11 = never used (only creation commit exists).

### Pattern 8: Orphaned Dependencies After Service Consolidation

Services removed during refactoring but their dependencies overlooked.

```
OLD: Job -> ServiceA.call -> ServiceB.call -> ServiceC.call
NEW: Job with inlined logic (ServiceA/B/C removed)
MISSED: ServiceC still exists but has zero callers
```

**Transitive dependency check**:
```bash
# Find all service calls within service being removed
grep -o "[A-Z][a-zA-Z]*::[A-Z][a-zA-Z]*\.call" "$SERVICE_FILE"

# Check if each dependency has other callers
for dep in ServiceB ServiceC; do
  grep -r "$dep" app/ --include="*.rb" | grep -v "$SERVICE_FILE"
done
```

### Pattern 10: Test Environment Bypass Masking Production Failures

Controller actions using `if Rails.env.test?` to provide simplified output while production path renders broken templates.

```bash
grep -r "Rails.env.test?" app/controllers/ --include="*.rb" -A5
```

**Red flags**: Test-specific CSS classes in assertions, missing partial dependencies, 4+ years without updates, `rescue StandardError` bypass.

## Detection Commands Library

### By File Type

```bash
# Partials
grep -r "render.*partial.*'shared/partial_name'" app/ test/
grep -r "render.*partial.*\#{" app/views/  # Dynamic renders

# Helpers
grep -l "module.*Helper" app/helpers/*.rb
grep -r "helper_method_name" app/views/ app/helpers/

# Controllers
rake routes | grep controller_name
grep -r "controller_name#action_name" app/ config/

# JavaScript
grep -r "import.*filename" app/javascript/
grep -r "data-controller.*controller-name" app/views/
```

### Git History

```bash
git log --oneline --all -10 -- path/to/file
git log -1 --format="%ai %an" -- path/to/file
git log --all --full-history -- path/to/file  # Find deletion
```

### Full Codebase Search

```bash
grep -r "filename" app/ test/ doc/ --include="*.rb" --include="*.erb" --include="*.js"
```

## Commit Format

`Remove dead code: <description>` — include: zero references verified via grep, why it became dead, what replaced it.
