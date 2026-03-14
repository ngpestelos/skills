---
name: controller-input-validation-edge-cases
description: "Guidance on implementing comprehensive input validation in Rails controller actions before processing to prevent edge case failures. Auto-activates for controller validation, missing parameters, edge cases, bulk actions, multi-tenant security, empty results, parameter flexibility, parameter fallback, partial updates. Trigger keywords: controller validation, input validation, edge cases, missing parameters, validate before processing, multi-tenant validation, malformed parameters, negative dimensions, 422 unprocessable entity, validation errors, proactive validation, rescue block anti-pattern, bulk operations, flexible parameter access, graceful empty handling, parameter fallback, partial update, use existing value, model state fallback, optional parameter default, missing param fallback, params to_s strip blank. (global)"
allowed-tools: Read, Grep, Glob
---

# Controller Input Validation Edge Cases

## Core Principles

1. **Validate Then Process**: Proactively validate all inputs before business logic execution
2. **Explicit Over Implicit**: Return specific error messages for each validation failure (not generic rescue block errors)
3. **Multi-Tenant Security**: Always validate that referenced resources belong to the current tenant (dealer, sale, etc.)
4. **Flexible Parameter Handling**: Support multiple parameter formats when tests and production use different structures
5. **Graceful Empty Handling**: Return success with appropriate messaging when operations have no data to process
6. **Fallback to Model State**: For partial updates, use existing model values when optional parameters are missing (enables updating one field without re-submitting all fields)

## The Problem: Rescue Block Anti-Pattern

### WRONG - Relying on Rescue Blocks

```ruby
def handle_bulk_action
  product_ids = params[:bulk_options][:product_ids]

  result = current_sale.bulk_process_products(
    product_ids: product_ids,
    action_params: action_params,
    bulk_options: bulk_options
  )

  # ... render result
rescue StandardError => e
  Rails.logger.error "Bulk action failed: #{e.message}"
  render json: { error: 'Unable to process. Please try again.' }, status: :unprocessable_entity
end
```

**Problems:**
- Missing parameters raise exceptions caught by generic rescue
- Malformed data (e.g., String instead of Hash) proceeds silently or crashes
- No validation that resource belongs to current tenant (security issue)
- Negative values accepted without validation
- Empty selections get generic error instead of specific message
- Tests expecting 422 validation errors get 201 success or generic 422

## REQUIRED Patterns

### 1. Proactive Parameter Validation

```ruby
def handle_bulk_action
  # STEP 1: Flexible parameter access
  product_ids = if params[:bulk_options].present? && params[:bulk_options][:product_ids].present?
                  params[:bulk_options][:product_ids]
                elsif params[:product_ids].present?
                  params[:product_ids]
                else
                  []
                end

  # STEP 2: Validate product selection
  if product_ids.blank? || product_ids.empty?
    return render json: { error: 'No products selected' }, status: :unprocessable_entity
  end

  # STEP 3: Validate action params structure
  unless params[:action_params].present?
    return render json: { error: 'Action parameters are required' }, status: :unprocessable_entity
  end

  action_params_hash = params[:action_params]

  # STEP 4: Validate required nested parameters
  if action_params_hash[:required_ids].blank?
    return render json: { error: 'At least one item must be selected' }, status: :unprocessable_entity
  end

  # Continue to business logic...
end
```

### 2. Multi-Tenant Security Validation

```ruby
# STEP 5: Validate resources belong to current tenant
resource_ids = action_params_hash[:resource_ids]
valid_resource_ids = Resource.where(id: resource_ids, tenant_id: Current.tenant.id).pluck(:id)

if valid_resource_ids.size != resource_ids.size
  return render json: { error: 'Selected resource does not belong to this account' }, status: :unprocessable_entity
end
```

**Why This Matters:**
- Prevents cross-tenant data access
- Returns 422 validation error instead of proceeding with wrong data
- Provides specific error message for debugging

### 3. Data Type and Value Validation

```ruby
# Validate dimensions structure
dimensions = action_params_hash[:dimensions]

# Check it's the right type
if !dimensions.is_a?(Hash) && !dimensions.is_a?(ActionController::Parameters)
  return render json: { error: 'Dimensions must be a valid object' }, status: :unprocessable_entity
end

# Check values are positive
if dimensions[:width].to_i <= 0 || dimensions[:height].to_i <= 0
  return render json: { error: 'Dimensions must be positive numbers' }, status: :unprocessable_entity
end
```

### 4. Tenant-Scoped Filtering

```ruby
# STEP 6: Filter products to only those belonging to current sale
scoped_product_ids = current_sale.products.where(id: product_ids).pluck(:id)

if scoped_product_ids.empty?
  return render json: { error: 'No valid products found' }, status: :unprocessable_entity
end

# Use scoped_product_ids in business logic, not the raw product_ids
```

**Benefits:**
- Prevents cross-sale data modification
- Returns appropriate error when all products filtered out
- Uses only validated, scoped IDs in processing

### 5. Graceful Empty Result Handling

**In Model/Service Layer:**

