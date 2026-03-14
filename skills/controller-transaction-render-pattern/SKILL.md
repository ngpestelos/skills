---
name: controller-transaction-render-pattern
description: "Prevents double render errors and connection pool pollution in ActiveRecord transaction blocks. Covers result variable pattern, unnecessary transaction wrapper removal, and find-then-create patterns. Trigger keywords: DoubleRenderError, PG::InFailedSqlTransaction, transaction render, result variable pattern, controller transaction, connection pool pollution, staging-only errors. (global)"
allowed-tools: Read, Grep, Glob
---

# Controller Transaction Render Pattern

Rendering inside `ActiveRecord::Base.transaction` + exception causes double render + connection pollution: transaction renders (first), exception raised, rescue renders (second) → `AbstractController::DoubleRenderError` + `PG::InFailedSqlTransaction`.

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
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Failed to update: #{e.message}"
    render json: { error: 'Something went wrong' }, status: :unprocessable_entity
  end
end
```

## When to Use

| Use This Pattern | Skip This Pattern |
|---|---|
| Any controller action with `ActiveRecord::Base.transaction do` | Actions without transactions |
| Actions that may raise exceptions during transaction | Actions that only render (no business logic) |
| AJAX/JSON API endpoints with multiple outcomes | Simple redirects |

## Connection Pool Pollution

Even with result variable pattern, **unnecessary controller transaction wrappers** cause `PG::InFailedSqlTransaction` in staging/production. Tests pass because they use single connections cleaned between tests.

**Root cause**: Controller wraps job in transaction → job fails → PostgreSQL marks transaction as aborted → connection returns to pool in failed state → next request gets dirty connection.

Don't wrap jobs in controller transactions — let jobs manage their own. Only use controller transactions when coordinating multiple independent writes that must succeed or fail together.

```ruby
# WRONG - Unnecessary wrapper when job handles its own errors
ActiveRecord::Base.transaction do
  if params[:default] == '1'
    set_as_default
    status_code = :ok
  elsif params[:default].blank?
    update_record  # Calls job with perform_now
    status_code = :ok
  end
end

# RIGHT - No unnecessary wrapper
if params[:default] == '1'
  set_as_default
  status_code = :ok
elsif params[:default].blank?
  update_record  # Job handles its own errors
  status_code = :ok
end

# RIGHT - Controller transaction for coordinated writes
ActiveRecord::Base.transaction do
  user.update!(role: 'admin')
  audit_log.create!(action: 'role_change', user: user)
  notification.create!(recipient: user, message: 'Role updated')
end
```

For `find_or_create_by` connection pollution under concurrency, see the `activerecord-idempotent-create-patterns` skill.
