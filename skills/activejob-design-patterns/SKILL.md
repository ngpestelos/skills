---
name: activejob-design-patterns
description: "Self-contained ActiveJob architecture with transaction safety, defensive programming, fatal vs non-fatal error handling, external API integration, internal batching, multi-dyno S3 file sharing, and operation-based idempotency using Rails cache with operation_id propagation, parameterized cache keys, TOCTOU prevention, and test cache configuration. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveJob Design Patterns

## Fatal vs Non-Fatal Exception Handling

First decision when writing any job: does this error warrant a retry?

**Pattern A: Fatal (Re-raise for Retry)** - Transient issues: network errors, timeouts, temporary DB locks, race conditions.

**Pattern B: Non-Fatal (No Re-raise)** - Permanent issues: data validation failures, audit discrepancies, business logic violations.

```
Is this a monitoring/audit job?
--- YES -> Pattern B (no re-raise)
--- NO  -> Is the error transient?
           --- YES -> Pattern A (re-raise)
           --- NO  -> Will retrying help?
                      --- YES -> Pattern A
                      --- NO  -> Pattern B
```

## Architecture

### Self-Contained Design

Job classes should contain all business logic with no external service dependencies. Use instance variables for state, not context hashes.

```ruby
class ProcessWeekly < ApplicationJob
  def perform(entity_id)
    @entity_id = entity_id
    calculate_date_range

    ActiveRecord::Base.transaction do
      create_record
      fetch_data
      create_content_records
      verify_contents
      finalize_calculations
    end
  end

  private

  def create_record; end
  def fetch_data; end
end
```

### Transaction Safety

Wrap database mutations in a transaction. Log start, completion (with duration/counts), and failure (with error class/message). Always re-raise after logging.

```ruby
def perform(entity_id)
  start_time = Time.current
  @entity_id = entity_id

  Rails.logger.info("[JOB] Starting - entity_id: #{@entity_id}")

  begin
    ActiveRecord::Base.transaction do
      create_record
      fetch_data
      create_content_records
    end
    Rails.logger.info("[JOB] Completed - duration: #{(Time.current - start_time).round(2)}s")
  rescue StandardError => e
    Rails.logger.error("[JOB] FAILED - entity_id: #{@entity_id}, error: #{e.class.name}: #{e.message}")
    raise
  end
end
```

### NO SILENT ERRORS Enforcement

Every error must be logged, reported, and re-raised.

```ruby
rescue StandardError => e
  # 1. Logging (ALWAYS)
  Rails.logger.error("[JOB] FAILED - record_id: #{record_id}, error: #{e.class.name}: #{e.message}")

  # 2. Database Error State (if applicable)
  @record&.update(error_message: e.message, error_backtrace: e.backtrace.first)

  # 3. ExceptionReporter (ALWAYS)
  ExceptionReporter.new(exception: e, metadata: {...}).perform_now

  # 4. Re-raise (ALWAYS - except for specific non-fatal cases)
  raise
end
```

### External API Integration

Jobs with external APIs: **no transaction wrapper** (API calls cannot be rolled back). Update state AFTER API success. Notification failures after a successful API call are non-fatal.

```ruby
class TransferAndSend < ApplicationJob
  def perform(record_id)
    @record = Record.find(record_id)

    validate_eligibility
    transfer_funds              # External API call
    send_notification           # Email notification
  rescue StandardError => e
    Rails.logger.error("[JOB] FAILED - record_id: #{@record.id}, error: #{e.message}")
    @record.update(error_message: e.message, error_backtrace: e.backtrace.first)
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

### Defensive Association Handling

`belongs_to` associations are not guaranteed present due to legacy data, orphaned references, or race conditions. Use primary + fallback + logging for resolution methods. Nil-check before using associations.

```ruby
def resolve_site(payoutable)
  site = payoutable.site

  if site.nil?
    Rails.logger.warn("[JOB INTEGRITY] NIL SITE - payoutable: #{payoutable.class.name}##{payoutable.id}")
    site = payoutable.order&.store&.site
  end

  raise "Cannot resolve site for #{payoutable.class.name} #{payoutable.id}" if site.nil?
  site
end
```

### Async Job Enqueuing After Transaction Commits

`perform_later` inside transactions causes race conditions where workers execute before commit. Enqueue AFTER the transaction block.

```ruby
# WRONG - Job enqueued inside transaction
ActiveRecord::Base.transaction do
  create_record
  finalize_calculations
  PublishJob.perform_later(@record.id)  # Worker may run before commit!
end

# RIGHT - Job enqueued AFTER transaction
ActiveRecord::Base.transaction do
  create_record
  finalize_calculations
end
PublishJob.perform_later(@record.id) if @record.present?
```

### Single-Job Internal Batching

For bulk operations, use single-job internal batching instead of multiple separate batch jobs.

```ruby
class BulkProcessJob < ApplicationJob
  def perform(job_id:, item_ids:, params:)
    result = Model.bulk_process_with_batching(
      item_ids: item_ids, batch_size: 50
    ) do |progress|
      update_job_progress(job_id, progress)
    end
  end