```ruby
def bulk_process_products(product_ids:, action_params:, bulk_options: {})
  records = scope.where(product_id: product_ids)
  record_ids = records.pluck(:id)

  # Handle case where no records exist
  if record_ids.empty?
    Rails.logger.info "No records found for products #{product_ids.inspect}"
    return {
      total: 0,
      completed: 0,
      failed_batches: [],
      success: true
    }
  end

  # Continue with processing...
end
```

**In Controller:**

```ruby
if result[:success]
  if result[:total] == 0
    render json: { notice: 'No items found to process', total: 0 }, status: :ok
  else
    notice = "Action applied to #{result[:completed]} item#{'s' if result[:completed] != 1}"
    render json: { notice: notice, total: result[:total] }, status: :created
  end
end
```

### 6. Flexible Parameter Format Handling

When tests use different parameter formats than production:

```ruby
def action_params
  # Handle both formats:
  # 1. Production format: ids, width, height at top level
  # 2. Test format: action_params nested object with dimensions inside

  if params[:action_params].present? && params[:action_params].is_a?(ActionController::Parameters)
    # Test format - extract from nested action_params
    action_params_obj = params[:action_params]
    dimensions = action_params_obj[:dimensions] || {}

    {
      resource_ids: action_params_obj[:resource_ids] || [],
      dimensions: {
        width: dimensions[:width],
        height: dimensions[:height]
      }
    }.with_indifferent_access
  else
    # Production format - extract from top level params
    # ... original logic
  end
end
```

### 7. Optional Parameter Safety

```ruby
def bulk_options
  if params[:bulk_options].present?
    params.require(:bulk_options).permit(
      :template_id,
      :apply_to,
      loaded_product_ids: [],
      product_ids: []
    )
  else
    # Return empty hash when bulk_options not present
    {}.with_indifferent_access
  end
end
```

**Prevents:**
- `ActionController::ParameterMissing` exception when `bulk_options` not in params
- Generic rescue block catching and returning unhelpful error

### 8. Parameter Fallback to Model State

When a parameter is optional and should default to the existing model value (for partial updates):

```ruby
def update_resource
  # Get parameter, convert nil to empty string
  sanitized_name = params[:name].to_s.strip

  # Fallback to existing model value when blank
  sanitized_name = current_resource.name if sanitized_name.blank?

  # Final validation - ensure we have a valid value (edge case: existing also blank)
  raise ArgumentError, 'Name is required' if sanitized_name.blank?

  # Proceed with the validated value
  UpdateResource.perform_now(
    resource: current_resource,
    name: sanitized_name,
    available: available_param
  )
end
```

**Pattern Structure:**
1. Extract and sanitize the parameter: `params[:name].to_s.strip`
2. Check if result is blank
3. If blank, use existing model value: `model.attribute`
4. Final validation in case both are blank (edge case)
5. Proceed with guaranteed non-blank value

**Use When:**
- Endpoint supports partial updates (update only some fields)
- Parameter is conceptually "optional" because it has an existing value
- Callers shouldn't need to re-send unchanged values
- Job/service layer validates for blanks (would fail with empty string)

**Common Pitfall - params[:x].to_s.strip converts nil to "":**
```ruby
# WRONG - nil becomes "", which may fail downstream validation
sanitized_name = params[:name].to_s.strip  # nil -> "" -> job raises "Missing name"

# RIGHT - fallback to existing value when blank
sanitized_name = params[:name].to_s.strip
sanitized_name = current_model.name if sanitized_name.blank?
```

## Quick Decision Tree

| Scenario | Validation Needed | Response Code |
|----------|-------------------|---------------|
| Empty array parameter | Check `.blank?` or `.empty?` | 422 with specific message |
| Missing required param | Check `.present?` | 422 with specific message |
| Wrong data type | Check `.is_a?(Hash)` | 422 with specific message |
| Invalid values | Check ranges, positivity | 422 with specific message |
| Cross-tenant reference | Query with tenant scope, compare size | 422 with security message |
| Optional parameter | Check `.present?` before `.require` | Return safe default |
| Empty result set | Check `.empty?` in service layer | 200 with `total: 0` |
| Malformed nested structure | Type check nested params | 422 with format message |
| Partial update param | Fallback to `model.attribute` if blank | Use existing value |

## Violation Detection

```bash
# Find controller actions with rescue but no validation
grep -A 30 "def handle_\|def bulk_" app/controllers/**/*.rb | \
  grep -B 30 "rescue StandardError" | \
  grep -L "return render.*unprocessable_entity"

# Find direct params access without presence checks
grep -rn "params\[.*\]\[.*\]" app/controllers/ --include="*.rb" | \
  grep -v "\.present?" | \
  grep -v "if params"

# Find multi-tenant models used without tenant scoping
grep -rn "Resource.find\|Resource.where" app/controllers/ | \
  grep -v "tenant_id:\|Current.tenant"

# Find actions that don't handle empty result sets
grep -A 20 "\.pluck(:id)" app/controllers/ | \
  grep -B 5 "\.empty?" | \
  grep -L "return render"
```

