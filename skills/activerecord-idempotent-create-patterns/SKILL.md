---
name: activerecord-idempotent-create-patterns
description: "Idempotent API endpoints using find_or_create_by! to prevent race conditions and duplicate records. Covers case-insensitive dedup, whitespace normalization, guard pattern vs idempotent pattern, and frontend debouncing. Trigger keywords: idempotent, find_or_create_by, race condition, check-then-act, duplicate records, guard pattern vs idempotence, uniqueness violation, find_or_create_by!. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Idempotent Create Patterns

## Core Principles

1. **Atomicity**: Use database-level atomic operations (find_or_create_by!) instead of application-level checks
2. **Idempotence**: Same input should always produce same output (return existing record, not error)
3. **Case-Insensitive**: Prevent "Electronics" and "electronics" duplicates with explicit checks
4. **Whitespace Normalization**: Strip whitespace before duplicate checks (`"  Nike  "` -> `"Nike"`)
5. **Transaction Wrapping**: Multi-step operations need transactions for atomicity
6. **Return vs Raise**: Return existing records for idempotence, only raise on unexpected errors

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

Two concurrent requests both check, both find nothing, both try to create -> uniqueness violation on the second.

## REQUIRED Pattern: Atomic find_or_create_by!

### Solution 1: Simple Atomic Create

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

### Solution 2: Case-Insensitive Duplicate Prevention

`find_or_create_by!` uses exact match. Add case-insensitive check first:

```ruby
def perform(name:, sale:)
  cleaned_name = name.strip

  # Step 1: Case-insensitive duplicate check
  existing = Record
    .where(sale: sale, parent_id: parent_id)
    .find_by('LOWER(name) = ?', cleaned_name.downcase)
  return existing if existing.present?

  # Step 2: Atomic create (exact case preserved)
  Record.find_or_create_by!(sale: sale, parent_id: parent_id, name: cleaned_name) do |new_record|
    new_record.position = 1
    new_record.slug = cleaned_name.parameterize
  end
end
```

### Solution 3: Global Scoping (Non-Tenant Records)

For records scoped by `parent_id` instead of tenant:

```ruby
def perform(name:, product:)
  cleaned_name = name.to_s.strip
  return nil if cleaned_name.blank?

  taxonomy = Taxonomy.find_by(name: 'Brands')
  return nil if taxonomy.blank?
  taxonomy_root = taxonomy.root

  # Case-insensitive check with parent_id scoping
  existing = Record
    .where(taxonomy: taxonomy, parent_id: taxonomy_root.id)
    .find_by('LOWER(name) = ?', cleaned_name.downcase)

  record = if existing.present?
    existing
  else
    Record.find_or_create_by!(
      taxonomy: taxonomy, parent_id: taxonomy_root.id, name: cleaned_name
    ) do |new_record|
      new_record.position = 1
      new_record.slug = cleaned_name.parameterize
    end
  end

  # Product assignment works for both new and existing
  record
end
```

## Transaction Wrapping for Multi-Step Operations

```ruby
# WRONG - Orphaned record if assignment fails
record = CreateRecord.perform_now(name: name, sale: sale)
AssignRecord.perform_now(record: record, product: product)  # If this fails, record is orphaned

# CORRECT - Both succeed or both fail
ActiveRecord::Base.transaction do
  record = CreateRecord.perform_now(name: name, sale: sale)
  raise 'Record creation failed' if record.blank?
  AssignRecord.perform_now(record: record, product: product)
  record
end
```

## Guard Pattern vs Idempotent Pattern

| Condition | Return Value | Rationale |
|-----------|--------------|-----------|
| Input validation failed (blank, nil) | `false` or raise | **Guard pattern** - Invalid input is an error |
| Required association missing | `false` or raise | **Guard pattern** - Cannot proceed |
| Duplicate record exists | Existing record | **Idempotent pattern** - Duplicate is valid state |
| Concurrent creation (race condition) | Existing record | **Idempotent pattern** - Return winner |
| Unexpected exception | Raise or `false` | **Error handling** - Log and report |

**`false` means** "operation failed due to invalid input." **`false` does NOT mean** "record already exists" (that's success, not failure).

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

## Case-Insensitive Patterns

| Approach | Pros | Cons |
|----------|------|------|
| **Application-level** `find_by('LOWER(name) = ?', ...)` then `find_or_create_by!` | No migration needed | Two queries, small race window |
| **Database-level** `add_index :records, 'LOWER(name), parent_id', unique: true` | True atomicity | Requires migration |

## Frontend Defense-in-Depth

Frontend debouncing prevents double-clicks but is insufficient alone (can't prevent concurrent requests from different users/API clients). Always pair with idempotent backend.

```javascript
async handleSelectChange(event) {
  if (this._isCreatingResource) return;
  this._isCreatingResource = true;
  try { await this.createRecord(name); }
  finally { this._isCreatingResource = false; }
}
```

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Return `false` for duplicates | Breaks calling code (CreateAndAssign skips assignment) | Return existing record |
| `create!` instead of `find_or_create_by!` | `RecordInvalid` on second call | `find_or_create_by!` |
| Not checking `previous_changes` | Runs position update on existing records | `if record.previous_changes.key?('id')` |
| Case-sensitive uniqueness only | "Electronics" and "electronics" both created | Add `find_by('LOWER(name) = ?', ...)` check |
| Missing whitespace normalization | `"  Nike  "` vs `"Nike"` = duplicates | `name.to_s.strip` before all checks |

## Violation Detection

```bash
# Check-then-act race conditions
grep -rn "where.*length.positive?\|where.*exists?" app/jobs/ | grep -A 5 "create!"
grep -rn "return false if.*where" app/jobs/

# Non-idempotent create patterns
grep -rn "\.create!" app/jobs/ | grep -v "find_or_create"
grep -rn "return false if.*exists?\|return false if.*present?" app/jobs/

# Case-sensitive uniqueness only
grep -rn "validates.*uniqueness" app/models/ | grep -v "case_sensitive: false"
```

## Testing Patterns

```ruby
# Idempotence: same input -> same output
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

# Case-insensitive duplicate prevention
test 'prevents case-insensitive duplicates' do
  post create_path, params: { name: 'Electronics' }
  first_id = JSON.parse(response.body)['id']

  post create_path, params: { name: 'electronics' }
  second_id = JSON.parse(response.body)['id']

  assert_equal first_id, second_id
  assert_equal 1, Record.where('LOWER(name) = ?', 'electronics').count
  assert_equal 'Electronics', Record.find(first_id).name  # Original case preserved
end

# Transaction rollback on failure
test 'rollback record creation if assignment fails' do
  initial_count = Record.count

  AssignRecord.stub :perform_now, ->(*) { raise 'Assignment failed' } do
    assert_raises(RuntimeError) do
      CreateAndAssignRecord.perform_now(name: 'Electronics', sale: @sale, product: @product)
    end
  end

  assert_equal initial_count, Record.count, 'Transaction should rollback'
end
```
