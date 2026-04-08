---
name: activejob-design-patterns
category: rails
description: "ActiveJob architecture patterns: fatal vs non-fatal error handling, transaction safety, external API integration, async enqueuing, internal batching, and operation-based idempotency. Auto-activates when writing background jobs, handling job errors, or implementing idempotent operations. Trigger keywords: ActiveJob, perform_later, background job, retry, idempotent, operation_id, job error handling."
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.1"
---

# ActiveJob Design Patterns

## Fatal vs Non-Fatal Error Handling

First decision for any job: will retrying help?

- **Fatal** (retry-worthy): transient issues — network errors, timeouts, temporary DB locks. Wrap mutations in a transaction, re-raise the error.
- **Non-Fatal** (no retry): permanent issues — validation failures, audit discrepancies. Log the error, do NOT re-raise.

```ruby
def perform(entity_id)
  ActiveRecord::Base.transaction do
    create_record
    fetch_data
    create_content_records
  end
rescue StandardError => e
  Rails.logger.error("[JOB] FAILED - entity_id: #{entity_id}, error: #{e.class.name}: #{e.message}")
  raise  # Remove `raise` for non-fatal jobs
end
```

## External API Integration

No transaction wrapper — API calls cannot be rolled back. Update state AFTER API success. Notification failures after successful API calls are non-fatal.

```ruby
class TransferAndSend < ApplicationJob
  def perform(record_id)
    @record = Record.find(record_id)
    validate_eligibility
    transfer_funds
    send_notification
  rescue StandardError => e
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
    Rails.logger.error("[JOB] Notification FAILED (API succeeded) - #{e.message}")
  end
end
```

## Async Enqueuing After Transaction Commits

`perform_later` inside transactions causes race conditions — workers may execute before commit. Enqueue after the transaction block:

```ruby
ActiveRecord::Base.transaction do
  create_record
end
PublishJob.perform_later(@record.id) if @record.present?
```

## Single-Job Internal Batching

For bulk operations, use one job with internal batching instead of many separate jobs. When multiple jobs share a file, create per-job copies to prevent race conditions on cleanup.

```ruby
class BulkProcessJob < ApplicationJob
  def perform(job_id:, item_ids:, params:)
    item_ids.each_slice(50).with_index do |batch_ids, batch_index|
      ActiveRecord::Base.transaction do
        process_batch(batch_ids: batch_ids)
      end
      GC.start if ((batch_index + 1) % 10).zero?
    rescue StandardError => e
      Rails.logger.error "Batch #{batch_index + 1} failed: #{e.message}"
    end
  end
end
```

## Idempotency: Operation-Based Tracking

Entity-based idempotency (e.g., checking `cloned_from_id`) prevents multiple intentional runs. Operation-based idempotency uses unique `operation_id` + cache to allow intentional re-runs while preventing retry duplicates.

| Scenario | Entity-based | Operation-based |
|----------|-------------|-----------------|
| Clone template -> A, B, C | BREAKS (one clone only) | WORKS (different operation_ids) |
| Retry failed clone | Creates duplicate | Returns cached result |

### Cache Check Before Processing (TOCTOU Prevention)

Check cache before any work begins — checking after processing starts creates a TOCTOU vulnerability.

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

Add `operation_id` as the **last** parameter with `nil` default for backward compatibility. Generate with `@operation_id = operation_id || SecureRandom.uuid` and pass to all nested jobs.