end
```

```ruby
def self.bulk_process_with_batching(item_ids:, batch_size:, &block)
  total = item_ids.size
  completed = 0
  failed_batches = []

  item_ids.each_slice(batch_size).with_index do |batch_ids, batch_index|
    transaction do
      process_batch(batch_ids: batch_ids)
    end
    completed += batch_ids.size
    yield(total: total, completed: completed, batch: batch_index + 1)
    GC.start if ((batch_index + 1) % 10).zero?
  rescue StandardError => e
    Rails.logger.error "Batch #{batch_index + 1} failed: #{e.message}"
    failed_batches << { batch: batch_index + 1, error: e.message }
  end

  { total: total, completed: completed, failed_batches: failed_batches }
end
```

### Multi-Dyno File Sharing via S3

In Heroku, web and worker dynos have separate ephemeral filesystems. Upload to S3 for cross-dyno access. When multiple async jobs need the same file, create per-job copies to prevent race conditions on cleanup.

```ruby
# WRONG - File on web dyno, invisible to worker
temp_file_path = save_to_temp_file(attachment)
BulkUploadJob.perform_later(item_ids, temp_file_path)

# RIGHT - Upload to S3
s3_key = upload_to_s3(attachment)
BulkUploadJob.perform_later(item_ids, s3_key)

# WRONG - All jobs share one temp file
item_ids.each { |id| UploadJob.perform_later(id, temp_file_path) }

# RIGHT - Per-job file isolation
item_ids.each do |id|
  item_temp_path = copy_for_item(original_temp_path, id)
  UploadJob.perform_later(id, item_temp_path)
end
```

## Idempotency

### Operation-Based Tracking (Not Entity-Based)

Entity-based idempotency (checking `cloned_from_id`) prevents multiple intentional runs. Operation-based idempotency uses unique `operation_id` + cache to allow multiple runs while preventing retry duplicates.

```ruby
# User clones "Summer Template" -> "School A", "School B", "School C"
# Entity-based: BREAKS (can only clone once)
# Operation-based: WORKS (different operation_ids, all succeed)

# User retries failed clone (network timeout)
# Entity-based: Creates duplicate
# Operation-based: Returns cached result (idempotent)
```

### Generate Operation ID at Entry Point

```ruby
def create
  operation_id = SecureRandom.uuid
  cache_key = "clone_op:#{operation_id}:entity:#{@source.id}"

  cached = Rails.cache.read(cache_key)
  if cached&.dig(:result_id)
    @result = Model.find_by(id: cached[:result_id])
    return if @result
  end

  # ... create record ...
  Rails.cache.write(cache_key, {result_id: @result.id}, expires_in: 1.hour)
  ProcessJob.perform_later(@result.id, @source.id, operation_id)
end
```

### Cache Key Design

**Basic**: `"operation_type:#{operation_id}:entity:#{entity_id}:#{context_id}"`

**Parameterized** (same entity, different parameters):
```ruby
def calculate_params_digest(params_hash)
  normalized_params = {
    artwork_ids: (params_hash[:artwork_ids] || []).sort,
    placements: params_hash[:placements].to_json
  }
  Digest::MD5.hexdigest(normalized_params.to_json)
end

cache_key = "decoration_op:#{operation_id}:image:#{image_id}:hash:#{params_digest}"
```

### Cache Check BEFORE Processing (TOCTOU Prevention)

Check cache before any work begins. Checking after processing starts creates a TOCTOU vulnerability where concurrent requests both start processing.

```ruby
def clone_to(dest, operation_id: nil)
  validate_inputs(dest)

  if operation_id.present?
    cache_key = "clone_op:#{operation_id}:entity:#{id}:#{dest.id}"
    cached = Rails.cache.read(cache_key)

    if cached&.dig(:result_id)
      existing = self.class.find_by(id: cached[:result_id])
      return OpenStruct.new(success?: true, result: existing) if existing
    end
  end

  # ... proceed with cloning ...
end
```

### Cache Write After Success Only

```ruby
if operation_id.present? && cloned&.id
  cache_key = "clone_op:#{operation_id}:entity:#{id}:#{dest.id}"
  Rails.cache.write(cache_key, {result_id: cloned.id}, expires_in: 1.hour)
end
```

### Propagate Through Job Chain

Add `operation_id` as **last** parameter, make it **optional** with `nil` default for backward compatibility.

```ruby
class ProcessJob < ApplicationJob
  def perform(dest_id, source_id, operation_id = nil)
    @operation_id = operation_id || SecureRandom.uuid
    NestedJob.perform_now(name: name, source: source, operation_id: @operation_id)
  end
end

class NestedJob < ApplicationJob
  def perform(name:, source:, operation_id: nil)
    @operation_id = operation_id || SecureRandom.uuid
    BatchJob.perform_now(dest: dest, source_ids: ids, operation_id: @operation_id)
  end
end
```

### Test Cache Configuration

**CRITICAL**: Tests require `:memory_store`, NOT `:null_store`.

```ruby
# config/environments/test.rb
config.cache_store = :null_store   # WRONG - discards all cache writes
config.cache_store = :memory_store # RIGHT - real cache behavior in tests
```

`:null_store` hides cache behavior. When switching to `:memory_store`, tests may fail revealing correct controller cache repopulation — fix the tests, not the code.
