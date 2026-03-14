---
name: activerecord-application-query-optimization
description: "Prevents N+1 queries, duplicate joins, and missing eager loading in ActiveRecord. Covers .length vs .count optimization, batch preloading for index pages, SQL CASE count consolidation, .includes + .references join pattern, thundering herd cache bypass, three-layer eager loading defense, no-op callback removal, and 12 N+1 discovery patterns."
license: MIT
compatibility: Ruby on Rails with PostgreSQL. Patterns apply to any ActiveRecord + PostgreSQL application.
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# ActiveRecord Query Performance

## Count Optimization

### Use `.count` Not `.length`

`.length` loads ALL records into memory before counting. `.count` generates `SELECT COUNT(*)`.

```ruby
# WRONG - Loads ALL records into memory, then counts
def paid_orders_count
  paid_orders.length  # Executes: SELECT * FROM orders WHERE...
end

# RIGHT - Uses SQL COUNT, no record loading
def paid_orders_count
  paid_orders.count  # Executes: SELECT COUNT(*) FROM orders WHERE...
end
```

### Batch Preload for Index Pages

Single GROUP BY query instead of N individual queries per row.

```ruby
# Controller
def preload_batch_order_counts
  sale_ids = @sales.map(&:id)
  return if sale_ids.empty?

  store_ids = @sales.map(&:store_id).compact

  counts_by_store = Spree::Order
    .where(store_id: store_ids)
    .where(payment_state: 'paid')
    .group(:store_id)
    .count

  @sales.each do |sale|
    count = counts_by_store[sale.store_id] || 0
    sale.instance_variable_set(:@preloaded_paid_orders_count, count)
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

Status tabs with open/closed/upcoming counts should use single query.

**Before** (3 separate COUNT queries):
```ruby
def load_status_counts
  base_query = current_dealer.sales
  @open_count = base_query.open.count      # Query 1
  @upcoming_count = base_query.upcoming.count  # Query 2
  @closed_count = base_query.closed.count    # Query 3
end
```

**After** (1 query with conditional aggregation):
```ruby
def load_status_counts
  t = Time.current
  counts = current_dealer.sales.pick(
    Arel.sql(ActiveRecord::Base.sanitize_sql_array([
      'SUM(CASE WHEN open_date <= ? AND (close_date IS NULL OR close_date >= ?) THEN 1 ELSE 0 END)', t, t])),
    Arel.sql(ActiveRecord::Base.sanitize_sql_array([
      'SUM(CASE WHEN open_date > ? THEN 1 ELSE 0 END)', t])),
    Arel.sql(ActiveRecord::Base.sanitize_sql_array([
      'SUM(CASE WHEN close_date < ? THEN 1 ELSE 0 END)', t]))
  )
  @open_count, @upcoming_count, @closed_count = counts.map(&:to_i)
end
```

Use `pick()` not `pluck()`. Use `.to_i` since SUM returns nil for empty sets.

### Skip COUNT in Pagination Actions

Infinite scroll caches `totalPages` from initial load; `page` actions don't need `load_totals`. Only fetch paginated records.

### Group Orders with ORDER Before GROUP_BY

```ruby
# WRONG - Unpredictable order within groups
all_orders = current_sale.current_orders.to_a
@grouped_orders = all_orders.group_by(&:payment_state)

# RIGHT - Add .order() BEFORE .to_a
all_orders = current_sale.current_orders.order(updated_at: :desc).to_a
@grouped_orders = all_orders.group_by(&:payment_state)
```

### Batch Preload to Bypass Rails.cache (Thundering Herd)

Check preloaded value BEFORE cache lookup to prevent N+1 when all caches expire simultaneously.

```ruby
def available_products_count
  # Bypass cache entirely for batch contexts
  return @preloaded_available_products_count if defined?(@preloaded_available_products_count)

  # Cache preserved for non-batch contexts (show pages)
  Rails.cache.fetch(['count', id], expires_in: 24.hours) do
    products.joins(:master).distinct.count
  end
end
```

### Avoid Paperclip HTTP HEAD Requests

```ruby
# WRONG - Triggers HTTP HEAD request to S3 (~70ms each!)
return '/placeholder.jpg' unless logo.exists?

# RIGHT - Check database column instead (0ms)
return '/placeholder.jpg' unless logo_file_name.present?
```

### Remove No-Op Callbacks

Callbacks that return boolean without `throw(:abort)` are no-ops that waste queries.

```ruby
# WRONG - Runs on EVERY update, loads ALL orders, does nothing
base.before_update :has_completed_orders?
def has_completed_orders?
  complete_orders.length.positive?  # Loads ALL records!
