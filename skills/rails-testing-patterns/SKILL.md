---
name: rails-testing-patterns
description: "Test type selection prioritizing integration tests (89-95% faster than system tests). Covers factory pitfalls, assert_select patterns, XSS testing, webhook/contract tests, FriendlyId slugs, and common test failures. Trigger keywords: integration test, system test, test type, factory association, flaky test, XSS testing, webhook test, assert_select, scoped selector. (global)"
allowed-tools: Read, Grep, Glob, Bash
---

# Rails Testing Pattern Selection

## Core Principles

1. **Integration tests are the default** - Use for controller logic AND template rendering
2. **System tests are expensive** - 10-20x slower, use ONLY for genuine browser interaction
3. **View tests require excessive stubbing** - Use integration tests instead
4. **Controller tests are deprecated** - Rails 5+ uses integration tests

## REQUIRED: Test Type Selection

### Priority Order

```
1. Integration Tests (ActionDispatch::IntegrationTest)
   → Controller logic, template rendering, AJAX, security

2. Model Tests (ActiveSupport::TestCase)
   → Business logic, validations, associations

3. JavaScript Tests (Jest/Mocha)
   → Frontend controller behavior, DOM manipulation

4. System Tests (MINIMAL)
   → ONLY genuine browser interaction (modals, JS-heavy UI)
```

### Decision Tree

| Question | YES | NO |
|----------|-----|-----|
| Browser interaction required? | System test | Continue |
| Controller/template logic? | Integration test | Continue |
| Frontend controller behavior? | JavaScript test | Continue |
| Model business logic? | Model test | Integration test |

## FORBIDDEN Patterns

```ruby
# WRONG - Controller tests (deprecated Rails 5+)
class ProductsControllerTest < ActionController::TestCase
  # Use integration tests instead
end

# WRONG - View tests with excessive stubbing
class ProductViewTest < ActionView::TestCase
  # 80+ stubs required - use integration tests instead
end

# WRONG - System tests for simple form submission
class CheckoutSystemTest < ApplicationSystemTestCase
  # 10-20x slower - use integration test instead
end
```

## Integration Test Patterns

### Basic Structure

```ruby
class ProductsIntegrationTest < ActionDispatch::IntegrationTest
  test "creates product" do
    post products_path, params: { product: { name: "Test" } }

    assert_response :redirect
    assert Product.exists?(name: "Test")
  end
end
```

### XSS Testing in HTML Attributes

**Problem**: Simple absence testing fails when content is properly escaped.

```ruby
# ❌ WRONG - Naive absence testing
test 'escapes color names' do
  item = create(:item, name: '<img onerror="alert(1)">')
  get item_path(item)

  # FAILS: 'onerror=' appears in escaped form 'onerror=&quot;'
  assert_not_includes response.body, 'onerror='
end

# ✅ RIGHT - Dual verification pattern
test 'escapes color names' do
  item = create(:item, name: '<img onerror="alert(1)">')
  get item_path(item)

  # POSITIVE: Entities ARE escaped
  assert_includes response.body, '&lt;img'
  assert_includes response.body, 'onerror=&quot;'

  # NEGATIVE: Malicious code NOT executable
  assert_not_includes response.body, '<img onerror="alert'
end
```

### Webhook Testing

```ruby
# Webhooks are HTTP endpoints - use integration tests
class StripeWebhookTest < ActionDispatch::IntegrationTest
  test 'processes charge.failed event' do
    payload = { type: 'charge.failed', data: { object: {} } }.to_json

    post '/webhooks/stripe',
         params: payload,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :success
  end
end
```

### Contract Testing for AJAX Endpoints

```ruby
test 'returns expected JSON structure' do
  get api_products_path, as: :json

  assert_response :success
  json = JSON.parse(response.body)

  # Test contract, not specific values
  assert json.key?('products')
  assert json['products'].is_a?(Array)
  assert json['products'].first.key?('id')
  assert json['products'].first.key?('name')
end
```

### assert_select Patterns

#### count: vs minimum:

```ruby
# ❌ WRONG - count: fails if structure changes
assert_select '.product-card', count: 3  # Fails if 4 cards exist

# ✅ RIGHT - minimum: for variable collections
assert_select '.product-card', minimum: 1

# ✅ RIGHT - count: only for fixed, known structures
assert_select 'form.product-form', count: 1  # Page has exactly one form
```

#### Scoped Selectors for Utility Classes

