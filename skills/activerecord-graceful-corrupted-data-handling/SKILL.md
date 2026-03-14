---
name: activerecord-graceful-corrupted-data-handling
description: "Graceful handling of missing/corrupted foreign key data: .find_by instead of .find for optional lookups, safe navigation with fallbacks, callback nil guards with throw(:abort), and defense-in-depth logging. Trigger keywords: ActiveRecord::RecordNotFound, .find_by, corrupted ID, 404 page, safe navigation, callback nil guard, throw(:abort). (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Graceful Corrupted Data Handling

## The Problem

Corrupted foreign key data (e.g., text instead of numeric ID) causes `.find()` to raise `ActiveRecord::RecordNotFound`. Template rendering crashes, `rescue_from` intercepts, renders 404 instead of the record's details page. Valid data becomes inaccessible because of a single corrupted field.

```ruby
def dropdown_option
  custom_field.dropdown_options.find(value)  # Raises on corrupted value!
end
```

## Defense-in-Depth Strategy

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **1. Query method** (primary) | Prevent the exception | `.find_by(id: value)` returns nil |
| **2. Display method** (defensive) | Handle nil gracefully | `association&.name \|\| value.to_s.upcase` |
| **3. Enhanced logging** (diagnostic) | Enable rapid diagnosis | Log exception class, message, backtrace in handler |

## Patterns

### 1. Use `.find_by()` for Optional Lookups

```ruby
# WRONG - Raises exception for missing/corrupted IDs
def dropdown_option
  custom_field.dropdown_options.find(value)
end

# RIGHT - Returns nil for missing/corrupted IDs
def dropdown_option
  custom_field.dropdown_options.find_by(id: value)
end
```

### 2. Safe Navigation with Fallback Values

Show the raw corrupted value rather than hiding the record entirely.

```ruby
def display_format
  case custom_field.field_type
  when 'number'
    "##{value}"
  when 'dropdown_option'
    dropdown_option&.name || value.to_s.upcase  # Safe navigation + fallback
  else
    value.upcase
  end
end
```

### 3. Enhanced Logging for Diagnosis

```ruby
def record_not_found(exception)
  if Rails.env.development?
    Rails.logger.error { "RecordNotFound - #{exception.class.name}: #{exception.message}" }
    Rails.logger.error { "Backtrace:\n#{exception.backtrace[0..10].join("\n")}" }
  end

  head :not_found
end
```

### 4. Callback Nil Guards with throw(:abort)

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

## Testing

Test both valid lookups and corrupted data to verify graceful degradation.

```ruby
test 'dropdown_option returns the option when it exists' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: @dropdown_option.id.to_s)
  assert_equal @dropdown_option, custom_value.dropdown_option
  assert_equal @dropdown_option.name, custom_value.display_format
end

test 'display_format falls back to raw value when value is corrupted text' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: 'CORRUPTED TEXT VALUE')
  assert_nil custom_value.dropdown_option
  assert_equal 'CORRUPTED TEXT VALUE', custom_value.display_format
end

test 'record details page renders with corrupted data' do
  CustomValue.create!(record: @record, custom_field: @custom_field,
                       value: 'CORRUPTED TEXT VALUE')
  get "/records/#{@record.id}"
  assert_response :success
  assert_includes response.body, 'CORRUPTED TEXT VALUE'
end
```