end

# RIGHT - Remove callback, optimize method
# NOTE: Removed before_update :has_completed_orders? (no-op callback)
def has_completed_orders?
  orders.complete.exists?  # Efficient EXISTS query when actually needed
end
```

## Eager Loading

### Three-Layer Protection

**Layer 1: Complete Eager Loading (Primary)**:
```ruby
scope :with_everything, lambda {
  includes(
    :store,
    :billing_address,
    line_items: [
      :custom_values,
      { variant: [:images] }
    ]
  )
}
```

**Layer 2: Template Nil Guards (Defense)**:
```erb
<% sale = order.sale || current_sale %>
<% url = "/sales/#{sale.id}/orders/#{order.number}" %>
```

**Layer 3: JavaScript Fallback (Safety Net)**:
```javascript
const saleId = this.element.dataset.saleId;
const orderNumber = this.element.dataset.orderNumber;
if (saleId && orderNumber) {
  return `/sales/${saleId}/orders/${orderNumber}`;
}
```

### 12 N+1 Discovery Patterns

**Pattern 1: Job/Service Layer Missing Eager Loading**
```ruby
# WRONG - Job returns unoptimized relation
def search_products(query)
  Product.where('name ILIKE ?', "%#{query}%").limit(50)
end

# RIGHT - Analyze template, add eager loading
def search_products(query)
  Product.where('name ILIKE ?', "%#{query}%")
    .includes(:variants, variants: [:images])
    .limit(50)
end
```

**Pattern 2: .limit() Defeating Eager Loading**
```ruby
# WRONG - .limit() defeats eager loading
product.color_variants.limit(6).each { |v| v.images }

# RIGHT - Use .first(N) on loaded collection
product.color_variants.first(6).each { |v| v.images }
```

**Pattern 3: In-Memory Filtering vs Database Filtering**
```ruby
# RIGHT - In-memory filtering (uses eager-loaded data)
product.variants.select { |v| v.active? }

# WRONG - Database filtering (ignores eager-loaded data)
product.variants.where(active: true)
```

**Pattern 4: LEFT JOIN NULL Check for Missing Associations**
```ruby
# WRONG - N+1: loads each order's line items
orders.select { |o| o.line_items.blank? }

# RIGHT - Single query with LEFT JOIN
Order.left_joins(:line_items).where(line_items: { id: nil })
```

**Pattern 5: Invalid Association Names in includes()**
```ruby
# WRONG - Association name mismatch
Product.includes(:color_variant_images)  # ConfigurationError!

# RIGHT - Verify association name in model
Product.includes(color_variants: :images)
```

**Pattern 6: has_one vs has_many Confusion**
```ruby
# Model has: has_many :images
variant.image  # NoMethodError!
variant.images.first  # Correct
```

**Pattern 7: Delegation Method vs Association**
```ruby
# Model defines: def artworks; color_variants.flat_map(&:artworks); end

# WRONG - Only preloads color_variants
Product.includes(:color_variants)

# RIGHT - Preload full chain
Product.includes(color_variants: :artworks)
```

**Pattern 8: Concern Method Shadowing Association** - Class method shadows included module method due to Ruby method resolution.

**Pattern 9: has_many :through .any? Bypassing Eager Loading**
```ruby
# WRONG - .any? triggers new COUNT query
product.customizations.any?

# RIGHT - Iterate base association
product.line_items.any? { |li| li.custom_values.present? }
```

**Pattern 10: Gem-Added Hidden Methods** - Serializers (fast_jsonapi) add hidden methods accessing associations. Include associations used by serializers.

**Pattern 11: Attachment Chain Preloading**
```ruby
# WRONG - Missing attachment chain
Variant.includes(:images)

# RIGHT - Complete attachment chain
Variant.includes(images: { attachment: :blob })
```

**Pattern 12: Comprehensive Nested Eager Loading**
```ruby
Product.includes(
  :brand, :taxons,
  variants: [:prices, :option_values, { images: { attachment: :blob } }],
  color_variants: [:artworks, { images: { attachment: :blob } }]
)
```

### Eager Loading Syntax Reference

```ruby
.includes(:store)                           # Single
.includes(:store, :billing_address)          # Multiple
.includes(store: :sale)                      # Nested
.includes(store: { sale: :organization })    # Deep
.includes(:variants, variants: [:images])    # Children with nested
.includes(variants: { images: :blob })       # 3-level deep
```

## Join Optimization

### Use `.includes() + .references()` Not `.joins() + .includes()`

Combining `.joins()` and `.includes()` on the same association creates duplicate join paths causing 50-70x slowdown.

```ruby
# WRONG - Duplicate joins cause 50-70x performance degradation!
::Spree::Order
  .joins(store: :sale)                # JOIN #1 - INNER JOIN
  .includes(store: { sale: :organization })  # JOIN #2 - LEFT OUTER JOIN (duplicate!)
  .where('sales.dealer_id = ?', dealer_id)

