---
name: activerecord-idempotent-create-patterns
description: "Idempotent API endpoints using find_or_create_by! to prevent race conditions and duplicate records. Covers case-insensitive dedup, whitespace normalization, guard pattern vs idempotent pattern, and frontend debouncing. Trigger keywords: idempotent, find_or_create_by, race condition, check-then-act, duplicate records, guard pattern vs idempotence, uniqueness violation, find_or_create_by!. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Idempotent Create Patterns

## The Problem: Check-Then-Act Race Condition

```ruby
# ANTI-PATTERN - Race condition window between check and create
def perform(name:, sale:)
  cleaned_name = name.strip
  return false if Record.where(sale: sale, name: cleaned_name).length.positive?
  # Another request can create here!
  record = Record.create!(name: cleaned_name, sale_id: sale.id)
end
```

Two concurrent requests both check, both find nothing, both try to create → uniqueness violation on the second.

## Atomic find_or_create_by!

### Simple Atomic Create

```ruby
def perform(name:, sale:)
  cleaned_name = name.strip

  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1  # Block only executes when creating
    new_record.slug = cleaned_name.parameterize
  end
end
```

**Requires a database-level uniqueness constraint** for true atomicity. With the constraint, race conditions resolve via retry: one request creates, the other hits uniqueness violation, retries, and finds the just-created record.

### Case-Insensitive Duplicate Prevention

`find_or_create_by!` uses exact match. Add case-insensitive check first.

```ruby
def perform(name:, sale:)
  cleaned_name = name.strip

  # Case-insensitive duplicate check
  existing = Record
    .where(sale: sale, parent_id: parent_id)
    .find_by('LOWER(name) = ?', cleaned_name.downcase)
  return existing if existing.present?

  # Atomic create (exact case preserved)
  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1
    new_record.slug = cleaned_name.parameterize
  end
end
```

For true atomicity on case-insensitive uniqueness, use a database-level index: `add_index :records, 'LOWER(name), parent_id', unique: true` (requires migration).

## Guard Pattern vs Idempotent Pattern

| Condition | Return Value | Pattern |
|-----------|--------------|---------|
| Input validation failed (blank, nil) | `false` or raise | **Guard** - Invalid input is an error |
| Required association missing | `false` or raise | **Guard** - Cannot proceed |
| Duplicate record exists | Existing record | **Idempotent** - Duplicate is valid state |
| Concurrent creation (race condition) | Existing record | **Idempotent** - Return winner |

**`false` means** "operation failed due to invalid input." **`false` does NOT mean** "record already exists" (that's success).

```ruby
def perform(name:, sale:)
  cleaned_name = name.strip
  return false if cleaned_name.blank?   # Guard: invalid input
  return false if sale.blank?            # Guard: missing required data

  existing = Record.where(sale: sale, parent_id: parent_id)
    .find_by('LOWER(name) = ?', cleaned_name.downcase)
  return existing if existing.present?   # Idempotent: return existing record

  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name)
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.info("Concurrent creation detected: #{e.message}")
  Record.find_by('LOWER(name) = ?', cleaned_name.downcase)  # Return the winner
end
```

## Testing Idempotence

```ruby
test 'calling twice returns same record' do
  post create_path, params: { name: 'Electronics' }
  assert_response :created
  first_id = JSON.parse(response.body)['id']

  post create_path, params: { name: 'Electronics' }
  assert_response :created
  second_id = JSON.parse(response.body)['id']

  assert_equal first_id, second_id, 'Should return same ID (idempotent)'
  assert_equal 1, Record.where(name: 'Electronics').count
end

test 'prevents case-insensitive duplicates' do
  post create_path, params: { name: 'Electronics' }
  first_id = JSON.parse(response.body)['id']

  post create_path, params: { name: 'electronics' }
  second_id = JSON.parse(response.body)['id']

  assert_equal first_id, second_id
  assert_equal 'Electronics', Record.find(first_id).name  # Original case preserved
end
```
