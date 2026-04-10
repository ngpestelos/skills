---
name: activerecord-application-query-optimization
description: "Prevents N+1 queries, duplicate joins, and missing eager loading in ActiveRecord. Detects common patterns via EXPLAIN ANALYZE, bullet gem warnings, and production log analysis."
license: MIT
metadata:
  category: rails
  author: ngpestelos
  version: "3.1.0"
---

# ActiveRecord Query Performance

## FORBIDDEN Patterns

| Anti-Pattern | Fix | Detection |
|-------------|-----|-----------|
| `.length` on associations | `.count` (SQL COUNT, no record loading) | `grep -rn "\.length" app/models/` |
| Per-row count on index pages | Batch preload with GROUP BY | High query count on index actions |
| Multiple separate COUNTs | SQL CASE consolidation (single query) | Multiple COUNT in same action |
| `Rails.cache.fetch { count }` without preload bypass | Check `defined?(@preloaded_...)` first | Thundering herd on cache expiry |
| `.joins(:x).includes(:x)` on same association | `.includes(:x).references(:x)` | 50-70x slowdown, high AR time |
| `.joins(:x).includes(:x)` with raw SQL | `.includes(:x).where(...).references(:x)` | Multiple JOINs on same table |
| `.includes(:x).left_outer_joins(:x)` | `.includes(:x).references(:x)` | Duplicate LEFT JOIN |
| Missing associations in `includes()` | Trace template association accesses | N+1 in view, not controller |

## Batch Preload for Index Pages

Single GROUP BY query replaces N individual queries. Same `defined?` pattern bypasses cache thundering herd.

```ruby
# Controller: preload counts for all rows in one query
counts_by_store = Order.where(store_id: store_ids, payment_state: 'paid')
                       .group(:store_id).count
@sales.each { |s| s.instance_variable_set(:@preloaded_count, counts_by_store[s.store_id] || 0) }

# Model: check preloaded first, fallback for non-batch contexts
def paid_orders_count
  return @preloaded_count if defined?(@preloaded_count)
  paid_orders.count
end
```

## SQL CASE Count Consolidation

N separate COUNT queries → 1 query with `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`. Use `.to_i` since SUM returns nil for empty sets.

```ruby
@open, @upcoming, @closed = current_dealer.sales.pick(
  Arel.sql(sanitize_sql(['SUM(CASE WHEN open_date <= ? AND (close_date IS NULL OR close_date >= ?) THEN 1 ELSE 0 END)', t, t])),
  Arel.sql(sanitize_sql(['SUM(CASE WHEN open_date > ? THEN 1 ELSE 0 END)', t])),
  Arel.sql(sanitize_sql(['SUM(CASE WHEN close_date < ? THEN 1 ELSE 0 END)', t]))
).map(&:to_i)
```

## N+1 Discovery Patterns

| # | Suspect When | Wrong | Right |
|---|-------------|-------|-------|
| 1 | Service returns relation rendered by template | `Product.where(...)` without includes | Add `.includes(:variants, variants: [:images])` |
| 2 | `.limit()` on eager-loaded association | `product.variants.limit(6)` (triggers new query) | `product.variants.first(6)` (in-memory — only works if already eager-loaded) |
| 3 | `.where()` on eager-loaded association | `product.variants.where(active: true)` (new query) | `product.variants.select { \|v\| v.active? }` (in-memory — only works if already eager-loaded) |
| 4 | Filtering "has no children" | `orders.select { \|o\| o.line_items.blank? }` | `Order.left_joins(:line_items).where(line_items: { id: nil })` |
| 5 | Model method traverses associations (flat_map) | `Product.includes(:color_variants)` | `Product.includes(color_variants: :artworks)` |
| 6 | `.any?` on has_many :through | `product.customizations.any?` (COUNT query) | `product.line_items.any? { \|li\| li.custom_values.present? }` (in-memory — only if line_items already loaded) |
| 7 | Rendering images/attachments | `Variant.includes(:images)` | `Variant.includes(images: { attachment: :blob })` |
| 8 | Detail-heavy pages | Partial includes | Include full chain: variants → prices, option_values, images → attachment → blob |

**Note on patterns 2, 3, 6**: The "in-memory" alternatives only avoid queries if the parent association was already eager-loaded. If the association is not loaded, `first(6)` and `select` will still trigger queries (though `first(6)` uses `LIMIT 6` which is cheaper than loading all). Choose based on whether you expect the data to be preloaded in context.

## Eager Loading Methods

Rails provides three ways to eager-load associations. Understanding the difference helps you choose the right tool:

| Method | SQL Strategy | Use When |
|--------|--------------|----------|
| `preload` | Separate queries (one per association) | Simple associations, no filtering on joined tables |
| `eager_load` | LEFT OUTER JOIN (single query) | Need to filter or order by joined table columns |
| `includes` | Rails decides (preload or eager_load) | Default choice; use `.references(:table)` to force JOIN when filtering |

**Key**: `includes` without `references` uses separate queries. Add `.references(:association)` when your `where` clause references the joined table.

## Strict Loading (Rails 6.1+)

Catch N+1 queries during development before they hit production:

```ruby
# config/environments/development.rb
config.active_record.strict_loading_by_default = true

# Or per-query
User.strict_loading.includes(:orders).find(1)
```

Raises `ActiveRecord::StrictLoadingViolationError` immediately when code attempts to lazy-load an association that wasn't eager-loaded.

**Best practice**: Enable in test environment to catch N+1s in CI:
```ruby
# config/environments/test.rb
config.active_record.strict_loading_by_default = true
```

## Join Optimization

Combining `.joins()` and `.includes()` on the same association creates duplicate join paths causing 50-70x slowdown. Silent — no errors, just slow. Indicators: AR time >1000ms, view time <50ms.

```ruby
# WRONG — Duplicate joins, 50-70x degradation
Order.joins(store: :sale).includes(store: { sale: :organization })
     .where('sales.dealer_id = ?', dealer_id)

# RIGHT — Single optimized join path
Order.includes(:bill_address, store: { sale: :organization })
     .where('sales.dealer_id = ?', dealer_id).references(:sales)
```

## Performance Impact

| Optimization | Before | After | Improvement |
|-------------|--------|-------|-------------|
| Count + batch preload | 109 queries, 4015ms | ~15-20 queries, ~800ms | 82% fewer queries |
| Duplicate join removal | 5-7 seconds | < 100ms | 50-70x faster |
