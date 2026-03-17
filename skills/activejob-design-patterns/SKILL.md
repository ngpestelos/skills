---
name: activejob-design-patterns
description: "ActiveJob architecture patterns: fatal vs non-fatal error handling, transaction safety, external API integration, async enqueuing, internal batching, and operation-based idempotency. Auto-activates when writing background jobs, handling job errors, or implementing idempotent operations. Trigger keywords: ActiveJob, perform_later, background job, retry, idempotent, operation_id, job error handling."
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# ActiveJob Design Patterns

## Fatal vs Non-Fatal Error Handling

First decision when writing any job: does this error warrant a retry?

Monitoring/audit job? → Non-fatal. Otherwise: transient error? → Fatal. Will retrying help? → Fatal. Else → Non-fatal.

**Fatal (Pattern A)**: Transient issues — network errors, timeouts, temporary DB locks. Wrap mutations in a transaction, log start/complete/fail with duration, always re-raise.

```ruby
def perform(entity_id)
  start_time = Time.current
  Rails.logger.info("[JOB] Starting - entity_id: #{entity_id}")

  begin
    ActiveRecord::Base.transaction do
      create_record
      fetch_data
      create_content_records
    end
    Rails.logger.info("[JOB] Completed - duration: #{(Time.current - start_time).round(2)}s")
  rescue StandardError => e
    Rails.logger.error("[JOB] FAILED - entity_id: #{entity_id}, error: #{e.class.name}: #{e.message}")
    raise
  end
end
```

**Non-Fatal (Pattern B)**: Permanent issues — data validation failures, audit discrepancies. Log the error, do NOT re-raise.

## External API Integration

Jobs calling external APIs: **no transaction wrapper** (API calls cannot be rolled back). Update state AFTER API success. Notification failures after a successful API call are non-fatal.

```ruby
class TransferAndSend < ApplicationJob
  def perform(record_id)
    @record = Record.find(record_id)

    validate_eligibility
    transfer_funds              # External API call
    send_notification           # Email notification
  rescue StandardError => e
    Rails.logger.error("[JOB] FAILED - record_id: #{@record.id}, error: #{e.message}")
    @record.update(error_message: e.message)
    raise
  end

  private

  def transfer_funds
    transfer = CreateTransfer.perform_now(...)
    @record.update(transfer_id: transfer.id)  # Update AFTER success
  end

  def send_notification
    NotifyJob.perform_now(@record)
  rescue StandardError => e
    # Non-fatal: API succeeded, notification is retryable
    Rails.logger.error("[JOB] Notification FAILED (API succeeded) - #{e.message}")
  end
end
```

## Async Job Enqueuing After Transaction Commits

`perform_later` inside transactions causes race conditions where workers execute before commit.

WRONG: `perform_later` inside transaction — worker may run before commit. RIGHT: enqueue after the transaction block.

```ruby
ActiveRecord::Base.transaction do
  create_record
end
PublishJob.perform_later(@record.id) if @record.present?
```

## Single-Job Internal Batching

For bulk operations, use single-job internal batching instead of many separate jobs. When multiple jobs share a file, create per-job copies to prevent race conditions on cleanup.

```ruby
class BulkProcessJob < ApplicationJob
  def perform(job_id:, item_ids:, params:)
    total = item_ids.size
    completed = 0
    failed_batches = []

    item_ids.each_slice(50).with_index do |batch_ids, batch_index|
      ActiveRecord::Base.transaction do
        process_batch(batch_ids: batch_ids)
      end
      completed += batch_ids.size
      GC.start if ((batch_index + 1) % 10).zero?
    rescue StandardError => e
      Rails.logger.error "Batch #{batch_index + 1} failed: #{e.message}"
      failed_batches << { batch: batch_index + 1, error: e.message }
    end

    { total: total, completed: completed, failed_batches: failed_batches }
  end
end
```

## Idempotency: Operation-Based Tracking

Entity-based idempotency (checking `cloned_from_id`) prevents multiple intentional runs. Operation-based idempotency uses unique `operation_id` + cache to allow multiple intentional runs while preventing retry duplicates.

| Scenario | Entity-based | Operation-based |
|----------|-------------|-----------------|
| Clone template → A, B, C | BREAKS (one clone only) | WORKS (different operation_ids) |
| Retry failed clone | Creates duplicate | Returns cached result |

### Cache Check BEFORE Processing (TOCTOU Prevention)

Check cache before any work begins. Checking after processing starts creates a TOCTOU vulnerability.

```ruby
def clone_to(dest, operation_id: nil)
  if operation_id.present?
    cache_key = "clone_op:#{operation_id}:entity:#{id}:#{dest.id}"
    cached = Rails.cache.read(cache_key)

    if cached&.dig(:result_id)
      existing = self.class.find_by(id: cached[:result_id])
      return OpenStruct.new(success?: true, result: existing) if existing
    end
  end

  # ... proceed with work ...

  if operation_id.present? && result&.id
    Rails.cache.write(cache_key, { result_id: result.id }, expires_in: 1.hour)
  end
end
```

### Propagate Operation ID Through Job Chain

Add `operation_id` as **last** parameter, **optional** with `nil` default for backward compatibility. Each job in the chain: `def perform(dest_id, source_id, operation_id = nil)` → `@operation_id = operation_id || SecureRandom.uuid` → pass to nested jobs.
