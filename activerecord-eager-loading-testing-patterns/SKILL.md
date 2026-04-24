---
name: activerecord-eager-loading-testing-patterns
description: "Testing patterns for ActiveRecord eager loading: .association.loaded? checks, bullet gem integration, performance regression tests, and query count assertions."
license: MIT
metadata:
  category: rails
  author: ngpestelos
  version: "2.0.1"
---

# ActiveRecord Eager Loading Testing Patterns

## Decision Tree

| Test Type | When to Use | What to Verify | Threshold |
|-----------|-------------|----------------|-----------|
| **Association Preloading** | Unit test for job/service returning relations | `.association(:name).loaded? == true` | N/A (boolean) |
| **Query Count** | Methods with multiple associations | Query count with association access | <= 15 queries |
| **Integration** | Full request cycle (controller + view) | End-to-end query count via `get` | <= 15 queries |
| **Pattern-Matching Count** | Isolate specific N+1 (e.g., one table) | `count_queries_matching(/table/)` | 1 query |
| **Nested Includes** | Multi-level (A -> B -> C) | Chain `.loaded?` at each level | N/A (boolean) |

## Test Helpers

Define once in `test_helper.rb`. Both use `ActiveSupport::Notifications`.

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

### Association Preloading

```ruby
result = SearchJob.perform_now(query: 'test')
assert result[:products].first.association(:variants).loaded?,
       'variants should be eager loaded to prevent N+1 queries'
# Nested: chain .loaded? at each level
# Public pages (no auth): use assigns(:products) after the request
```

### Query Count

Access associations inside the block to trigger lazy loads — otherwise N+1 hides in the view.

```ruby
queries_count = count_queries do
  result = SearchJob.perform_now(query: 'Test')
  result[:products].each { |product| product.variants.each(&:images) }
end
assert queries_count <= 15,
       "Expected <= 15 queries with eager loading, got #{queries_count}"
# For full request cycle, use get/post to catch view-triggered N+1
```

### Pattern-Matching Count

```ruby
target_queries = count_queries_matching(/custom_fields/) do
  post endpoint_path, params: build_params(items), xhr: true
end
assert target_queries <= 1,
       "Expected 1 query (batch), got #{target_queries} (N+1 detected)"
```

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `assert order.sale` (tests data, not loading) | `assert order.association(:store).loaded?` |
| `assert_equal 3, queries_count` (brittle) | `assert queries_count <= 15` (threshold + buffer) |
| Not accessing associations in count block | Mimic template: `products.each { \|p\| p.variants.each(&:images) }` |
| Only testing job, not full request cycle | Add integration test with `get`/`post` |
