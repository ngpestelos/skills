---
name: model-method-memoization-view-performance
description: "Memoize model methods called multiple times per object during view rendering to reduce Ruby CPU and memory allocations. Auto-activates when performance traces show high render_template with fast SQL queries, allocation count >50k with query count <100, investigating views-slow-but-queries-fast scenarios, or working with @var ||= vs defined?(@var) patterns."
license: MIT
compatibility: Ruby on Rails applications with view rendering performance issues.
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Memoizing Model Methods for View Performance

> **When to suspect this**: SQL queries are fast (<100ms each) but `render_template.action_view` is slow (5+ seconds) with high allocations (50k+). This is a **Ruby CPU/memory issue**, not a database issue.

## Quick Decision Tree

| Scenario | Pattern |
|----------|---------|
| Method always returns truthy | `@var ||= compute_method` |
| Method can return nil/false | `return @var if defined?(@var); @var = compute_method` |
| Method takes arguments | `@cache ||= {}; @cache[arg] ||= compute(arg)` |
| Method called 3+ times in one caller | Store in local variable |
| Method creates objects (Struct, Array) | Memoize or use frozen constant |
| Method called in view loops | Must be memoized |
| Method uses `begin` block with `||=` | Never use `return` — use if/else expressions |

## Required Patterns

### Pattern 1: Simple Memoization (`@var ||=`)

For methods that always return truthy values. Extract computation to `compute_` method.

```ruby
def preferred_image
  @preferred_image ||= compute_preferred_image
end

private

def compute_preferred_image
  # conditional chain here
end
```

### Pattern 2: Nil-Safe Memoization (`defined?`)

**Why `||=` fails**: If method returns `nil`, `@var ||= compute()` recomputes every time.

```ruby
def default_image
  return @default_image if defined?(@default_image)
  @default_image = compute_default_image
end
```

### Pattern 3: Hash-Based Memoization (methods with arguments)

```ruby
def fallback_urls_for(style = :large)
  @fallback_urls_cache ||= {}
  @fallback_urls_cache[style] ||= compute_fallback_urls_for(style)
end
```

### Constant Extraction for Static Objects

```ruby
# WRONG: Creates new Struct on every call
def fallback_image
  Struct.new(:large_url, :thumb_url).new('/not_available.jpg', '/not_available_th.jpg')
end

# RIGHT: Frozen constant
FALLBACK_IMAGE = Struct.new(:large_url, :thumb_url).new(
  '/not_available.jpg', '/not_available_th.jpg'
).freeze
```

## Critical Anti-Pattern: `return` Inside `begin` Block Defeats `||=`

```ruby
# WRONG: return exits method entirely, bypassing ||= assignment
# @_cached stays nil — block re-executes on every call
def expensive_lookup
  @_cached ||= begin
    return Set.new unless feature_enabled?     # exits method, no assignment!
    record = Model.find_by(slug: slug)
    return Set.new if record.nil?              # exits method after DB query!
    Set.new(record.items.pluck(:id))
  end
end

# RIGHT: Use conditional expressions so begin always evaluates to a value
def expensive_lookup
  @_cached ||= begin
    if feature_enabled?
      record = Model.find_by(slug: slug)
      record ? Set.new(record.items.pluck(:id)) : Set.new
    else
      Set.new
    end
  end
end
```

**Impact**: When the early-return condition is met, the DB query re-executes on every call. A page rendering 50 items = 50 redundant `find_by` queries.

**Rule**: Never use `return` inside a `begin` block assigned via `||=`. Use `if/else` expressions instead.

## Testing Memoization

```ruby
test "method is memoized" do
  obj = create(:model_with_data)
  result1 = obj.expensive_method
  result2 = obj.expensive_method
  assert_equal result1.object_id, result2.object_id,
               'Should return same memoized object'
end
```

## Violation Detection

```bash
# Find unmemoized methods with conditional chains
grep -rn "def .*\n.*if.*&\.\|elsif" app/models/ --include="*.rb" | head -20

# Find methods that create Struct/OpenStruct (should be memoized or constant)
grep -rn "Struct.new\|OpenStruct.new" app/models/ --include="*.rb" | grep "def "

# Find URL methods without memoization
grep -rn "def.*_url$\|def.*_url(" app/models/ --include="*.rb" | \
  xargs -I{} sh -c 'file=$(echo "{}" | cut -d: -f1); grep -L "@.*||=" "$file" 2>/dev/null' | sort -u

# Find return statements inside begin blocks assigned via ||= (memoization defeat)
grep -rn "||= begin" app/ --include="*.rb" -A 10 | grep "return "
```

## Performance Impact

| Before | After | Reduction |
|--------|-------|-----------|
| 91,204 allocations | < 20,000 | ~78% |
| 7.22s response | < 1s | ~86% |
| 300+ redundant calls | 0 | 100% |
