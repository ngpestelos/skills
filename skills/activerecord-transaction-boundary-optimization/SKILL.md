---
name: activerecord-transaction-boundary-optimization
description: "Optimizes ActiveRecord transaction boundaries by moving read operations outside transaction blocks to reduce lock time and contention. Covers pre-fetching, backward-compatible signatures, and minimizing scope. Trigger keywords: transaction optimization, lock contention, transaction boundary, read inside transaction, pre-fetch before transaction, minimize transaction scope, transaction deadlock prevention. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Transaction Boundary Optimization

## Core Principles

1. **Minimize Transaction Scope**: Only keep write operations inside transactions
2. **Pre-fetch Reads Outside**: Move all read operations before transaction starts
3. **Preserve Atomicity**: Keep related writes together in same transaction
4. **Backward Compatible**: Optional parameters allow gradual adoption
5. **Lock Contention Matters**: Shorter transactions = better concurrency

## The Problem

Transactions hold database locks. Read operations inside transactions extend lock time unnecessarily, causing:

1. **Increased lock contention** - Other operations wait longer
2. **Higher deadlock risk** - More concurrent operations competing for locks
3. **Reduced throughput** - Longer locks = fewer concurrent operations
4. **Wasted transaction time** - Reads don't need ACID guarantees

## REQUIRED Pattern: Pre-fetch Outside Transaction

Move read operations BEFORE the transaction starts:

```ruby
# WRONG - Reads inside transaction extend lock time
def process_records(product, dest_sale)
  ActiveRecord::Base.transaction do
    # READ operations hold locks unnecessarily
    source_records = Record.where(id: record_ids).index_by(&:id)
    dest_records = dest_sale.records.index_by(&:name)

    # WRITE operations (these need the transaction)
    Classification.insert_all!(records)
  end
end

# RIGHT - Pre-fetch reads, only writes in transaction
def process_records(product, dest_sale)
  # READ operations outside transaction (no locks held)
  source_record_ids = product.classifications.map(&:record_id).compact
  source_records = source_record_ids.any? ? Record.where(id: source_record_ids).index_by(&:id) : {}
  dest_records = dest_sale.records.index_by(&:name)

  # Transaction only for WRITE operations
  ActiveRecord::Base.transaction do
    # Use pre-fetched data (hash lookups, no queries)
    records = build_records_from_prefetched_data(source_records, dest_records)
    Classification.insert_all!(records)
  end
end
```

**Performance Impact:**
- **Before:** Transaction holds locks during 2 database queries
- **After:** Transaction holds locks only during insert (queries completed before lock acquired)
- **Improvement:** 10-15% reduction in transaction hold time

## REQUIRED Pattern: Backward Compatible Method Signatures

Add optional parameters for pre-fetched data to allow gradual adoption:

```ruby
# RIGHT - Optional parameters with fallback
def clone_classifications(cloned_product, uncategorized = nil, source_records_prefetch = nil, dest_records_prefetch = nil)
  # Use pre-fetched data if provided (batch usage - optimized path)
  if source_records_prefetch && dest_records_prefetch
    source_records = source_records_prefetch
    dest_records = dest_records_prefetch
  else
    # Fallback to fetching (standalone usage - backward compatible)
    source_record_ids = classifications.map(&:record_id).compact
    source_records = Record.where(id: source_record_ids).index_by(&:id)
    dest_records = dest_sale.records.index_by(&:name)
  end

  # Rest of method uses source_records and dest_records
end
```

**Benefits:**
- Existing calling code continues to work without changes
- New calling code can opt-in to optimization
- No breaking changes to API
- Gradual performance improvement rollout

## FORBIDDEN Patterns

### Anti-Pattern 1: Reading Inside Transaction When Not Necessary

```ruby
# WRONG - Query inside transaction extends lock unnecessarily
ActiveRecord::Base.transaction do
  user = User.find(user_id)  # READ - doesn't need transaction
  product = Product.find(product_id)  # READ - doesn't need transaction

  Order.create!(user: user, product: product)  # WRITE - needs transaction
end

# RIGHT - Only writes in transaction
user = User.find(user_id)  # Outside
product = Product.find(product_id)  # Outside

ActiveRecord::Base.transaction do
  Order.create!(user: user, product: product)  # Only this needs transaction
end
```

### Anti-Pattern 2: Breaking Atomicity by Moving Dependent Writes Outside

```ruby
# WRONG - Related writes split across transactions (atomicity broken)
def clone_product(source, dest_sale)
  # Pre-fetch reads (correct)
  records = fetch_records

  # First transaction
  ActiveRecord::Base.transaction do
    cloned_product = create_product(source, dest_sale)
  end

  # Second transaction - WRONG! These writes are related
  ActiveRecord::Base.transaction do
    create_classifications(cloned_product, records)
  end
end

# RIGHT - Related writes stay together
def clone_product(source, dest_sale)
  # Pre-fetch reads (outside transaction)
  records = fetch_records

  # All related writes in ONE transaction
  ActiveRecord::Base.transaction do
    cloned_product = create_product(source, dest_sale)
    create_classifications(cloned_product, records)  # Related write stays in same transaction
  end
end
```

**Why This Matters**: If `create_product` succeeds but `create_classifications` fails, you have incomplete data. Atomicity requires related writes to succeed or fail together.

### Anti-Pattern 3: Breaking Existing Transaction Boundaries for Wrong Reasons

