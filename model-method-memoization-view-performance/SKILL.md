---
name: model-method-memoization-view-performance
description: "Memoize model methods called multiple times per object during view rendering to reduce Ruby CPU and memory allocations. Auto-activates when performance traces show high render_template with fast SQL queries, allocation count >50k with query count <100, investigating views-slow-but-queries-fast scenarios, or working with @var ||= vs defined?(@var) patterns."
license: MIT
compatibility: Ruby on Rails applications with view rendering performance issues.
metadata:
  author: ngpestelos
  version: "1.1.1"
---

# Memoizing Model Methods for View Performance

> **When to suspect this**: SQL queries are fast (<100ms each) but `render_template.action_view` is slow (5+ seconds) with high allocations (50k+). This is a **Ruby CPU/memory issue**, not a database issue.

## Pattern Selection

| Scenario | Pattern |
|----------|---------|
| Method always returns truthy | `@var \|\|= compute_method` |
| Method can return nil/false | `return @var if defined?(@var); @var = compute_method` |
| Method takes arguments | `@cache \|\|= {}; @cache[arg] \|\|= compute(arg)` |
| Method called 3+ times in one caller | Store in local variable |
| Method creates objects (Struct, Array) | Memoize or use frozen constant |
| Method called in view loops | Must be memoized |
| Method uses `begin` block with `\|\|=` | Never use `return` — use if/else expressions |

## Nil-Safe Memoization

`||=` silently recomputes when the method returns `nil` or `false`. Use the `defined?` guard:

```ruby
def default_image
  return @default_image if defined?(@default_image)
  @default_image = compute_default_image
end
```

## Constant Extraction for Static Objects

Methods that return the same Struct/OpenStruct every time should use a frozen constant instead: `FALLBACK = Struct.new(:url, :thumb).new('/na.jpg', '/na_th.jpg').freeze`

## Anti-Pattern: `return` Inside `begin` Block Defeats `||=`

A `return` inside `begin` exits the method entirely, bypassing the `||=` assignment. The ivar stays `nil` and the block re-executes every call. With 50 items on a page, that means 50 redundant DB queries.

```ruby
# WRONG: return exits method, @_cached stays nil
def expensive_lookup
  @_cached ||= begin
    return Set.new unless feature_enabled?   # bypasses assignment!
    record = Model.find_by(slug: slug)
    return Set.new if record.nil?            # bypasses assignment!
    Set.new(record.items.pluck(:id))
  end
end

# RIGHT: if/else expressions always produce a value for ||= to capture
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

## Violation Detection

```bash
# Unmemoized methods with conditional chains
grep -rn "def .*\n.*if.*&\.\|elsif" app/models/ --include="*.rb" | head -20
# Struct/OpenStruct creation that should be constants
grep -rn "Struct.new\|OpenStruct.new" app/models/ --include="*.rb" | grep "def "
# return inside begin blocks assigned via ||= (memoization defeat)
grep -rn "||= begin" app/ --include="*.rb" -A 10 | grep "return "
```

## Observed Impact

| Metric | Before | After |
|--------|--------|-------|
| Allocations | 91,204 | < 20,000 (~78% reduction) |
| Response time | 7.22s | < 1s (~86% reduction) |
| Redundant calls | 300+ | 0 |
