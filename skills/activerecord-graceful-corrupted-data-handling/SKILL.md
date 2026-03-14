---
name: activerecord-graceful-corrupted-data-handling
description: "Graceful handling of missing/corrupted foreign key data: .find_by instead of .find for optional lookups, safe navigation with fallbacks, callback nil guards with throw(:abort), and defense-in-depth logging. Trigger keywords: ActiveRecord::RecordNotFound, .find_by, corrupted ID, 404 page, safe navigation, callback nil guard, throw(:abort). (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Graceful Corrupted Data Handling

## Core Principles

1. **Use `.find_by()` for optional lookups** - Returns nil instead of raising exception when ID doesn't exist or is corrupted
2. **Safe navigation for display methods** - Use `&.` with fallback values to display raw data when association missing
3. **Preserve data visibility** - Show corrupted values as-is rather than hiding entire records
4. **Test both valid and corrupted scenarios** - Verify graceful degradation works with missing IDs and text values

## Problem Pattern

### Failure Chain

Corrupted foreign key data (e.g., text instead of numeric ID) causes `.find()` to raise `ActiveRecord::RecordNotFound`. Template rendering crashes, `rescue_from` intercepts, renders 404 instead of the record's details page. Valid data becomes inaccessible because of a single corrupted field.

```ruby
# Model: .find() raises on corrupted value
def dropdown_option
  custom_field.dropdown_options.find(value)  # Raises exception!
end

# Template calls display method -> crashes
<%= custom_value.display_format %>  # Calls dropdown_option.name

# Controller rescues -> generic 404
rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
```

## Defense-in-Depth Strategy

| Layer | Purpose | Implementation |
|-------|---------|----------------|
| **1. Query method** (primary) | Prevent the exception | `.find_by(id: value)` returns nil |
| **2. Display method** (defensive) | Handle nil gracefully | `association&.name \|\| value.to_s.upcase` |
| **3. Enhanced logging** (diagnostic) | Enable rapid diagnosis | Log exception class, message, backtrace in handler |

## REQUIRED Patterns

### Pattern 1: Use `.find_by()` for Optional Lookups

```ruby
# WRONG - Raises exception for missing/corrupted IDs
def dropdown_option
  custom_field.dropdown_options.find(value)
end

# CORRECT - Returns nil for missing/corrupted IDs
def dropdown_option
  custom_field.dropdown_options.find_by(id: value)
end
```

### Pattern 2: Safe Navigation with Fallback Values

```ruby
# WRONG - Crashes when dropdown_option is nil
def display_format
  case custom_field.field_type
  when 'dropdown_option'
    dropdown_option.name  # NoMethodError if nil
  else
    value.upcase
  end
end

# CORRECT - Falls back to raw value when association missing
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

### Pattern 3: Enhanced Logging for Diagnosis

```ruby
# CORRECT - Logs exception details for debugging
def record_not_found(exception)
  if Rails.env.development?
    Rails.logger.error { "RecordNotFound - Exception: #{exception.class.name}" }
    Rails.logger.error { "RecordNotFound - Message: #{exception.message}" }
    Rails.logger.error { "RecordNotFound - Backtrace:\n#{exception.backtrace[0..10].join("\n")}" }
  end

  respond_to do |format|
    format.html { render plain: 'Not Found', status: :not_found }
    format.csv { render plain: 'Not Found', status: :not_found }
    format.any { head :not_found }
  end
end
```

### Pattern 4: Callback Nil Guards with throw(:abort)

```ruby
# WRONG - Crashes if OptionType doesn't exist
def match_option_value
  self.option_value = ::OptionType.find_by(name: 'Size')
                                   .option_values.find_or_create_by(name: name, presentation: name)
end

# CORRECT - Guard + throw(:abort) to halt callback chain
def match_option_value
  size_option_type = ::OptionType.find_by(name: 'Size')

  unless size_option_type
    errors.add(:base, 'Size option type not configured. Please contact support.')
    throw(:abort)  # Required in Rails 5+; returning false does NOT halt callbacks
  end

  self.option_value = size_option_type.option_values.find_or_create_by(
    name: name, presentation: name
  )
