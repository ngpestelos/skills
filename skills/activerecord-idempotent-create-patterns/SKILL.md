---
name: activerecord-idempotent-create-patterns
description: "Idempotent API endpoints using find_or_create_by! to prevent race conditions and duplicate records. Covers case-insensitive dedup, whitespace normalization, and guard pattern vs idempotent pattern. Trigger keywords: idempotent, find_or_create_by, race condition, check-then-act, duplicate records, uniqueness violation. (global)"
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
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

# RIGHT - Atomic find-or-create
def perform(name:, sale:)
  cleaned_name = name.strip
  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1  # Block only executes when creating
    new_record.slug = cleaned_name.parameterize
  end
end
```

**Requires a database-level uniqueness constraint** for true atomicity. With the constraint, race conditions resolve via retry: one creates, the other hits violation, retries, finds the record.

## Case-Insensitive Duplicate Prevention

`find_or_create_by!` uses exact match. Add case-insensitive check first. For concurrent race conditions, rescue `RecordInvalid` and return the winner.

```ruby
def perform(name:, sale:)
  cleaned_name = name.strip

  existing = Record.where(sale: sale, parent_id: parent_id)
    .find_by('LOWER(name) = ?', cleaned_name.downcase)
  return existing if existing.present?

  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1
    new_record.slug = cleaned_name.parameterize
  end
rescue ActiveRecord::RecordInvalid
  Record.find_by('LOWER(name) = ?', cleaned_name.downcase)
end
```

For true case-insensitive atomicity: `add_index :records, 'LOWER(name), parent_id', unique: true`.

## Guard Pattern vs Idempotent Pattern

| Condition | Return Value | Pattern |
|-----------|--------------|---------|
| Input validation failed (blank, nil) | `false` or raise | **Guard** — invalid input is an error |
| Required association missing | `false` or raise | **Guard** — cannot proceed |
| Duplicate record exists | Existing record | **Idempotent** — duplicate is valid state |
| Concurrent creation (race condition) | Existing record | **Idempotent** — return winner |

**`false` means** "operation failed due to invalid input." **`false` does NOT mean** "record already exists" (that's success).
