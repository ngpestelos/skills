---
name: activerecord-application-query-optimization
description: "Prevents N+1 queries, duplicate joins, and missing eager loading in ActiveRecord. Covers .length vs .count, batch preloading, SQL CASE count consolidation, .includes + .references join pattern, thundering herd cache bypass, no-op callback removal, and N+1 discovery patterns."
license: MIT
compatibility: Ruby on Rails with PostgreSQL. Patterns apply to any ActiveRecord + PostgreSQL application.
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# ActiveRecord Query Performance

## FORBIDDEN Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| `.length` on associations | `.count` |
| Per-row count on index pages | Batch preload with GROUP BY |
| Multiple separate COUNTs | SQL CASE consolidation |
| `Rails.cache.fetch { count }` without preload bypass | Check preloaded value first |
| `.joins(:x).includes(:x)` | `.includes(:x).references(:x)` |
| Missing associations in `includes()` | Trace template association accesses |

## Count Optimization

### Use `.count` Not `.length`

`.length` loads ALL records into memory before counting. `.count` generates `SELECT COUNT(*)`.

```ruby
# WRONG - Loads ALL records into memory, then counts
paid_orders.length  # Executes: SELECT * FROM orders WHERE...

# RIGHT - Uses SQL COUNT, no record loading
paid_orders.count  # Executes: SELECT COUNT(*) FROM orders WHERE...
```

### Batch Preload for Index Pages

Single GROUP BY query instead of N individual queries per row.

```ruby
# Controller
def preload_batch_order_counts
  store_ids = @sales.map(&:store_id).compact
  return if store_ids.empty?

  counts_by_store = Spree::Order
    .where(store_id: store_ids)
    .where(payment_state: 'paid')
    .group(:store_id)
    .count

  @sales.each do |sale|
    sale.instance_variable_set(:@preloaded_paid_orders_count, counts_by_store[sale.store_id] || 0)
  end
end
```

**Model: Check for preloaded data first with fallback**:
```ruby
def paid_orders_count
  return @preloaded_paid_orders_count if defined?(@preloaded_paid_orders_count)
  paid_orders.count  # Fallback for non-batch contexts
end
```

### Consolidate Multiple COUNT Queries with SQL CASE

N separate COUNT queries → 1 query with conditional aggregation using `pick()` + `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`. Use `.to_i` since SUM returns nil for empty sets.

```ruby
def load_status_counts
  t = Time.current
  @open_count, @upcoming_count, @closed_count = current_dealer.sales.pick(
    Arel.sql(ActiveRecord::Base.sanitize_sql_array([
      'SUM(CASE WHEN open_date <= ? AND (close_date IS NULL OR close_date >= ?) THEN 1 ELSE 0 END)', t, t])),
    Arel.sql(ActiveRecord::Base.sanitize_sql_array([
      'SUM(CASE WHEN open_date > ? THEN 1 ELSE 0 END)', t])),
    Arel.sql(ActiveRecord::Base.sanitize_sql_array([
      'SUM(CASE WHEN close_date < ? THEN 1 ELSE 0 END)', t]))
  ).map(&:to_i)
end
```

### Batch Preload to Bypass Rails.cache (Thundering Herd)

Check preloaded value BEFORE cache lookup to prevent N+1 when all caches expire simultaneously.

```ruby
def available_products_count
  return @preloaded_available_products_count if defined?(@preloaded_available_products_count)

  Rails.cache.fetch(['count', id], expires_in: 24.hours) do
    products.joins(:master).distinct.count
  end
end
```

### Remove No-Op Callbacks

Callbacks that return boolean without `throw(:abort)` are no-ops that waste queries.

```ruby
# WRONG - Runs on EVERY update, loads ALL orders, does nothing
base.before_update :has_completed_orders?
def has_completed_orders?
  complete_orders.length.positive?  # Loads ALL records!
end

# RIGHT - Remove callback, use .exists? when actually needed
def has_completed_orders?
  orders.complete.exists?
end
```

## Eager Loading

### Complete Eager Loading Scope

```ruby
scope :with_everything, lambda {
  includes(
    :store, :billing_address,
    line_items: [:custom_values, { variant: [:images] }]
  )
}
```

### N+1 Discovery Patterns

**Pattern 1: Job/Service Layer Missing Eager Loading** — Suspect when: service returns a relation rendered by a template.
```ruby
# WRONG
Product.where('name ILIKE ?', "%#{query}%").limit(50)
# RIGHT — Analyze template, add eager loading
Product.where('name ILIKE ?', "%#{query}%").includes(:variants, variants: [:images]).limit(50)
```

**Pattern 2: .limit() Defeating Eager Loading** — Suspect when: `.limit()` on an already-eager-loaded association.
```ruby
# WRONG — .limit() triggers new query, ignores eager-loaded data
product.color_variants.limit(6).each { |v| v.images }
# RIGHT — Use .first(N) on loaded collection
product.color_variants.first(6).each { |v| v.images }
```

**Pattern 3: In-Memory vs Database Filtering** — Suspect when: `.where()` on an eager-loaded association.
```ruby
# RIGHT — In-memory filtering uses eager-loaded data
product.variants.select { |v| v.active? }
# WRONG — .where() ignores eager-loaded data, triggers new query
product.variants.where(active: true)
```

**Pattern 4: LEFT JOIN for Missing Associations** — Suspect when: filtering records by "has no children."
```ruby
# WRONG — N+1: loads each order's line items
orders.select { |o| o.line_items.blank? }
# RIGHT — Single query
Order.left_joins(:line_items).where(line_items: { id: nil })
```

