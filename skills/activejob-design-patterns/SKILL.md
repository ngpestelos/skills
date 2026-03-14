---
name: activejob-design-patterns
description: "Self-contained ActiveJob architecture with transaction safety, defensive programming, fatal vs non-fatal error handling, external API integration, internal batching, multi-dyno S3 file sharing, and operation-based idempotency using Rails cache with operation_id propagation, parameterized cache keys, TOCTOU prevention, and test cache configuration. (global)"
allowed-tools: Read, Grep, Glob
---

# ActiveJob Design Patterns
## Architecture

### Self-Contained Design

Job classes should contain all business logic with no external service dependencies.

```ruby
# RIGHT - Self-contained job
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

# WRONG - External service dependencies
class ProcessWeekly < ApplicationJob
  def perform(entity_id)
    context = {entity_id: entity_id}
    context = Services::CalculateDateRange.call(context)
    context = Services::CreateRecord.call(context)
    # ... 13 more service calls
  end
end
```

Use instance variables for state, not context hashes. Clear state visibility, no context mutation concerns, simpler method signatures.

### Transaction Safety with Comprehensive Logging

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
      verify_contents
      finalize_calculations
    end

    Rails.logger.info(
      "[JOB] Completed - duration: #{(Time.current - start_time).round(2)}s, " \
      "items: #{@items.count}, total: #{@record.total}"
    )
  rescue StandardError => e
    Rails.logger.error(
      "[JOB] FAILED - transaction rolled back - entity_id: #{@entity_id}, " \
      "error: #{e.class.name}: #{e.message}"
    )
    raise  # Re-raise to preserve original behavior
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

### Fatal vs Non-Fatal Exception Handling

**Pattern A: Fatal (Re-raise for Retry)** - Transient issues that might succeed on retry: network errors, timeouts, temporary DB locks, race conditions.

**Pattern B: Non-Fatal (No Re-raise)** - Permanent issues that won't improve on retry: data validation failures, audit discrepancies, business logic violations.

```
Is this a monitoring/audit job?
--- YES -> Pattern B (no re-raise)
--- NO  -> Is the error transient?
           --- YES -> Pattern A (re-raise)
           --- NO  -> Will retrying help?
                      --- YES -> Pattern A
                      --- NO  -> Pattern B
```

### External API Integration

Jobs with external APIs require different patterns than database-only jobs.

```ruby
class TransferAndSend < ApplicationJob
  def perform(record_id)
    @record = Record.find(record_id)

    # NO transaction wrapper - external API calls cannot be rolled back
    validate_eligibility
    transfer_funds              # External API call
    send_notification           # Email notification
  rescue StandardError => e
    Rails.logger.error("[JOB] FAILED - record_id: #{@record.id}, error: #{e.message}")
    @record.update(error_message: e.message, error_backtrace: e.backtrace.first)
    ExceptionReporter.new(exception: e, metadata: {...}).perform_now
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
    ExceptionReporter.new(exception: e, metadata: {...}).perform_now
  end
end
```

### Defensive Resolution Methods

Methods that resolve associations should have primary + fallback + logging.

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

### Defensive Association Nil Checking

`belongs_to` associations without `optional: true` are not guaranteed present due to legacy data, orphaned references, or race conditions.

```ruby
# WRONG - Assumes association present
variant.option_values << color_variant.color_option_value  # Fails if nil

# RIGHT - Defensive nil check
if color_variant.color_option_value.nil?
  raise ArgumentError, 'Color option value not found for color variant'
end
variant.option_values << color_variant.color_option_value
```

### Verification Methods for Data Integrity

```ruby
def verify_contents
  expected_count = @items.count + @refunds.count
  actual_count = @record.contents.count

  if expected_count != actual_count
    Rails.logger.error("[JOB] Content MISMATCH - expected: #{expected_count}, actual: #{actual_count}")
    raise "Content count mismatch: expected #{expected_count}, got #{actual_count}"
  end
end
```

### Async Job Enqueuing After Transaction Commits

`perform_later` inside transactions causes race conditions where workers execute before commit.

```ruby
# WRONG - Job enqueued inside transaction
ActiveRecord::Base.transaction do
  create_record
  finalize_calculations  # Calls perform_later inside transaction!
end

# RIGHT - Job enqueued AFTER transaction
ActiveRecord::Base.transaction do
  create_record
  finalize_calculations  # NO job enqueuing here
end
# Record now visible to all connections
::PublishCalculatedJob.perform_later(@record.id) if @record.present?
```

**Dual-path solution**: Conditional `after_commit` callback + explicit enqueuing for redundancy.

```ruby
class Record < ApplicationRecord
  after_commit :enqueue_publish_job, on: :update, if: :saved_change_to_amount?

  private
  def enqueue_publish_job
    ::PublishCalculatedJob.perform_later(id)
  end
end
```

### Service Extraction for Reusability

When verification logic needs to run both async (monitoring) AND sync (blocking), extract into a service.

