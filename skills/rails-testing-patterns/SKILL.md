---
name: rails-testing-patterns
description: "Test type selection prioritizing integration tests (89-95% faster than system tests). Covers factory pitfalls, assert_select patterns, XSS testing, webhook/contract tests, FriendlyId slugs, and common test failures. Trigger keywords: integration test, system test, test type, factory association, flaky test, XSS testing, webhook test, assert_select, scoped selector. (global)"
allowed-tools: Read, Grep, Glob, Bash
---

# Rails Testing Pattern Selection

## Test Type Selection

### Priority Order

```
1. Integration Tests (ActionDispatch::IntegrationTest)
   → Controller logic, template rendering, AJAX, security

2. Model Tests (ActiveSupport::TestCase)
   → Business logic, validations, associations

3. JavaScript Tests (Jest/Mocha)
   → Frontend controller behavior, DOM manipulation

4. System Tests (MINIMAL)
   → ONLY genuine browser interaction (modals, JS-heavy UI, 10-20x slower)
```

### Decision Tree

| Question | YES | NO |
|----------|-----|-----|
| Browser interaction required? | System test | Continue |
| Controller/template logic? | Integration test | Continue |
| Frontend controller behavior? | JavaScript test | Continue |
| Model business logic? | Model test | Integration test |

## Integration Test Patterns

### XSS Testing in HTML Attributes

Simple absence testing fails when content is properly escaped. Use dual verification.

```ruby
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
end
```

### assert_select Patterns

**count: vs minimum:**
```ruby
# WRONG - count: fails if structure changes
assert_select '.product-card', count: 3  # Fails if 4 cards exist

# RIGHT - minimum: for variable collections
assert_select '.product-card', minimum: 1

# RIGHT - count: only for fixed, known structures
assert_select 'form.product-form', count: 1
```

**Scoped selectors for utility classes:**
```ruby
# WRONG - Utility class may appear elsewhere on page
assert_select '.text-center', count: 1

# RIGHT - Scope to specific container
assert_select '#product-details' do
  assert_select '.text-center', minimum: 1
end
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

### 4. FriendlyId Slug Stale Object

```ruby
# BROKEN: Object created before slug updated
product = create(:product, name: "Test")
product.update(name: "New Name")
get product_path(product)  # Uses stale slug!

# FIX: Reload object
product.reload
get product_path(product)
```

### 5. Timezone-Aware Date Creation

```ruby
# BROKEN: Date comparison fails across timezones
order = create(:order, created_at: Date.today)
assert_equal Date.today, order.created_at.to_date  # May fail!

# FIX: Use Time.zone.now
order = create(:order, created_at: Time.zone.now)
```

### 6. Testing Wrong Endpoint

AJAX content isn't in the initial page render. Test the AJAX endpoint directly.

```ruby
# BROKEN: AJAX content not in initial render
get product_path(@product)
assert_match /Cart/, response.body  # Fails!

# FIX: Test the AJAX endpoint directly
get cart_path, headers: { 'HTTP_ACCEPT' => 'text/html' }
```
