---
name: activerecord-query-performance-patterns
description: "Four query performance techniques preventing 10-70x PostgreSQL degradation: ILIKE index usage, duplicate joins prevention, two-phase DISTINCT optimization, and UNION ALL OR-splitting. Auto-activates when writing ActiveRecord queries with ILIKE, joins, includes, or DISTINCT, debugging slow queries, or implementing search across multiple tables."
license: MIT
compatibility: Ruby on Rails with PostgreSQL. Patterns apply to any ActiveRecord + PostgreSQL application.
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# ActiveRecord Query Performance Patterns

## Pattern 1: ILIKE Index Usage — Avoid Leading Wildcards

Leading wildcards (`%pattern%`) prevent B-tree index usage → 800-1000x slower on large tables.

### Required Pattern

```ruby
# Trailing wildcard only — uses B-tree index
pattern = "#{query.strip}%"
.where('orders.number ILIKE ?', pattern)

# FORBIDDEN: Leading wildcard = full table scan
pattern = "%#{query.strip}%"
```

### For True Substring Matching: pg_trgm GIN Index

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_orders_number_trgm ON orders USING gin (number gin_trgm_ops);
```

## Pattern 2: Duplicate Joins Prevention

**Never use both `.joins()` and `.includes()` on the same association.** Duplicate joins confuse PostgreSQL's query planner → 50-70x slowdown with no errors.

### Required Pattern

```ruby
# Single optimized join path
Order
  .includes(:billing_address, store: :organization)
  .where('organizations.id = ?', org_id)
  .references(:organizations)  # Tells AR to include join for WHERE
```

### Forbidden Patterns

```ruby
.joins(store: :org).includes(store: :org)                  # joins + includes
.includes(:address).left_outer_joins(:address)             # includes + left_outer_joins
.joins('INNER JOIN stores...').includes(store: :org)       # raw SQL + includes
```

### Decision Table

| Scenario | Pattern |
|----------|---------|
| Eager load WITHOUT WHERE on association | `.includes(:assoc)` |
| Eager load WITH WHERE on association | `.includes(:assoc).references(:assoc)` |
| Filter WITHOUT eager loading | `.joins(:assoc)` |
| **NEVER** | `.joins(:assoc).includes(:assoc)` |

## Pattern 3: Two-Phase DISTINCT Optimization

`.includes()` + `.distinct` generates `SELECT DISTINCT` on ALL columns from ALL included tables (120+ columns). Split into two phases.

### Required Pattern

```ruby
# Phase 1: DISTINCT on single integer column (fast)
order_ids = Order
  .joins(:store)
  .left_outer_joins(:billing_address)
  .where(conditions)
  .distinct
  .limit(MAX_RESULTS)
  .pluck(:id)  # Only select ID column — NOT .select(:id)

return [] if order_ids.empty?

# Phase 2: Load full objects (no DISTINCT needed — IDs are unique)
Order
  .includes(:billing_address, store: :organization)
  .where(id: order_ids)
```

**Use `.pluck(:id)` not `.select(:id)`** — `.select` returns ActiveRecord::Relation, `.pluck` returns plain array.

## Pattern 4: UNION ALL OR-Splitting for Cross-Table Queries

OR conditions spanning multiple tables prevent index usage, even trigram indexes. Split into separate queries combined with `UNION ALL`.

### Structure

```ruby
# Each branch uses its own optimal index
email_sql     = "SELECT id #{base_sql} AND email ILIKE :pattern"
firstname_sql = "SELECT id #{base_sql} AND EXISTS (SELECT 1 FROM addresses WHERE ...)"
lastname_sql  = "SELECT id #{base_sql} AND EXISTS (SELECT 1 FROM addresses WHERE ...)"

union_sql = "SELECT DISTINCT id FROM (
  (#{email_sql}) UNION ALL (#{firstname_sql}) UNION ALL (#{lastname_sql})
) AS combined LIMIT :limit"

order_ids = ActiveRecord::Base.connection.select_values(sanitized_sql).map(&:to_i)
```

**Key**: UNION ALL + outer DISTINCT is faster than UNION (which deduplicates per-branch). EXISTS subqueries avoid LEFT JOIN overhead.

### Decision Table

| Scenario | Pattern |
|----------|---------|
| OR across 2+ tables with ILIKE | UNION ALL splitting |
| OR within same table | Keep single query |
| AND conditions across tables | Keep single query |

## Performance Impact Summary

| Pattern | Before | After | Improvement |
|---------|--------|-------|-------------|
| Leading wildcard ILIKE | Full table scan | Index scan | 800-1000x |
| Duplicate joins | 50-70x overhead | Single join path | 50-70x |
| Wide-row DISTINCT (120+ cols) | 100-500ms | 10-50ms | 10-50x |
| Cross-table OR | 7,000ms | 200-500ms | 14-35x |

## Violation Detection

```bash
# Pattern 1: Leading wildcard ILIKE
grep -rn 'ILIKE.*"%' app/jobs/ app/models/ app/controllers/ --include="*.rb"

# Pattern 2: Duplicate joins
grep -rn "\.joins(" app/ --include="*.rb" | cut -d: -f1 | sort -u | \
  while read file; do
    grep -q "\.includes(" "$file" && echo "CHECK: $file"
  done

# Pattern 3: Wide-row DISTINCT
grep -rn "\.includes.*\.distinct\|\.distinct.*\.includes" app/ --include="*.rb"

# Pattern 4: Cross-table OR with ILIKE
grep -rn "ILIKE.*OR.*ILIKE" app/ --include="*.rb" | grep -v "UNION"
```
