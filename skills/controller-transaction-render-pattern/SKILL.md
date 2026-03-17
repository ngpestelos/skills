---
name: controller-transaction-render-pattern
version: 1.1.0
license: MIT
metadata:
  author: ngpestelos
  version: 1.1.0
description: "Prevents double render errors and connection pool pollution in ActiveRecord transaction blocks. Trigger keywords: DoubleRenderError, PG::InFailedSqlTransaction, transaction render, result variable pattern, connection pool pollution."
allowed-tools: Read, Grep, Glob
---

# Controller Transaction Render Pattern

Rendering inside `ActiveRecord::Base.transaction` + exception causes double render + connection pollution: transaction renders (first), exception raised, rescue renders (second) → `DoubleRenderError` + `PG::InFailedSqlTransaction`.

## Result Variable Pattern

Store outcome during transaction, render once after completion.

```ruby
def update
  status_code = nil
  response_data = nil
  begin
    ActiveRecord::Base.transaction do
      if some_condition
        perform_update
        status_code = :ok
        response_data = { message: 'Changes saved' }
      else
        status_code = :unprocessable_entity
        response_data = { error: 'Invalid request' }
      end
    end
    render json: response_data, status: status_code  # AFTER transaction
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
```

## Connection Pool Pollution

**Unnecessary controller transaction wrappers** cause `PG::InFailedSqlTransaction` in staging/production even with the result variable pattern. Tests pass because they use single connections cleaned between tests.

**Root cause**: Controller wraps job in transaction → job fails → PostgreSQL marks transaction as aborted → connection returns to pool in failed state → next request gets dirty connection.

Don't wrap jobs in controller transactions — let jobs manage their own. Only use controller transactions when coordinating multiple independent writes that must succeed or fail together.

```ruby
# WRONG - Unnecessary wrapper when job handles its own errors
ActiveRecord::Base.transaction do
  update_record  # Calls job with perform_now
  status_code = :ok
end

# RIGHT - No wrapper; job handles its own errors
update_record
status_code = :ok

# RIGHT - Controller transaction for coordinated writes
ActiveRecord::Base.transaction do
  user.update!(role: 'admin')
  audit_log.create!(action: 'role_change', user: user)
end
```

For `find_or_create_by` connection pollution under concurrency, see `activerecord-idempotent-create-patterns`.