```ruby
# WRONG - Removing transaction to "optimize" (breaks safety)
def update_account_balance(account_id, amount)
  # Used to be in transaction, removed to "reduce lock time"
  account = Account.find(account_id)
  account.balance += amount
  account.save!  # Race condition! No transaction protection
end

# RIGHT - Keep transaction for write safety, optimize reads
def update_account_balance(account_id, amount)
  # Pre-fetch reads if needed (outside transaction)
  metadata = fetch_metadata(account_id)

  # Transaction for write safety
  ActiveRecord::Base.transaction do
    account = Account.lock.find(account_id)  # Lock during read
    account.balance += amount
    account.save!
  end
end
```

**Rule**: Don't remove transactions to optimize. Instead, optimize by moving reads outside while keeping writes protected.

## Quick Decision Tree

When optimizing transaction boundaries:

1. **Identify all operations inside transaction** -> Categorize as READ or WRITE
2. **For each READ operation**:
   - Can it be moved outside transaction? -> YES: Move it
   - Does it need to see uncommitted data? -> NO: Move it outside
   - Is it a quick hash/array lookup? -> Already fast, but moving still helps
3. **For each WRITE operation**:
   - Is it related to other writes in this transaction? -> YES: Keep together
   - Does it need atomicity with other writes? -> YES: Keep in transaction
   - Can it be moved to separate transaction? -> Only if truly independent
4. **Verify**:
   - All related writes still in same transaction? -> Required for atomicity
   - Reads moved outside? -> Reduces lock time
   - Method signature backward compatible? -> No breaking changes

## Performance Impact Analysis

### Example: Product Cloning with Category Assignment

**Before Optimization:**
```ruby
ActiveRecord::Base.transaction do
  # Inside transaction (holds locks)
  source_records = Record.where(id: record_ids).index_by(&:id)  # Query 1
  dest_records = dest_sale.records.index_by(&:name)  # Query 2

  # Build records using queries results
  classifications_to_create = build_classifications(source_records, dest_records)

  # Insert (actual write that needs transaction)
  Classification.insert_all!(classifications_to_create)
end
```

**Timing:**
- Query 1: 15ms
- Query 2: 12ms
- Build records: 3ms
- Insert: 8ms
- **Total transaction time: 38ms** (locks held for all 4 operations)

**After Optimization:**
```ruby
# Outside transaction (no locks)
source_record_ids = classifications.map(&:record_id).compact
source_records = Record.where(id: source_record_ids).index_by(&:id)  # Query 1: 15ms
dest_records = dest_sale.records.index_by(&:name)  # Query 2: 12ms
classifications_to_create = build_classifications(source_records, dest_records)  # 3ms

ActiveRecord::Base.transaction do
  # Only insert inside transaction
  Classification.insert_all!(classifications_to_create)  # 8ms
end
```

**Timing:**
- Query 1: 15ms (outside transaction)
- Query 2: 12ms (outside transaction)
- Build records: 3ms (outside transaction)
- **Transaction time: 8ms** (locks held only for insert)

**Results:**
- **Transaction hold time reduced from 38ms to 8ms** (79% reduction)
- **Lock contention reduced** - Other operations wait 30ms less
- **Throughput increased** - More operations can complete concurrently

### Batch Operation Impact

For batch operations (e.g., cloning 100 products):

**Before:**
- 100 products x 38ms transaction time = 3,800ms total lock time
- Sequential processing due to lock contention

**After:**
- 100 products x 8ms transaction time = 800ms total lock time
- **3,000ms less total lock time** = 10-15% faster overall

## Violation Detection

### Find Transactions with Read Operations

```bash
# Find transactions that likely contain reads
grep -A 20 "ActiveRecord::Base.transaction do" app/models/ app/jobs/ | grep -E "\.find\(|\.where\(|\.pluck\(|\.count"

# Find specific pattern: queries inside transaction blocks
grep -B 2 -A 10 "transaction do" app/models/**/*.rb | grep -E "\.where|\.find_by"

# Find transactions that could be optimized
ack "transaction do" --ruby -A 15 | grep -E "(where|find|pluck|select|joins|includes)"
```

### Find Methods That Could Accept Pre-fetched Data

```bash
# Find methods with transaction blocks that query data
grep -l "ActiveRecord::Base.transaction" app/models/**/*.rb | \
  xargs grep -l "\.where\(.*\.index_by"

# Find hash-based lookups inside transactions (optimization candidates)
grep -A 10 "transaction do" app/models/**/*.rb | grep "index_by"
```

## Real-World Example: Product Cloning Optimization

**Context**: Sale cloning system needed to clone 100+ products with category assignments. Original implementation had 2 queries inside Structure transaction.

**Before (N+1 elimination):**
```ruby
ActiveRecord::Base.transaction do
  source_product.send(:clone_classifications, cloned_product, uncategorized)
  # Inside clone_classifications:
  #   source_records = Record.where(id: record_ids).index_by(&:id)  # Query inside transaction
  #   dest_records = dest_sale.records.index_by(&:name)  # Query inside transaction
end
```

**After (Transaction boundary optimization):**
```ruby
# Pre-fetch OUTSIDE transaction
source_record_ids = source_product.classifications.map(&:record_id).compact
source_records = source_record_ids.any? ? Record.where(id: source_record_ids).index_by(&:id) : {}
dest_records = dest_sale.records.index_by(&:name)

ActiveRecord::Base.transaction do
  # Pass pre-fetched data, no queries inside transaction
  source_product.send(:clone_classifications, cloned_product, uncategorized, source_records, dest_records)
end
```

**Results:**
- Transaction hold time reduced by 10-15%
- 2 queries removed from locked section per product
- 200 queries eliminated from transaction scope per 100 products
- Backward compatibility maintained