# RIGHT - Single optimized join path
::Spree::Order
  .includes(:bill_address, store: { sale: :organization })
  .where('sales.dealer_id = ?', dealer_id)
  .references(:sales)  # Tells AR to include join for WHERE
  .limit(MAX_RESULTS_PER_TYPE)
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

Duplicate joins are silent - no errors, just slow. Key indicators:
- High ActiveRecord time (> 1000ms for simple queries)
- Low view rendering time (< 50ms)
- Multiple JOINs on same tables in SQL logs

```ruby
# Detection in development
ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
  if payload[:sql].scan(/JOIN/).count > 4
    Rails.logger.warn "[DUPLICATE-JOINS?] #{payload[:sql].scan(/JOIN/).count} JOINs"
  end
end
```

## Template-Driven N+1

Templates access associations not eager loaded in the controller. Common triggers:
- `.present?` checks (`payout.orders.present?`)
- Delegated attributes (`payout.abs_adjustment_amount` delegates to `adjustment.amount`)
- Method chains through multiple associations

**Fix**: Read the partial/template, find ALL association accesses (including `.present?`, `.any?`, delegated attributes), and add them all to the controller's `includes()`.

## Composite Index for Paginated Soft-Delete Queries

Missing composite indexes cause 20+ second loads on paginated queries with soft deletes.

```sql
-- Common pattern needing composite index
SELECT * FROM products WHERE deleted_at IS NULL AND sale_id = $1
         ORDER BY created_at DESC LIMIT 12
```

```ruby
add_index :products,
          [:sale_id, :deleted_at, :created_at],
          name: 'idx_products_sale_deleted_created',
          order: { created_at: :desc },
          algorithm: :concurrently
```

**Expected impact**: COUNT 19.7s -> <100ms, SELECT 9.7s -> <50ms.

**Applies when**: `acts_as_paranoid` tables + paginated index pages + foreign key filtering.

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

Combined with fragment caching (`cached:` option on collection renders), this yields 30-50% response time reduction (controller) + 40-60% render time reduction (caching).

## Query Threshold Management in Tests

Test environment adds 10-15 schema introspection queries, 3-5 multi-tenant context queries, and 2-3 session/auth queries beyond production. Set thresholds at observed count after fixing N+1 issues + 10-20% buffer.

## Deadlock Prevention

Multi-seed stress testing:
```bash
for i in {0..4}; do
  RAILS_ENV=test bin/rails test test/integration/order_processing_test.rb --seed $i
done
```

Use exponential backoff with `ActiveRecord::Deadlocked` rescue and `sleep(2 ** attempts)`.

## ActiveRecord Callback Race Conditions

`after_find` callbacks accessing associations can fail when concurrent threads delete the same record during callback execution. Use defensive nil guards at every association access point:
1. Check parent association exists
2. Check collection not empty
3. Check association object exists (concurrent deletion window)
4. Safe method call with `try` + fallback

Applies when: `after_find` callbacks + `dependent: :destroy` + concurrent operations.

## FORBIDDEN Patterns

| Anti-Pattern | Fix | Section |
|-------------|-----|---------|
| `.length` on associations | `.count` | Count Optimization |
| Per-row count on index pages | Batch preload with GROUP BY | Batch Preload |
| `attachment.exists?` | Check `_file_name.present?` | Paperclip |
| Multiple separate COUNTs | SQL CASE consolidation | SQL CASE |
| `.to_a.group_by` without ORDER | Add `.order()` before `.to_a` | Group Orders |
| `Rails.cache.fetch { count }` without preload bypass | Check preloaded value first | Thundering Herd |
| `.joins(:x).includes(:x)` | `.includes(:x).references(:x)` | Join Optimization |
| Missing associations in `includes()` | Trace template association accesses | Eager Loading |

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
| HTTP HEAD elimination | 15 x 70ms = 1050ms | 0ms | 100% eliminated |
| Duplicate join removal | 5-7 seconds | < 100ms | 50-70x faster |
| No-op callback removal | >1 second saves | <100ms saves | 90% faster |

