---
name: activerecord-eager-loading-testing-patterns
description: "Testing patterns for ActiveRecord eager loading: .association(:name).loaded? verification, query count tests via ActiveSupport::Notifications, pattern-matching counts, batch loading, nested includes, and public page integration tests. Trigger keywords: test eager loading, association loaded, query count test, N+1 test, count_queries_matching, public page. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Eager Loading Testing Patterns

## Core Principles

1. **Test association loading, not just data presence** - verify `.association(:name).loaded?` returns true
2. **Count actual queries** - use ActiveSupport::Notifications to measure query count
3. **Set realistic thresholds** - account for Rails overhead (transactions, cache checks)
4. **Test full request cycle** - integration tests verify controller + view don't trigger N+1
5. **Batch load in loops** - replace individual finds with single WHERE IN query
6. **Use nested includes** - `parent: :children` for multi-level eager loading

## Quick Decision Tree

| Test Type | When to Use | What to Verify | Threshold |
|-----------|-------------|----------------|-----------|
| **Association Preloading** | Unit test for job/service returning relations | `.association(:name).loaded? == true` | N/A (boolean) |
| **Query Count** | Unit test for methods with multiple associations | Query count with association access | <= 15 queries |
| **Integration** | Full request cycle (controller + view) | End-to-end query count | <= 15 queries |
| **Pattern-Matching Count** | Isolate specific N+1 (e.g., one table) | `count_queries_matching(/table/)` | 1 query |
| **Batch Loading** | Replace loop finds with WHERE IN | Single query for all IDs | 1 query |
| **Nested Includes** | Multi-level eager loading (A -> B -> C) | `.association(:b).loaded? && b.association(:c).loaded?` | N/A (boolean) |
| **Public Page** | Unauthenticated pages (catalogs) | `assigns(:products).first.association(:x).loaded?` | N/A (boolean) |

## REQUIRED Testing Patterns

### Pattern 1: Association Preloading Verification (Unit Test)

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

### Pattern 2: Query Count Testing (Unit Test)

```ruby
test 'search executes minimal queries with eager loading' do
  3.times do |i|
    product = create(:product, sale: @sale, name: "Test #{i}")
    variant = create(:variant, product: product)
    create(:image, variant: variant)
  end

  queries_count = count_queries do
    result = SearchJob.perform_now(query: 'Test')
    # Access associations (would trigger N+1 without eager loading)
    result[:products].each { |product| product.variants.each(&:images) }
  end

  # With eager loading: ~5-10 queries; without: 50+
  assert queries_count <= 15,
         "Expected <= 15 queries with eager loading, got #{queries_count} (N+1 detected)"
end

private

def count_queries(&block)
  queries = []
  counter = lambda do |_name, _started, _finished, _unique_id, payload|
    queries << payload[:sql] unless payload[:name] == 'SCHEMA'
  end
  ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { block.call }
  queries.count
end
```

### Pattern 3: Full Request Cycle Testing (Integration Test)

```ruby
class SearchPerformanceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in @test_user
    @product = create(:product, sale: @sale)
    @variant = create(:variant, product: @product)
    @image = create(:image, variant: @variant)
  end

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

  private

  def count_queries(&block)
    queries = []
    counter = lambda do |_name, _started, _finished, _unique_id, payload|
      queries << payload[:sql] unless payload[:name] == 'SCHEMA'
    end
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { block.call }
    queries.count
  end
end
```

### Pattern 4: Pattern-Matching Query Count

```ruby
def count_queries_matching(pattern, &block)
  queries = []
  counter = lambda do |_name, _started, _finished, _unique_id, payload|
    queries << payload[:sql] if payload[:sql]&.match?(pattern) && payload[:name] != 'SCHEMA'
  end
  ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { block.call }
  queries.count
end

test 'create uses batch loading for custom fields instead of N+1' do
  product = create(:product, sale: @test_sale)
  variant = create(:variant, product: product)
  custom_fields = 5.times.map { create(:custom_field, product: product, required: false) }

  custom_fields_params = custom_fields.each_with_index.to_h do |field, i|
    [i.to_s, { id: field.id.to_s, value: '' }]
  end

  params = {
    product_id: product.id, variant_id: variant.id,
    quantity: 1, custom_fields_attributes: custom_fields_params
  }

  custom_field_queries = count_queries_matching(/custom_fields/) do
    post "/checkout/line_items", params: { line_item: params }, xhr: true
  end

  assert_response :success
  # Batch loading: 1 query; N+1: 5 queries
  assert custom_field_queries <= 1,
         "Expected 1 custom field query (batch), got #{custom_field_queries} (N+1 detected)"
end
```

### Pattern 5: Nested Includes for Multi-Level Eager Loading

