---
name: rails-cache-performance
description: "Rails cache invalidation, stale cache detection, request-level fragment caching, and Russian doll caching patterns."
allowed-tools: Read, Grep, Glob
metadata:
  category: rails
  version: "1.0.1"
---

# Rails Cache Performance

## Fragment Cache Invalidation

Use touch cascades so parent records auto-invalidate when children update:

```ruby
class Image < ApplicationRecord
  belongs_to :viewable, polymorphic: true, touch: true
end
```

## Multi-Layer Cache Clearing

Clear all layers: `Rails.cache.delete(key)` (app cache), `@cached_value = nil` (memoization), `reload` (association cache).

## Stale Cache Detection

Routing caches storing record IDs cause sporadic 404s when cached IDs no longer exist. Use atomic fetch with stampede prevention:

```ruby
record = Rails.cache.fetch(cache_key,
                          expires_in: 10.seconds,
                          race_condition_ttl: 5.seconds) do
  find_by(name: lookup_name)
end
```

Simpler alternative: for indexed lookups (<1ms), shrink TTL from minutes to 10 seconds — zero logic changes, reduces risk 6-30x.

## Cache TTL Selection

| TTL | Use Case | Recommendation |
|-----|----------|----------------|
| 10s | Routing/resolution (subdomain, dealer) | Default for routing |
| 30s | Stable data, higher traffic | Good middle ground |
| 1min | Very stable data | Maximum for routing |
| 5min+ | Static reference data | Avoid for routing |

For security-critical paths (multi-tenant resolution, auth): consider removing cache entirely. ~2ms per-request cost is negligible vs. data breach risk.

## Request-Scoped Caching for Current.* Attributes

Check if already set before calling the setter — without early return, each partial/helper call re-evaluates:

```ruby
def current_master_sale
  return Current.master_sale if Current.master_sale.present?
  set_current_master_sale
end
```

## Log Volume Reduction

Enable lograge to suppress ActionView render notifications (90% log reduction):

```ruby
config.lograge.enabled = true
config.lograge.ignore_actions = ['HealthController#index']
ActiveSupport::Notifications.unsubscribe("render_template.action_view")
ActiveSupport::Notifications.unsubscribe("render_partial.action_view")
```
