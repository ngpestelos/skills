---
name: cyclomatic-complexity-reduction
description: "Reduce cyclomatic complexity in Ruby methods via early-return extraction, guard unification, and safe attribute access helpers. Auto-activates when RuboCop flags Metrics/CyclomaticComplexity, refactoring nested conditionals, or reducing CC scores. Trigger keywords: cyclomatic complexity, CC too high, nested conditionals, early return extraction."
allowed-tools: Read, Grep, Glob, Bash
---

# Reducing Cyclomatic Complexity in Ruby Methods

Systematic extraction patterns for reducing CC in Ruby methods flagged by RuboCop `Metrics/CyclomaticComplexity`.

## Core Technique: Guard-Chain to Early-Return Extraction

Replace nested `if/elsif/end` blocks with extracted methods that use early `return` guards.

**Before** (CC=30):
```ruby
def validate_context
  if a.present? && b.present? && a.respond_to?(:store) && a.store.present?
    if b.respond_to?(:dealer_id) && a.store.respond_to?(:dealer_id)
      warnings << "mismatch" unless b.dealer_id == a.store.dealer_id
    elsif b.respond_to?(:dealer) && a.store.respond_to?(:dealer)
      site_id = b.dealer.respond_to?(:id) ? b.dealer.id : nil
      store_id = a.store.dealer.respond_to?(:id) ? a.store.dealer.id : nil
      if site_id && store_id && site_id != store_id
        warnings << "mismatch (fallback)"
      end
    end
  end
end
```

**After** (CC=4 orchestrator + CC=8 helper):
```ruby
def validate_context
  return unless should_validate?
  warnings = [check_a, check_b].compact
  log_warnings(warnings) if warnings.any?
end

def check_a
  return unless a.present? && b.present?
  return unless a.respond_to?(:store) && a.store.present?
  site_id = safe_id(b)
  store_id = safe_id(a.store)
  return unless site_id && store_id
  return if site_id == store_id
  "mismatch"
end
```

## Anti-Pattern: `&.` vs `respond_to?`

**NEVER replace `respond_to?` checks with `&.` (safe navigation) during extraction.** RuboCop `Style/SafeNavigation` actively suggests this, but it's wrong for duck typing.

- `&.` short-circuits on `nil` but raises `NoMethodError` on non-nil objects that lack the method
- `respond_to?(:method)` handles both nil and non-nil objects without the method

```ruby
# WRONG — raises NoMethodError if object is a non-nil that doesn't have :dealer_id
object&.dealer_id

# RIGHT — safe for any object type
object.dealer_id if object.respond_to?(:dealer_id)
```

When chaining through associations, also guard against nil returns: `object.respond_to?(:dealer) && object.dealer && object.dealer.respond_to?(:id)`.

## Extraction Checklist

1. **Identify branches**: Count `if`, `elsif`, `unless`, `&&`, `||`, `?:` — each adds 1 CC
2. **Group by concern**: Each logical check → separate method
3. **Unify access patterns**: Extract `safe_*` helpers for repeated respond_to/ternary chains

## RuboCop CC=8 Tradeoff

Extracted methods with 4+ early-return guards often land at CC=8 (limit 7). This is acceptable when:
- The original method was CC=15+
- Each guard is a single-line early return (maximally readable)
- Further splitting would scatter related logic across too many methods

Document the tradeoff in the commit message rather than contorting code to hit CC=7.

## Discovery Context

- **2026-03-16**: Extracted from `validate_tenant_context` refactoring (CC=30→4) in `BaseValidationStrategy`. RuboCop `Style/SafeNavigation` suggested `&.` but that would break duck-typing safety. Nil dealer association guard caught by code review agent.