```ruby
# Production code: nested includes
def find_for_cart(variant_id)
  variant = where(id: variant_id).includes(
    :product, :parent, [:images], :default_price, :option_values,
    product: { master: [:default_price, :images] },
    parent: :parent_images
  ).first
  return if variant.blank?
  variant.prepare_for_cart
  variant
end

# Tests verifying each nesting level independently
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

test 'find_for_cart preloads product master with images for fallback' do
  product = create(:product, sale: @test_sale)
  parent = create(:parent_variant, product: product)
  size_variant = create(:size_variant, parent: parent)

  loaded_variant = Variant.find_for_cart(size_variant.id)

  assert loaded_variant.association(:product).loaded?, 'product should be eager loaded'
  assert loaded_variant.product.association(:master).loaded?,
         'product.master should be eager loaded'
  assert loaded_variant.product.master.association(:images).loaded?,
         'product.master.images should be eager loaded for image fallback'
end
```

### Pattern 6: Batch Loading to Replace Loop N+1

```ruby
# N+1 anti-pattern: Find in loop
def remove_blank_optional_custom_fields
  custom_fields_attributes.reject! do |_k, params|
    hash = params.with_indifferent_access
    hash[:value].blank? && !CustomField.find(hash[:id]).required  # N+1!
  end
end

# Batch loading pattern: Single query with in-memory lookup
def remove_blank_optional_custom_fields
  return if custom_fields_attributes.blank?

  custom_field_ids = custom_fields_attributes.values.map { |p| p.with_indifferent_access[:id] }.compact
  required_field_ids = CustomField
    .where(id: custom_field_ids, required: true)
    .pluck(:id)
    .to_set  # O(1) lookup

  custom_fields_attributes.reject! do |_k, params|
    hash = params.with_indifferent_access
    hash[:value].blank? && !required_field_ids.include?(hash[:id].to_i)
  end
end

# Test: verify batch loading uses single query
test 'batch loading custom fields uses single query' do
  product = create(:product, sale: @test_sale)
  custom_fields = 5.times.map { create(:custom_field, product: product) }

  custom_field_queries = count_queries_matching(/custom_fields/) do
    custom_field_ids = custom_fields.map(&:id)
    CustomField.where(id: custom_field_ids, required: true).pluck(:id).to_set
  end

  assert_equal 1, custom_field_queries,
               "Batch loading should use exactly 1 query, got #{custom_field_queries}"
end
```

### Pattern 7: Public Page Eager Loading Verification

Public pages skip authentication, use subdomain routing, and often have complex nested includes with polymorphic image associations.

```ruby
# Production code
class PublicPagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :load_products, only: :index

  def index
    render layout: 'public'
  end

  private

  def load_products
    @products = current_sale.products
                            .includes(
                              :variants,
                              display_variant: [
                                :option_value,
                                { display_image: %i[uploaded_image decorated_image] }
                              ],
                              variants: [
                                :option_value, :size_variants,
                                { display_image: %i[uploaded_image decorated_image] }
                              ]
                            )
                            .where(available: true)
                            .order(name: :asc)
  end
end

# Integration test
class PublicPagesTest < ActionDispatch::IntegrationTest
  setup do
    host! "#{@test_subdomain.name}.example.com"
    @products = create_sale_products(@test_sale, 3)
    @products.each { |p| p.update_column(:available, true) }
  end

  test 'public page eager loads product associations to prevent N+1' do
    get "/public/#{@test_sale.slug}/catalog"
    assert_response :success

    products = assigns(:products)
    return if products.empty?

    first_product = products.first
    assert first_product.association(:variants).loaded?,
           'variants should be eager loaded to prevent N+1'
    assert first_product.association(:display_variant).loaded?,
           'display_variant should be eager loaded to prevent N+1'
  end
end
```

## FORBIDDEN Testing Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
|---|---|---|
| **Test data presence, not loading** `assert order.sale` | Passes with lazy loading; doesn't catch N+1 | `assert order.association(:store).loaded?` |
| **Exact query count** `assert_equal 3, queries_count` | Brittle; Rails adds overhead queries | `assert queries_count <= 15` (threshold + buffer) |
| **Not accessing associations** in query count test | N+1 exists in view but test passes | Mimic template access: `products.each { \|p\| p.variants.each(&:images) }` |
| **Only testing job, not view** | Job eager loads but template triggers N+1 | Add integration test exercising full request cycle |
| **Threshold too high** `assert queries_count <= 50` | Doesn't detect N+1 of 40 queries | Set threshold = expected queries + small buffer |
| **Individual finds in loops** `CustomField.find(id)` per iteration | N+1 queries | Batch load: `CustomField.where(id: ids).index_by(&:id)` |

## Violation Detection

```bash
# Find scopes with .includes() but no tests
grep -r "\.includes(" app/models/ app/jobs/ app/services/ | \
  sed 's/:.*//g' | \
  while read file; do
    basename=$(basename "$file" .rb)
    if ! grep -q "association.*loaded" "test/**/${basename}_test.rb" 2>/dev/null; then
      echo "Missing test: $file"
    fi
  done

# Find jobs/services without query count tests
find app/jobs app/services -name "*.rb" -type f | \
  while read file; do
    basename=$(basename "$file" .rb)
    test_file=$(find test -name "${basename}_test.rb")
    if [ -f "$test_file" ] && ! grep -q "count_queries" "$test_file"; then
      echo "Add query count test: $file"
    fi
  done

# Find integration tests missing query verification
grep -L "count_queries\|queries_count" test/integration/**/*_test.rb
```
