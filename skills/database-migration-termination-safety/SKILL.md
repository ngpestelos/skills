---
name: database-migration-termination-safety
description: Guidance on what happens when database migrations are terminated mid-execution, how to design safe recoverable migrations, and running long migrations on Heroku. Covers index creation termination, concurrent index safety, data migration batching, lock behavior, invalid index cleanup, and idempotent design.
license: MIT
compatibility: Ruby on Rails with PostgreSQL. Heroku section requires Heroku CLI.
metadata:
  author: ngpestelos
  version: "1.0"
---

# Database Migration Termination Safety

> **Purpose**: Understand what happens when migrations are terminated mid-execution, how to design safe recoverable migrations, and how to run long migrations on Heroku without timeout interruptions.

## Core Principles

1. **Standard DDL is transactional** - Column additions, table changes, and standard indexes roll back cleanly
2. **Concurrent operations are non-transactional** - `CREATE INDEX CONCURRENTLY` can leave invalid indexes
3. **Data migrations need checkpoints** - Large data updates should be batched and idempotent
4. **Idempotency enables recovery** - Use `IF NOT EXISTS`, `IF EXISTS`, and conditional updates
5. **Lock awareness prevents deadlocks** - Understand what locks each operation acquires

## Termination Behavior by Migration Type

### Standard Index (`add_index`)

**If terminated**: Transaction rolls back, no partial index, table unlocks, safe to re-run.

### Concurrent Index (`algorithm: :concurrently`)

**If terminated**: May leave invalid index requiring manual cleanup.

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

### Data Migrations

**Unbatched (DANGEROUS)**: Partial update, no way to know which rows processed.

**Batched (SAFE)**:
```ruby
Order.where(status: nil).find_in_batches(batch_size: 1000) do |batch|
  Order.where(id: batch.map(&:id)).update_all(status: 'pending')
  sleep 0.1  # Reduce database load
end
```

## Required Patterns

1. `CREATE INDEX CONCURRENTLY IF NOT EXISTS`
2. `DROP INDEX CONCURRENTLY IF EXISTS`
3. `find_in_batches(batch_size: 1000)` for data updates
4. `disable_ddl_transaction!` for CONCURRENTLY

## Forbidden Patterns

1. CONCURRENTLY without `IF NOT EXISTS`
2. CONCURRENTLY without `disable_ddl_transaction!`
3. Unbatched large data migrations

## Invalid Index Detection and Cleanup

```sql
-- Check for invalid indexes
SELECT indexrelid::regclass AS index_name, indrelid::regclass AS table_name
FROM pg_index WHERE NOT indisvalid;

-- Clean up
DROP INDEX CONCURRENTLY IF EXISTS idx_invalid_name;
```

## Lock Behavior Reference

| Operation | Lock Type | Blocks Reads | Blocks Writes |
|-----------|-----------|--------------|---------------|
| `CREATE INDEX` | `ShareLock` | No | Yes |
| `CREATE INDEX CONCURRENTLY` | `ShareUpdateExclusiveLock` | No | No |
| `ADD COLUMN` | `AccessExclusiveLock` | Yes (brief) | Yes (brief) |
| `ALTER COLUMN TYPE` | `AccessExclusiveLock` | Yes | Yes |
| `UPDATE` (data migration) | `RowExclusiveLock` | No | Per-row |

## Quick Decision Tree

| Scenario | Termination Safe? | Recovery Action |
|----------|------------------|-----------------|
| Standard `add_index` | Yes | Re-run migration |
| `CREATE INDEX CONCURRENTLY` | **No** | Drop invalid index, re-run |
| `add_column` | Yes | Re-run migration |
| `update_all` (unbatched) | **No** | Manual data audit |
| Batched update with idempotent WHERE | Yes | Re-run migration |

See [references/heroku-long-migrations.md](references/heroku-long-migrations.md) for Heroku-specific timeout layers, detached mode execution, and monitoring commands.
