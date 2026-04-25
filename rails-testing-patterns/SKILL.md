---
name: rails-testing-patterns
description: "Test type selection prioritizing integration tests over system tests, shared context for reusable test data, and avoiding over-mocking in Rails."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  category: rails
  version: "2.0.1"
---

# Rails Testing Pattern Selection

## Test Type Decision

| Question | Test Type |
|----------|-----------|
| Requires real browser (modals, JS-heavy UI)? | System test (last resort — 10-20x slower) |
| Controller logic, routing, template rendering, security? | Integration test |
| Frontend controller / DOM manipulation? | JavaScript test (Jest/Mocha) |
| Business logic, validations, associations? | Model test |

Default to integration tests. System tests only for genuine browser interaction.

## XSS Dual-Verification

Simple absence checks fail when content is HTML-escaped. Always verify both sides:

```ruby
test 'escapes user input in HTML' do
  item = create(:item, name: '<img onerror="alert(1)">')
  get item_path(item)

  assert_includes response.body, '&lt;img'                    # entities present
  assert_not_includes response.body, '<img onerror="alert'     # raw markup absent
end
```

## assert_select Patterns

Use `minimum:` for variable collections, `count:` only for fixed structures. Always scope utility classes to a container:

```ruby
assert_select '.product-card', minimum: 1          # variable collection
assert_select 'form.product-form', count: 1        # known singleton

assert_select '#product-details' do                 # scoped — avoids false matches
  assert_select '.text-center', minimum: 1
end
```

## Contract Testing for AJAX

Test the AJAX endpoint directly — AJAX content is absent from the initial page render. Assert contract shape (keys, types), not specific values:

```ruby
test 'returns expected JSON structure' do
  get api_products_path, as: :json
  json = JSON.parse(response.body)

  assert json.key?('products')
  assert json['products'].first.key?('id')
end
```

## Staleness Pitfalls

Three common variants of the same root cause: **the Ruby object doesn't reflect the current DB state**. Fix: call `.reload` before assertions or path helpers.

| Scenario | What goes stale | Fix |
|----------|----------------|-----|
| Create child via `parent_id:`, then read `parent.children` | Association cache | `parent.reload` |
| Update a FriendlyId model, then use `product_path(product)` | Slug attribute | `product.reload` |
| Factory creates its own association, ignoring your override | Implicit association | Pass association explicitly **and** verify with `.reload` |

```ruby
# All three reduce to:
parent = create(:parent)
create(:child, parent_id: parent.id)
parent.reload                          # without this, parent.children is []
```

## Naming Convention

Prefix integration test classes with the type suffix to avoid collisions across directories: `FooIntegrationTest < ActionDispatch::IntegrationTest`, not `FooTest`.
