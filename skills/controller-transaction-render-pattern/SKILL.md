---
name: controller-transaction-render-pattern
description: "Prevents double render errors and connection pool pollution in ActiveRecord transaction blocks. Covers result variable pattern, unnecessary transaction wrapper removal, and find-then-create patterns. Trigger keywords: DoubleRenderError, PG::InFailedSqlTransaction, transaction render, result variable pattern, controller transaction, connection pool pollution, staging-only errors. (global)"
allowed-tools: Read, Grep, Glob
---

# Controller Transaction Render Pattern

## Core Principles

1. **NEVER render inside ActiveRecord transaction blocks** - Store result, render after transaction completes
2. **Use result variable pattern** - Set status/data during transaction, render once outside
3. **Rescue blocks can render** - Exception handling outside transaction is safe
4. **One render per action** - Rails enforces this; violations cause AbstractController::DoubleRenderError

## The Problem

Rendering inside `ActiveRecord::Base.transaction` + exception -> double render + connection pollution:

1. Transaction renders response (first render)
2. Exception raised (validation failure)
3. Rescue block renders error (second render)
4. Result: `AbstractController::DoubleRenderError` + `PG::InFailedSqlTransaction`

## REQUIRED Pattern: Result Variable

Store outcome during transaction, render once after completion:

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

## FORBIDDEN Pattern: Render Inside Transaction

```ruby
# WRONG - Renders inside transaction
ActiveRecord::Base.transaction do
  if params[:default] == '1'
    set_as_default
    render json: { message: 'Changes saved' }, status: :ok  # First render
  elsif params[:default].blank?
    update_record  # May raise exception
    render json: { message: 'Changes saved' }, status: :ok
  end
end
rescue StandardError => e
  render json: { error: 'Something went wrong' }, status: :unprocessable_entity  # Second render!
end
```

## Pattern Variations

### Simple Success/Failure

```ruby
def toggle_availability
  begin
    ActiveRecord::Base.transaction do
      new_availability = params[:current_availability] != 'true'
      unless current_record.update(available: new_availability)
        raise StandardError, "Failed to toggle: #{current_record.errors.full_messages.join(', ')}"
      end
    end
    render json: { message: 'Changes saved' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Failed: #{e.message}"
    render json: { error: 'Something went wrong' }, status: :unprocessable_entity
  end
end
```

### Complex Data Response

```ruby
def update_size
  status_code = nil
  response_data = nil

  begin
    ActiveRecord::Base.transaction do
      size_record = current_record.sizes.find(params[:size_id])
      update_size_attributes(size_record)

      if size_record.save
        size_record.touch
        status_code = :ok
        response_data = {
          message: 'Size updated',
          updated_data: {
            cost_price: size_record.cost_price,
            additional_price: size_record.additional_price,
            available: size_record.available, limit: size_record.limit
          }
        }
      else
        status_code = :unprocessable_entity
        response_data = { error: 'Failed to update size' }
      end
    end

    render json: response_data, status: status_code
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Size not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Failed: #{e.message}"
    render json: { error: 'Something went wrong' }, status: :unprocessable_entity
  end
end
```

## When to Use / Not Use

| Use This Pattern | Skip This Pattern |
|---|---|
| Any controller action with `ActiveRecord::Base.transaction do` | Actions without transactions |
| Actions that may raise exceptions during transaction | Actions that only render (no business logic) |
| AJAX/JSON API endpoints with multiple outcomes | Simple redirects |

## Connection Pool Pollution

### The Problem

Even with result variable pattern, **unnecessary controller transaction wrappers** cause `PG::InFailedSqlTransaction` in staging/production through connection pool pollution. Tests pass because they use single connections cleaned between tests.

**Root cause**: Controller wraps job in transaction -> job/nested operation fails -> PostgreSQL marks transaction as aborted -> connection returns to pool in failed state -> next request gets dirty connection.

### FORBIDDEN: Unnecessary Controller Transaction Wrappers

```ruby
# WRONG - Transaction wrapper provides no benefit when job handles its own errors
ActiveRecord::Base.transaction do
  if params[:default] == '1'
    set_as_default
    status_code = :ok
  elsif params[:default].blank?
    update_record  # Calls job with perform_now
    status_code = :ok
  end
end
```

### REQUIRED: Let Jobs Manage Own Transactions

```ruby
# CORRECT - No unnecessary wrapper
if params[:default] == '1'
  set_as_default
  status_code = :ok
elsif params[:default].blank?
  update_record  # Job handles its own errors
  status_code = :ok
end
```

### When Controller Transactions ARE Needed

Only when coordinating multiple independent database operations that must succeed or fail together:

```ruby
ActiveRecord::Base.transaction do
  user.update!(role: 'admin')
  audit_log.create!(action: 'role_change', user: user)
  notification.create!(recipient: user, message: 'Role updated')
end
```

### `find_or_create_by` Connection Pollution

> **Note**: For general idempotent creation patterns, see the **activerecord-idempotent-create-patterns** skill.

`find_or_create_by` has an implicit transaction that can leave connections in a failed state under high concurrency. Use explicit find-then-create instead:

```ruby
# WRONG - Implicit transaction can fail and pollute connection
OptionValue.find_or_create_by(option_type_id: option_type.id, name: name, presentation: name)

# CORRECT - Explicit find-then-create with retry
existing = OptionValue.find_by(option_type_id: option_type.id, name: name)
return existing if existing

OptionValue.create!(option_type_id: option_type.id, name: name, presentation: name)
rescue ActiveRecord::RecordInvalid => e
  retry_find = OptionValue.find_by(option_type_id: option_type.id, name: name)
  return retry_find if retry_find
  raise e
end
```

## Violation Detection

```bash
# Render calls inside transaction blocks
grep -A 20 "ActiveRecord::Base.transaction do" app/controllers/**/*.rb | grep "render "

# Transaction blocks wrapping perform_now (unnecessary wrappers)
grep -A 10 "ActiveRecord::Base.transaction do" app/controllers/**/*.rb | grep "perform_now"

# find_or_create_by in jobs (connection pollution risk)
grep -n "find_or_create_by" app/jobs/**/*.rb
```

## Integration Test

```ruby
test 'should handle duplicate validation error without double render' do
  existing_record = create(:record, name: 'Red')

  patch "/resources/#{@record.id}",
        params: { name: 'Red', available: '1' },
        as: :json

  assert_response :unprocessable_entity
  json_response = response.parsed_body
  assert_equal 'Something went wrong', json_response['error']

  @record.reload
  assert_not_equal 'Red', @record.name
end
```