```ruby
module AuditService
  def self.audit(record)
    new(record).audit
  end

  def audit
    verify_content_completeness
    verify_total_amount
    { passed: @discrepancies.empty?, discrepancies: @discrepancies }
  end
end

# Async monitoring (non-blocking)
audit_result = AuditService.audit(@record)

# Sync blocking (prevents incorrect transfers)
unless AuditService.audit(@record)[:passed]
  raise AuditFailed, "Audit failed"
end
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

In Heroku, web dynos and worker dynos have separate ephemeral filesystems.

```ruby
# WRONG - File saved to web dyno's /tmp, worker can't see it
temp_file_path = save_to_temp_file(attachment)
BulkUploadJob.perform_later(item_ids, temp_file_path)

# RIGHT - Upload to S3 (accessible from ALL dynos)
s3_key = upload_to_s3(attachment)
BulkUploadJob.perform_later(item_ids, s3_key)
```

### Shared Temp File Race Condition Prevention

When multiple async jobs point to same temp file, first job to complete deletes it.

```ruby
# WRONG - All jobs point to SAME temp file
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
# Controller
def create
  operation_id = SecureRandom.uuid
  cache_key = "clone_op:#{operation_id}:entity:#{@source.id}"

  cached = Rails.cache.read(cache_key)
  if cached&.dig(:result_id)
    @result = Model.find_by(id: cached[:result_id])
    if @result
      flash[:notice] = "Operation already in progress."
      return
    end
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

```ruby
def clone_to(dest, operation_id: nil)
  validate_inputs(dest)  # Fail fast on bad inputs

  if operation_id.present?
    cache_key = "clone_op:#{operation_id}:entity:#{id}:#{dest.id}"
    cached = Rails.cache.read(cache_key)

    if cached&.dig(:result_id)
      existing = self.class.find_by(id: cached[:result_id])
      if existing
        Rails.logger.info "[Clone] Returning cached clone #{existing.id}"
        return OpenStruct.new(success?: true, result: existing)
      end
    end
  end

  # ... proceed with normal cloning ...
end
```

**FORBIDDEN**: Checking cache AFTER processing starts creates TOCTOU vulnerability where concurrent requests both start processing.

### Cache Write After Success Only

```ruby
# Only cache successful results (don't cache failures)
if operation_id.present? && cloned&.id
  cache_key = "clone_op:#{operation_id}:entity:#{id}:#{dest.id}"
  Rails.cache.write(cache_key, {result_id: cloned.id}, expires_in: 1.hour)
end
```

### Propagate Through Job Chain

```ruby
# Job 1
class ProcessJob < ApplicationJob
  def perform(dest_id, source_id, operation_id = nil)
    @operation_id = operation_id || SecureRandom.uuid
    NestedJob.perform_now(name: name, source: source, operation_id: @operation_id)
  end
end

# Job 2
class NestedJob < ApplicationJob
  def perform(name:, source:, operation_id: nil)
    @operation_id = operation_id || SecureRandom.uuid
    BatchJob.perform_now(dest: dest, source_ids: ids, operation_id: @operation_id)
  end
end
```

Add `operation_id` as **last** parameter, make it **optional** with `nil` default for backward compatibility.

### Test Cache Configuration

**CRITICAL**: Tests require `:memory_store`, NOT `:null_store`.

```ruby
# config/environments/test.rb
config.cache_store = :null_store   # WRONG - discards all cache writes
config.cache_store = :memory_store # RIGHT - real cache behavior in tests
```

`:null_store` hides cache behavior. When switching to `:memory_store`, tests may fail revealing correct controller cache repopulation - fix the tests, not the code.

## FORBIDDEN Patterns

```ruby
# Entity-based idempotency (prevents multiple intentional runs)
existing = dest.products.find_by(cloned_from_id: self.id)
return existing if existing

# Database-based operation tracking (requires migration, permanent pollution)
add_column :products, :clone_operation_id, :string

# Cache check AFTER processing (TOCTOU vulnerability)
cloned = clone_attributes(dest)
clone_children(cloned)
cached = Rails.cache.read(cache_key)  # Too late!

# Job enqueued inside transaction (race condition)
ActiveRecord::Base.transaction do
  save!
  PublishJob.perform_later(id)  # Worker may run before commit!
end

# Shared temp file with per-job cleanup (race condition)
item_ids.each { |id| UploadJob.perform_later(id, same_temp_file) }

# Silent errors
rescue StandardError => e
  # No logging, no reporting, no re-raise
end
```

## Violation Detection

```bash
# Find jobs without error handling
grep -L "rescue StandardError" app/jobs/*.rb

# Find shared temp file patterns
grep -rn "perform_later.*temp\|perform_later.*file_path" app/models/ app/services/

# Find jobs that might need idempotency
grep -r "class.*< ApplicationJob" app/jobs/ | grep -i "clone\|batch\|import\|sync"

# Find cache checks in wrong location
grep -rn "Rails.cache.read" app/ --include="*.rb" -A 5 | grep -B 5 "clone\|create"

# Find :null_store in test environment
grep -n "cache_store.*null_store" config/environments/test.rb

# Find perform_later inside transactions
grep -rn "perform_later" app/models/ app/services/ | grep -v "#\|spec\|test"
```
