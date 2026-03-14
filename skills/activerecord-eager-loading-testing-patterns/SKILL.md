---
name: activerecord-eager-loading-testing-patterns
description: "Testing patterns for ActiveRecord eager loading: .association(:name).loaded? verification, query count tests via ActiveSupport::Notifications, pattern-matching counts, batch loading, nested includes, and public page integration tests. Trigger keywords: test eager loading, association loaded, query count test, N+1 test, count_queries_matching, public page. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Eager Loading Testing Patterns

## Decision Tree

| Test Type | When to Use | What to Verify | Threshold |
|-----------|-------------|----------------|-----------|
| **Association Preloading** | Unit test for job/service returning relations | `.association(:name).loaded? == true` | N/A (boolean) |
| **Query Count** | Unit test for methods with multiple associations | Query count with association access | <= 15 queries |
| **Integration** | Full request cycle (controller + view) | End-to-end query count | <= 15 queries |
| **Pattern-Matching Count** | Isolate specific N+1 (e.g., one table) | `count_queries_matching(/table/)` | 1 query |
| **Batch Loading** | Replace loop finds with WHERE IN | Single query for all IDs | 1 query |
| **Nested Includes** | Multi-level eager loading (A -> B -> C) | `.association(:b).loaded? && b.association(:c).loaded?` | N/A (boolean) |
| **Public Page** | Unauthenticated pages (catalogs) | `assigns(:products).first.association(:x).loaded?` | N/A (boolean) |

## Test Helpers

Define once in `test_helper.rb` or a shared concern. Both patterns use `ActiveSupport::Notifications`.

```ruby
def count_queries(&block)
  queries = []
  counter = lambda do |_name, _started, _finished, _unique_id, payload|
    queries << payload[:sql] unless payload[:name] == 'SCHEMA'
  end
  ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { block.call }
  queries.count
end

def count_queries_matching(pattern, &block)
  queries = []
  counter = lambda do |_name, _started, _finished, _unique_id, payload|
    queries << payload[:sql] if payload[:sql]&.match?(pattern) && payload[:name] != 'SCHEMA'
  end
  ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { block.call }
  queries.count
end
```

## Testing Patterns

### Association Preloading Verification

```ruby
test 'search preloads variants and images' do
  product = create(:product, sale: @sale)
  variant = create(:variant, product: product)
  create(:image, variant: variant)

  result = SearchJob.perform_now(query: 'test')

  products = result[:products]
  assert products.first.association(:variants).loaded?,
         'variants should be eager loaded to prevent N+1 queries'
  assert products.first.variants.first.association(:images).loaded?,
         'images should be eager loaded'
end
```

### Query Count Testing

Access associations inside the block to trigger lazy loads — otherwise N+1 hides in the view.

```ruby
test 'search executes minimal queries with eager loading' do
  3.times do |i|
    product = create(:product, sale: @sale, name: "Test #{i}")
    variant = create(:variant, product: product)
    create(:image, variant: variant)
  end

  queries_count = count_queries do
    result = SearchJob.perform_now(query: 'Test')
    result[:products].each { |product| product.variants.each(&:images) }
  end

  assert queries_count <= 15,
         "Expected <= 15 queries with eager loading, got #{queries_count} (N+1 detected)"
end
```

### Full Request Cycle (Integration Test)

Tests controller + view together — catches N+1 that unit tests miss when the view accesses associations.

```ruby
test 'search does not trigger N+1 queries during view rendering' do
  queries_count = count_queries do
    get search_path,
        params: { search_form: { keywords: 'test' } },
        headers: { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
  end

  assert_response :success
  assert queries_count <= 15,
         "Expected <= 15 queries, got #{queries_count} (N+1 detected)"
end
```

### Pattern-Matching Query Count

Isolate queries to a specific table to detect N+1 on one association.

```ruby
test 'uses batch loading instead of N+1' do
  items = 5.times.map { create(:custom_field, product: @product) }

  target_queries = count_queries_matching(/custom_fields/) do
    post endpoint_path, params: build_params(items), xhr: true
  end

  assert_response :success
  assert target_queries <= 1,
         "Expected 1 query (batch), got #{target_queries} (N+1 detected)"
end
```

### Nested Includes Verification

Test each nesting level independently with `.association(:name).loaded?`.

```ruby
test 'find_for_cart preloads parent and parent_images' do
  product = create(:product, sale: @test_sale)
  parent = create(:parent_variant, product: product)
  size_variant = create(:size_variant, parent: parent)
  create(:parent_image, parent: parent)

  loaded_variant = Variant.find_for_cart(size_variant.id)

  assert loaded_variant.association(:parent).loaded?, 'parent should be eager loaded'
  assert loaded_variant.parent.association(:parent_images).loaded?,
         'parent_images should be eager loaded (nested)'
end
```

### Public Page Eager Loading

Use `assigns(:products)` after a request to verify associations are preloaded. Public pages skip authentication, so no `sign_in` needed.

```ruby
test 'public page eager loads product associations to prevent N+1' do
  host! "#{@test_subdomain.name}.example.com"

  get "/public/#{@test_sale.slug}/catalog"
  assert_response :success

  products = assigns(:products)
  return if products.empty?

  assert products.first.association(:variants).loaded?,
         'variants should be eager loaded to prevent N+1'
  assert products.first.association(:display_variant).loaded?,
         'display_variant should be eager loaded to prevent N+1'
end
```

## FORBIDDEN Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
|---|---|---|
| **Test data presence, not loading** `assert order.sale` | Passes with lazy loading; doesn't catch N+1 | `assert order.association(:store).loaded?` |
| **Exact query count** `assert_equal 3, queries_count` | Brittle; Rails adds overhead queries | `assert queries_count <= 15` (threshold + buffer) |
| **Not accessing associations** in query count test | N+1 exists in view but test passes | Mimic template access: `products.each { \|p\| p.variants.each(&:images) }` |
| **Only testing job, not view** | Job eager loads but template triggers N+1 | Add integration test exercising full request cycle |
| **Threshold too high** `assert queries_count <= 50` | Doesn't detect N+1 of 40 queries | Set threshold = expected queries + small buffer |
| **Individual finds in loops** `CustomField.find(id)` per iteration | N+1 queries | Batch load: `CustomField.where(id: ids).index_by(&:id)` |
