---
name: activerecord-idempotent-create-patterns
description: "Idempotent API endpoints using find_or_create_by! to prevent duplicate records on retries."
license: MIT
metadata:
  category: rails
  author: ngpestelos
  version: "2.1.1"
---

# ActiveRecord Idempotent Create Patterns

## The Race Condition

Check-then-act is not atomic. Two concurrent requests both check, both find nothing, both create → uniqueness violation.

```ruby
# WRONG - Race condition window between check and create
def perform(name:, sale:)
  cleaned_name = name.strip
  return false if Record.where(sale: sale, name: cleaned_name).length.positive?
  # Another request can create here!
  Record.create!(name: cleaned_name, sale_id: sale.id)
end

# RIGHT - Race-condition-recovering find-or-create
def perform(name:, sale:)
  cleaned_name = name.strip
  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1  # Block only executes when creating
    new_record.slug = cleaned_name.parameterize
  end
end
```

**Important**: `find_or_create_by!` is **NOT atomic**. It runs SELECT first, then INSERT if no record found. There is a race condition window between these operations. However, with a database-level uniqueness constraint, the race is detected and resolved: one request creates, the other hits `RecordNotUnique`, rescues, and finds the existing record.

## Choosing Between Methods

Rails provides two approaches with inverted trade-offs:

| Method | Strategy | Best When | Race Window |
|--------|----------|-----------|-------------|
| `find_or_create_by!` | SELECT → INSERT | Record likely **EXISTS** | SELECT→INSERT (common under contention) |
| `create_or_find_by!` | INSERT → SELECT | Record likely **DOESN'T exist** | INSERT→SELECT (rare — requires DELETE to interleave) |

**Use `create_or_find_by!` when**: High insert contention, idempotent endpoints, background job deduplication — most calls are for new records.

**Requirements for `create_or_find_by!`**: Database unique constraints **required**; uniqueness validations on those columns must be **removed** (they break the exception flow).

Both methods require database-level uniqueness constraints to prevent duplicates under concurrency.

## Case-Insensitive Duplicate Prevention

`find_or_create_by!` uses exact match. For case-insensitive matching, you have two options:

### Option 1: Functional Index (Race-Safe)

The only race-safe approach for case-insensitive uniqueness:

```ruby
# Migration
add_index :records, 'LOWER(name), parent_id', unique: true

# Model
def perform(name:, sale:)
  cleaned_name = name.strip
  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1
    new_record.slug = cleaned_name.parameterize
  end
end
```

### Option 2: Pre-Check Pattern (Best-Effort)

Reduces duplicates but **does not eliminate race conditions**:

```ruby
def perform(name:, sale:)
  cleaned_name = name.strip

  # Check first (best effort, not atomic)
  existing = Record.where(sale: sale, parent_id: parent_id)
    .find_by('LOWER(name) = ?', cleaned_name.downcase)
  return existing if existing.present?

  # Race window still exists here!
  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1
    new_record.slug = cleaned_name.parameterize
  end
rescue ActiveRecord::RecordNotUnique  # Catches unique constraint violation
  # Another thread created it — find and return the winner
  Record.find_by('LOWER(name) = ?', cleaned_name.downcase)
end
```

**Note**: Rescues `RecordNotUnique` (database constraint violation), not `RecordInvalid` (validation error).

## Guard Pattern vs Idempotent Pattern

| Condition | Return Value | Pattern |
|-----------|--------------|---------|
| Input validation failed (blank, nil) | `false` or raise | **Guard** — invalid input is an error |
| Required association missing | `false` or raise | **Guard** — cannot proceed |
| Duplicate record exists | Existing record | **Idempotent** — duplicate is valid state |
| Concurrent creation (race condition) | Existing record | **Idempotent** — return winner |

**`false` means** "operation failed due to invalid input." **`false` does NOT mean** "record already exists" (that's success).