```ruby
# ❌ WRONG - Utility class may appear elsewhere on page
assert_select '.text-center', count: 1  # Fails if header also centered

# ✅ RIGHT - Scope to specific container
assert_select '#product-details' do
  assert_select '.text-center', minimum: 1
end

# ✅ RIGHT - More specific selector
assert_select '#product-details .text-center', minimum: 1
```

## Common Pitfalls

### 1. Factory Association Override

```ruby
# BROKEN: Factory creates new association
parent = create(:parent, name: 'Specific')
child = create(:child, parent: parent)
# child.parent.name might NOT be 'Specific'

# FIX: Explicitly pass association
child = create(:child, parent: parent, parent_name: parent.name)
```

### 2. Duplicate Test Class Names

```ruby
# BROKEN: Same class name, different parent
# test/models/foo_test.rb → FooTest < ActiveSupport::TestCase
# test/integration/foo_test.rb → FooTest < IntegrationTest

# FIX: Add type suffix
class FooIntegrationTest < ActionDispatch::IntegrationTest
```

### 3. Association Cache Staleness

```ruby
# BROKEN: Cache populated before children created
parent = create(:parent)
child = create(:child, parent_id: parent.id)
parent.children.to_a  # => [] (EMPTY!)

# FIX: Reload parent
parent.reload
parent.children.to_a  # => [child]
```

### 4. Non-Deterministic Test Data

```ruby
# BROKEN: UUID changes every run
name = "Test-#{SecureRandom.uuid}"
assert_match /#{name}/, response.body

# FIX: Deterministic values
name = "Test Category"
assert_match /Test Category/, response.body
```

### 5. AJAX Content via Full Page

```ruby
# BROKEN: AJAX content not in initial render
get product_path(@product)
assert_match /Cart/, response.body  # Fails!

# FIX: Test AJAX endpoint directly
get cart_path, headers: { 'HTTP_ACCEPT' => 'text/html' }
```

### 6. FriendlyId Slug Stale Object

```ruby
# BROKEN: Object created before slug updated
product = create(:product, name: "Test")
product.update(name: "New Name")
get product_path(product)  # Uses stale slug!

# FIX: Reload object
product.reload
get product_path(product)  # Uses new slug
```

### 7. Conditional UI Rendering

```ruby
# BROKEN: Testing UI that requires prerequisite data
get product_path(@product)
assert_select '.add-to-cart-btn'  # Fails - button hidden!

# FIX: Ensure prerequisite data exists
@product.update(inventory_count: 10)  # Enable "in stock" state
get product_path(@product)
assert_select '.add-to-cart-btn'
```

### 8. Testing Wrong Endpoint

```ruby
# BROKEN: Testing full page instead of AJAX endpoint
get products_path
assert_select '.search-results'  # Empty - AJAX loads later!

# FIX: Test the AJAX endpoint directly
get search_products_path(q: 'test'), as: :json
json = JSON.parse(response.body)
assert json['results'].any?
```

### 9. Timezone-Aware Date Creation

```ruby
# BROKEN: Date comparison fails across timezones
order = create(:order, created_at: Date.today)
assert_equal Date.today, order.created_at.to_date  # May fail!

# FIX: Use Time.zone.now
order = create(:order, created_at: Time.zone.now)
```

### 10. Setup Pollution

```ruby
# BROKEN: Tests depend on order
test 'first test creates data' do
  create(:product, global: true)
end

test 'second test assumes clean state' do
  assert_equal 0, Product.global.count  # Fails!
end

# FIX: Complete data isolation in setup
setup do
  Product.global.delete_all
end
```

## Performance Comparison

| Test Type | Speed | Use Case |
|-----------|-------|----------|
| Integration | 1x (baseline) | Controller + template |
| Model | 0.8x | Business logic |
| JavaScript | 0.5x | Frontend behavior |
| System | 10-20x | Browser interaction ONLY |

## Violation Detection

```bash
# Find duplicate test class names
grep -rn "^class.*Test <" test/ | awk -F: '{print $2}' | sort | uniq -d

# Find system tests that could be integration tests
grep -rn "visit\|click_on" test/system/ --include="*.rb" | head -10

# Find excessive stubbing in view tests
grep -c "stub\|mock" test/views/*.rb 2>/dev/null | sort -t: -k2 -rn

# Find deprecated controller tests
grep -rn "ActionController::TestCase" test/ --include="*.rb"

# Find brittle count assertions
grep -rn "count: [0-9]" test/ --include="*.rb" | grep "assert_select"
```