end
```

## FORBIDDEN Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| `.find(value)` for optional lookups | Crashes entire page for single corrupted field | `.find_by(id: value)` |
| No fallback for nil association | `dropdown_option.name` -> NoMethodError | `dropdown_option&.name \|\| fallback` |
| Silent error swallowing (`rescue nil`) | Masks data integrity issues | `.find_by` + logging |
| Generic handler without logging | Impossible to diagnose which field is corrupted | Log exception class, message, backtrace |
| Chaining on `find_by` result | `.find_by(...).option_values` -> NoMethodError on nil | Guard clause + `throw(:abort)` |
| Hiding corrupted data with `"-"` placeholder | User can't see what the value actually is | `value.to_s.upcase` as fallback |

## Regression Testing

```ruby
# Valid lookup
test 'dropdown_option returns the option when it exists' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: @dropdown_option.id.to_s)
  assert_equal @dropdown_option, custom_value.dropdown_option
  assert_equal @dropdown_option.name, custom_value.display_format
end

# Missing ID
test 'dropdown_option returns nil when dropdown option does not exist' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: '999999')
  assert_nil custom_value.dropdown_option
end

test 'display_format falls back to raw value when dropdown option is missing' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: '999999')
  assert_equal '999999', custom_value.display_format
end

# Corrupted text value
test 'dropdown_option returns nil when value is corrupted text instead of ID' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: 'SOME TEXT VALUE INSTEAD OF ID')
  assert_nil custom_value.dropdown_option
end

test 'display_format falls back to uppercase corrupted value' do
  custom_value = CustomValue.create!(record: @record, custom_field: @custom_field,
                                     value: 'SOME TEXT VALUE INSTEAD OF ID')
  assert_equal 'SOME TEXT VALUE INSTEAD OF ID', custom_value.display_format
end

# Integration: page renders with corrupted data
test 'record details page renders successfully with missing dropdown option' do
  CustomValue.create!(record: @record, custom_field: @custom_field, value: '999999')
  get "/records/#{@record.id}"
  assert_response :success
  assert_includes response.body, @record.name
end

test 'record details page renders with corrupted text value in dropdown field' do
  CustomValue.create!(record: @record, custom_field: @custom_field,
                       value: 'CORRUPTED TEXT VALUE')
  get "/records/#{@record.id}"
  assert_response :success
  assert_includes response.body, 'CORRUPTED TEXT VALUE'
end
```

## Quick Diagnostic Checklist

When you see `ActiveRecord::RecordNotFound` in production or tests:

1. **Check stacktrace** -> Identify model file and method causing exception
2. **Check exception message** -> Extract the corrupted value (e.g., "Couldn't find X with 'id'=Y")
3. **Identify lookup pattern** -> `.find(value)` or `.find_by(id: value)`?
4. **Check display methods** -> Do they handle nil associations gracefully?
5. **Determine data corruption** -> Is the foreign key text instead of numeric ID?
6. **Apply fix**: `.find_by(id: value)` + `&.name || fallback` + enhanced logging
7. **Add tests** -> Valid, missing ID, corrupted text, integration

## Violation Detection

```bash
# Find .find() on association chains
grep -rn "\.dropdown_options\.find(\|\.custom_fields\.find(\|\.items\.find(" app/models/ --include="*.rb"

# Find .find(variable) patterns (high risk for corruption)
grep -rn "\.find(value\|\.find(id\|\.find(code" app/models/ --include="*.rb"

# Find display methods without safe navigation
grep -rn "def display_format\|def display_value\|def display_name" app/models/ -A 5 | \
  grep -v "&\.\||| \|if.*nil"

# Find exception handlers without logging
grep -rn "rescue_from ActiveRecord::RecordNotFound" app/controllers/ -A 5 | \
  grep -v "Rails.logger\|logger\."

# Find callbacks that chain on find_by results
grep -rn "find_by.*\.\w\+\." app/models/ --include="*.rb" | grep -E "before_|after_"
```
