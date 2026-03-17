---
name: activerecord-graceful-corrupted-data-handling
description: "Graceful handling of missing/corrupted foreign key data: .find_by instead of .find for optional lookups, safe navigation with fallbacks, and callback nil guards with throw(:abort). Trigger keywords: ActiveRecord::RecordNotFound, .find_by, corrupted ID, 404 page, safe navigation, callback nil guard, throw(:abort). (global)"
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# ActiveRecord Graceful Corrupted Data Handling

## Defense-in-Depth Strategy

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **1. Query method** (primary) | Prevent the exception | `.find_by(id: value)` returns nil |
| **2. Display method** (defensive) | Handle nil gracefully | `association&.name \|\| value.to_s.upcase` |
| **3. Logging** (diagnostic) | Enable rapid diagnosis | Log exception class, message, backtrace in handler |

## Patterns

### 1. Use `.find_by()` for Optional Lookups

`.find()` raises `RecordNotFound` on corrupted/missing IDs, crashing template rendering. `.find_by()` returns nil.

```ruby
# WRONG - Raises exception, triggers 404 via rescue_from
def dropdown_option
  custom_field.dropdown_options.find(value)
end

# RIGHT - Returns nil for missing/corrupted IDs
def dropdown_option
  custom_field.dropdown_options.find_by(id: value)
end
```

### 2. Safe Navigation with Fallback Values

Show the raw corrupted value rather than hiding the record. Use `&.` with `||` fallback:

```ruby
# In display methods: safe navigation + raw value fallback
dropdown_option&.name || value.to_s.upcase
```

### 3. Callback Nil Guards with throw(:abort)

In Rails 5+, returning `false` does NOT halt callbacks — use `throw(:abort)`.

```ruby
# WRONG - Crashes if OptionType doesn't exist
def match_option_value
  self.option_value = ::OptionType.find_by(name: 'Size')
                                   .option_values.find_or_create_by(name: name, presentation: name)
end

# RIGHT - Guard + throw(:abort) to halt callback chain
def match_option_value
  size_option_type = ::OptionType.find_by(name: 'Size')

  unless size_option_type
    errors.add(:base, 'Size option type not configured. Please contact support.')
    throw(:abort)
  end

  self.option_value = size_option_type.option_values.find_or_create_by(
    name: name, presentation: name
  )
end
```
