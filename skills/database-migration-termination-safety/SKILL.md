---
name: database-migration-termination-safety
description: Guidance on what happens when database migrations are terminated mid-execution, how to design safe recoverable migrations, and running long migrations on Heroku. Covers index creation termination, concurrent index safety, data migration batching, invalid index cleanup, and idempotent design.
license: MIT
compatibility: Ruby on Rails with PostgreSQL. Heroku section requires Heroku CLI.
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# Database Migration Termination Safety

> **Purpose**: Know what happens when migrations are terminated mid-execution, design safe recoverable migrations, and run long migrations on Heroku.

## Termination Safety Reference

| Operation | Safe? | What Happens on Termination | Recovery |
|-----------|-------|----------------------------|----------|
| `add_index` | Yes | Transaction rolls back, no partial index, table unlocks | Re-run migration |
| `add_column` | Yes | Transaction rolls back cleanly | Re-run migration |
| `CREATE INDEX CONCURRENTLY` | **No** | May leave invalid index (non-transactional) | Drop invalid index, re-run |
| `update_all` (unbatched) | **No** | Partial update, no way to know which rows processed | Manual data audit |
| Batched update with idempotent WHERE | Yes | Completed batches persist, remaining batches re-run | Re-run migration |

## Concurrent Index Example

```ruby
class AddIndexConcurrently < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!  # REQUIRED for CONCURRENTLY

  def up
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_id
      ON orders (customer_id);
    SQL
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_orders_customer_id;'
  end
end
```

## Invalid Index Detection and Cleanup

```sql
-- Check for invalid indexes
SELECT indexrelid::regclass AS index_name, indrelid::regclass AS table_name
FROM pg_index WHERE NOT indisvalid;

-- Clean up
DROP INDEX CONCURRENTLY IF EXISTS idx_invalid_name;
```

## Batched Data Migration Example

```ruby
Order.where(status: nil).find_in_batches(batch_size: 1000) do |batch|
  Order.where(id: batch.map(&:id)).update_all(status: 'pending')
  sleep 0.1  # Reduce database load
end
```

See [references/heroku-long-migrations.md](references/heroku-long-migrations.md) for Heroku-specific timeout layers, detached mode execution, and monitoring commands.