**Pattern 5: Delegation Method vs Association** — Suspect when: model method traverses associations (e.g., `flat_map`).
```ruby
# Model: def artworks; color_variants.flat_map(&:artworks); end
# WRONG — Only preloads color_variants, misses artworks
Product.includes(:color_variants)
# RIGHT — Preload full chain
Product.includes(color_variants: :artworks)
```

**Pattern 6: has_many :through .any? Bypassing Eager Loading** — Suspect when: `.any?` on a `through` association.
```ruby
# WRONG — .any? triggers new COUNT query
product.customizations.any?
# RIGHT — Iterate base association
product.line_items.any? { |li| li.custom_values.present? }
```

**Pattern 7: Attachment Chain Preloading** — Suspect when: rendering images/attachments.
```ruby
# WRONG — Missing attachment chain
Variant.includes(:images)
# RIGHT — Complete chain
Variant.includes(images: { attachment: :blob })
```

**Pattern 8: Comprehensive Nested Eager Loading** — Suspect when: rendering detail-heavy pages.
```ruby
Product.includes(
  :brand, :taxons,
  variants: [:prices, :option_values, { images: { attachment: :blob } }],
  color_variants: [:artworks, { images: { attachment: :blob } }]
)
```

Additional patterns (no code needed): **Invalid association names** in `includes()` cause `ConfigurationError` — verify against model. **has_one vs has_many confusion** — use `.images.first` not `.image`. **Concern method shadowing** — class method can shadow included module method. **Gem-added hidden methods** — serializers (fast_jsonapi) access associations implicitly; include them.

## Join Optimization

### Use `.includes() + .references()` Not `.joins() + .includes()`

Combining `.joins()` and `.includes()` on the same association creates duplicate join paths causing 50-70x slowdown.

```ruby
# WRONG — Duplicate joins cause 50-70x performance degradation!
::Spree::Order
  .joins(store: :sale)
  .includes(store: { sale: :organization })
  .where('sales.dealer_id = ?', dealer_id)

# RIGHT — Single optimized join path
::Spree::Order
  .includes(:bill_address, store: { sale: :organization })
  .where('sales.dealer_id = ?', dealer_id)
  .references(:sales)
```

### Quick Decision Tree

| Scenario | Pattern |
|----------|---------|
| Eager load WITHOUT WHERE clause | `.includes(:association)` |
| Eager load WITH WHERE clause | `.includes(:association).references(:association)` |
| Filter WITHOUT eager loading | `.joins(:association)` |
| **NEVER** | `.joins(:assoc).includes(:assoc)` |
| **NEVER** | `.joins('INNER JOIN...').includes(:assoc)` |
| **NEVER** | `.includes(:assoc).left_outer_joins(:assoc)` |

### Duplicate Join Detection

Silent — no errors, just slow. Indicators: high AR time (>1000ms), low view time (<50ms), multiple JOINs on same tables.

```ruby
ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
  if payload[:sql].scan(/JOIN/).count > 4
    Rails.logger.warn "[DUPLICATE-JOINS?] #{payload[:sql].scan(/JOIN/).count} JOINs"
  end
end
```

## Template-Driven N+1

Templates access associations not eager loaded in the controller. Common triggers: `.present?` checks, delegated attributes, method chains through multiple associations.

**Fix**: Read the partial/template, find ALL association accesses (including `.present?`, `.any?`, delegated attributes), and add them all to the controller's `includes()`.

## Composite Index for Paginated Soft-Delete Queries

Missing composite indexes cause 20+ second loads on paginated queries with soft deletes.

```ruby
add_index :products,
          [:sale_id, :deleted_at, :created_at],
          name: 'idx_products_sale_deleted_created',
          order: { created_at: :desc },
          algorithm: :concurrently
```

**Expected impact**: COUNT 19.7s → <100ms, SELECT 9.7s → <50ms. **Applies when**: `acts_as_paranoid` + paginated index + foreign key filtering.

## Controller Pre-Loading for Memoized Data

Memoized concern methods called during view rendering execute expensive queries in the render phase. Pre-call them in the controller:

```ruby
def edit
  @product = load_product_for_edit(current_sale.products, params[:product_id])
  preload_edit_page_data unless request.xhr?
  render layout: 'product_edit'
end

private

def preload_edit_page_data
  return unless current_sale
  current_sale.product_categories  # Pre-warm sidebar cache
  current_sale.all_brands          # Pre-load dropdown data
  current_sale.all_categories
end
```

Yields 30-50% response time reduction + 40-60% render time reduction when combined with fragment caching.

## Verification Commands

```bash
# Verify association loaded (Rails console)
order = Order.with_everything.first; order.association(:store).loaded?

# Find .length on associations
grep -rn "\.length" app/models/ --include="*.rb" | grep -v "\.to_s\.length"

# Find duplicate joins (files using both .joins and .includes)
grep -rln "\.joins(" app/ --include="*.rb" | xargs grep -l "\.includes("

# Find no-op callbacks
grep -rn "before_update\|before_save" app/models/ --include="*.rb" -A 5 | \
  grep -v "throw\|abort\|errors\.add\|validate"
```

## Performance Impact

| Optimization | Before | After | Improvement |
|-------------|--------|-------|-------------|
| Count + batch preload | 109 queries, 4015ms | ~15-20 queries, ~800ms | 82% fewer queries |
| Duplicate join removal | 5-7 seconds | < 100ms | 50-70x faster |
| No-op callback removal | >1 second saves | <100ms saves | 90% faster |
