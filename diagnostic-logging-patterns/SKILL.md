---
name: diagnostic-logging-patterns
description: "Strategic diagnostic logging for production debugging. 3-layer logging (controller → model → database verification), P0/P1/P2 priority, temporary debug protocol. Trigger keywords: staging bug, test passes production fails, insert_all debugging, parameter not received, debug logging, production debugging, P0 P1 P2 logging."
---

# Diagnostic Logging Patterns

When code works in tests but fails in staging/production, strategic logging at each layer reveals environmental differences.

## Layer 1: Controller — Parameter Reception

```ruby
def action
  source = find_source_record(params[:record_id])
  return unless source

  selected_id = params[:selection_id]&.to_i
  Rails.logger.info "[DEBUG] Controller received params[:selection_id]=#{params[:selection_id].inspect}"
  Rails.logger.info "[DEBUG] Converted to selected_id=#{selected_id.inspect}"

  result = source.process(selected_id: selected_id)
end
```

## Layer 2: Model — Logic + Database Verification

```ruby
def process_items(selected_id = nil)
  Rails.logger.info "[DEBUG] process_items called with selected_id=#{selected_id.inspect}"

  items_attrs = items.map do |item|
    active = selected_id ? (item.id == selected_id) : item.active
    Rails.logger.info "[DEBUG] Item #{item.id}: active=#{active.inspect}"
    item.attributes.except('id', 'created_at', 'updated_at')
      .merge('active' => active, 'created_at' => Time.current, 'updated_at' => Time.current)
  end

  if items_attrs.any?
    result = Model.insert_all!(items_attrs, returning: %w[id])
    inserted_ids = result.rows.map(&:first)
    # Always verify database state — insert_all! bypasses ActiveRecord
    db_check = Model.where(id: inserted_ids).pluck(:id, :active)
    Rails.logger.info "[DEBUG] Database verification: #{db_check.inspect}"
  end
end
```

## P0/P1/P2 Priority

| Priority | Purpose | Classify when |
|----------|---------|---------------|
| **P0** | Gap analysis — diagnosing missing data | Answers "what data was selected/processed?" |
| **P1** | Workflow tracking — job lifecycle | Tracks state transitions, error context |
| **P2** | Operational context | Config values, date ranges, record details |

## Temporary Debug Protocol

1. **Add** with `[DEBUG]` prefix + `.inspect` on all values
2. **Deploy** to staging, reproduce, filter with `grep "[DEBUG]"`
3. **Analyze** parameter flow, identify gap
4. **Remove** after root cause identified

## Optimization History

- **March 13, 2026**: Five-step optimizer pass 1. 363 → 105 lines (71%).
- **April 1, 2026**: Five-step optimizer pass 2. Deleted Layer 3 standalone (duplicate of Layer 2 verification), Log Filtering section (shown in every example), Pattern summaries (code speaks for itself). 105 → 42 lines (60%).
