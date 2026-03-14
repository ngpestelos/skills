---
name: activerecord-transaction-boundary-optimization
description: "Optimizes ActiveRecord transaction boundaries by moving read operations outside transaction blocks to reduce lock time and contention. Covers pre-fetching, backward-compatible signatures, and minimizing scope. Trigger keywords: transaction optimization, lock contention, transaction boundary, read inside transaction, pre-fetch before transaction, minimize transaction scope, transaction deadlock prevention. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveRecord Transaction Boundary Optimization

## Pre-fetch Reads Outside Transaction

Move read operations BEFORE the transaction starts. Transactions hold database locks — reads inside extend lock time unnecessarily.

```ruby
# WRONG - Reads inside transaction extend lock time
def process_records(product, dest_sale)
  ActiveRecord::Base.transaction do
    source_records = Record.where(id: record_ids).index_by(&:id)
    dest_records = dest_sale.records.index_by(&:name)

    Classification.insert_all!(records)
  end
end

# RIGHT - Pre-fetch reads, only writes in transaction
def process_records(product, dest_sale)
  source_record_ids = product.classifications.map(&:record_id).compact
  source_records = source_record_ids.any? ? Record.where(id: source_record_ids).index_by(&:id) : {}
  dest_records = dest_sale.records.index_by(&:name)

  ActiveRecord::Base.transaction do
    records = build_records_from_prefetched_data(source_records, dest_records)
    Classification.insert_all!(records)
  end
end
```

## Backward Compatible Method Signatures

Add optional parameters for pre-fetched data so callers can opt in without breaking existing code.

```ruby
def clone_classifications(cloned_product, uncategorized = nil, source_records_prefetch = nil, dest_records_prefetch = nil)
  if source_records_prefetch && dest_records_prefetch
    source_records = source_records_prefetch
    dest_records = dest_records_prefetch
  else
    # Fallback to fetching (standalone usage)
    source_record_ids = classifications.map(&:record_id).compact
    source_records = Record.where(id: source_record_ids).index_by(&:id)
    dest_records = dest_sale.records.index_by(&:name)
  end

  # Rest of method uses source_records and dest_records
end
```

## Preserving Atomicity

Never split related writes across separate transactions to "optimize." Atomicity requires related writes to succeed or fail together.

```ruby
# WRONG - Related writes split across transactions
def clone_product(source, dest_sale)
  records = fetch_records

  ActiveRecord::Base.transaction do
    cloned_product = create_product(source, dest_sale)
  end

  ActiveRecord::Base.transaction do
    create_classifications(cloned_product, records)  # Orphaned if first tx rolled back!
  end
end

# RIGHT - Related writes stay together, reads outside
def clone_product(source, dest_sale)
  records = fetch_records

  ActiveRecord::Base.transaction do
    cloned_product = create_product(source, dest_sale)
    create_classifications(cloned_product, records)
  end
end
```

Don't remove transactions to optimize. Instead, move reads outside while keeping writes protected. For writes requiring read-consistency (e.g., balance updates), use `Account.lock.find(id)` inside the transaction.

## Decision Tree

| Operation inside transaction | Action |
|------------------------------|--------|
| Read that doesn't need uncommitted data | Move outside |
| Read that needs `lock` for write consistency | Keep inside with `.lock` |
| Write related to other writes in same tx | Keep together |
| Write truly independent of other writes | Can be separate transaction |
