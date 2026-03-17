---
name: activerecord-query-performance-patterns
description: "Three query performance techniques preventing 10-1000x PostgreSQL degradation: ILIKE index usage, two-phase DISTINCT optimization, and UNION ALL OR-splitting. Auto-activates when writing ActiveRecord queries with ILIKE or DISTINCT, debugging slow queries, or implementing search across multiple tables. Trigger keywords: ILIKE, leading wildcard, DISTINCT slow, UNION ALL, cross-table search, pg_trgm."
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# ActiveRecord Query Performance Patterns

For duplicate joins prevention (`.joins().includes()` → 50-70x slowdown), see `activerecord-application-query-optimization`.

## Pattern 1: ILIKE Index Usage — Avoid Leading Wildcards

Leading wildcards (`%pattern%`) prevent B-tree index usage → 800-1000x slower on large tables.

```ruby
# Trailing wildcard only — uses B-tree index
pattern = "#{query.strip}%"
.where('orders.number ILIKE ?', pattern)

# FORBIDDEN: Leading wildcard = full table scan
pattern = "%#{query.strip}%"
```

For true substring matching, create a pg_trgm GIN index: `CREATE EXTENSION IF NOT EXISTS pg_trgm; CREATE INDEX idx_trgm ON table USING gin (column gin_trgm_ops);`

## Pattern 2: Two-Phase DISTINCT Optimization

`.includes()` + `.distinct` generates `SELECT DISTINCT` on ALL columns from ALL included tables (120+ columns). Split into two phases.

```ruby
# Phase 1: DISTINCT on single integer column (fast)
order_ids = Order
  .joins(:store)
  .left_outer_joins(:billing_address)
  .where(conditions)
  .distinct
  .limit(MAX_RESULTS)
  .pluck(:id)  # .pluck returns array — NOT .select (returns Relation)

return [] if order_ids.empty?

# Phase 2: Load full objects (no DISTINCT needed — IDs are unique)
Order
  .includes(:billing_address, store: :organization)
  .where(id: order_ids)
```

## Pattern 3: UNION ALL OR-Splitting for Cross-Table Queries

OR conditions spanning multiple tables prevent index usage, even trigram indexes. Split into separate queries combined with `UNION ALL`. Each branch uses its own optimal index.

```ruby
email_sql     = "SELECT id #{base_sql} AND email ILIKE :pattern"
firstname_sql = "SELECT id #{base_sql} AND EXISTS (SELECT 1 FROM addresses WHERE ...)"
lastname_sql  = "SELECT id #{base_sql} AND EXISTS (SELECT 1 FROM addresses WHERE ...)"

union_sql = "SELECT DISTINCT id FROM (
  (#{email_sql}) UNION ALL (#{firstname_sql}) UNION ALL (#{lastname_sql})
) AS combined LIMIT :limit"

order_ids = ActiveRecord::Base.connection.select_values(sanitized_sql).map(&:to_i)
```

UNION ALL + outer DISTINCT is faster than UNION (which deduplicates per-branch). EXISTS subqueries avoid LEFT JOIN overhead.

## Performance Impact

| Pattern | Before | After | Improvement |
|---------|--------|-------|-------------|
| Leading wildcard ILIKE | Full table scan | Index scan | 800-1000x |
| Wide-row DISTINCT (120+ cols) | 100-500ms | 10-50ms | 10-50x |
| Cross-table OR | 7,000ms | 200-500ms | 14-35x |
