# Heroku: Running Long Migrations

## Heroku Timeout Layers

| Layer | Timeout | Impact on Migrations |
|-------|---------|---------------------|
| Router | 30 seconds | Does not affect `heroku run` |
| CLI connection | ~1 hour | `heroku run` killed if connection drops |
| One-off dyno | 24 hours | Maximum runtime |

**Key insight**: `heroku run` kills the dyno if your terminal disconnects. `heroku run:detached` runs independently.

## Detached vs Attached Mode

**Attached Mode (`heroku run`)** — Terminal disconnection kills dyno:
```
Your Terminal <──SSH tunnel──> Heroku One-off Dyno
     │                              │
     └── connection drops ──────────┘ dyno KILLED
```

**Detached Mode (`heroku run:detached`)** — Runs independently:
```
Your Terminal                    Heroku One-off Dyno
     │                                  │
     │ "dyno: run.1234"                 │
     │ (returns immediately)            │
     └── connection irrelevant ─────────┘ dyno runs to completion
```

## Running Long Migrations

```bash
# Start migration independently of terminal
heroku run:detached bin/rails db:migrate --app YOUR_APP
# Returns immediately with dyno ID: "Running... dyno: run.1234"
```

## Monitoring and Diagnostics

```bash
# Check running dynos
heroku ps --app YOUR_APP

# Watch logs in real-time
heroku logs --dyno run.1234 --tail --app YOUR_APP

# Check migration completion
heroku pg:psql --app YOUR_APP -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;"

# Check for invalid indexes
heroku pg:psql --app YOUR_APP -c "
  SELECT indexname, indexdef FROM pg_indexes i
  JOIN pg_class c ON c.relname = i.indexname
  JOIN pg_index idx ON idx.indexrelid = c.oid
  WHERE NOT idx.indisvalid;
"
```

## Recovery After Interrupted Migration

### Standard Migration
1. Check status: `bin/rails db:migrate:status`
2. Re-run: `bin/rails db:migrate`

### Concurrent Index
1. Check for invalid indexes (SQL above)
2. Drop invalid: `DROP INDEX CONCURRENTLY IF EXISTS idx_name;`
3. Re-run migration

### Data Migration
1. Check data state (count processed vs unprocessed)
2. Ensure migration is idempotent
3. Re-run (batches already processed skipped by WHERE clause)
