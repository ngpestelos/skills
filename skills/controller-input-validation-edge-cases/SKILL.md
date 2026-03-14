---
name: controller-input-validation-edge-cases
description: "Guidance on implementing comprehensive input validation in Rails controller actions before processing to prevent edge case failures. Auto-activates for controller validation, missing parameters, edge cases, bulk actions, multi-tenant security, empty results, parameter fallback, partial updates. Trigger keywords: controller validation, input validation, edge cases, missing parameters, validate before processing, multi-tenant validation, malformed parameters, negative dimensions, 422 unprocessable entity, validation errors, proactive validation, rescue block anti-pattern, bulk operations, parameter fallback, partial update, model state fallback, params to_s strip blank. (global)"
allowed-tools: Read, Grep, Glob
---

# Controller Input Validation Edge Cases

Validate all inputs proactively before business logic. Don't rely on rescue blocks catching `NoMethodError` or `ParameterMissing` — they produce generic errors and hide security issues.

## Validation Patterns

### 1. Multi-Tenant Security Validation

Always validate that referenced resources belong to the current tenant. Scope queries by tenant, then compare counts.

```ruby
resource_ids = action_params[:resource_ids]
valid_resource_ids = Resource.where(id: resource_ids, tenant_id: Current.tenant.id).pluck(:id)

if valid_resource_ids.size != resource_ids.size
  return render json: { error: 'Selected resource does not belong to this account' }, status: :unprocessable_entity
end

# Also scope collections to current context
scoped_product_ids = current_sale.products.where(id: product_ids).pluck(:id)

if scoped_product_ids.empty?
  return render json: { error: 'No valid products found' }, status: :unprocessable_entity
end

# Use scoped_product_ids, not raw product_ids
```

### 2. Data Type and Value Validation

```ruby
dimensions = action_params[:dimensions]

# Check type
if !dimensions.is_a?(Hash) && !dimensions.is_a?(ActionController::Parameters)
  return render json: { error: 'Dimensions must be a valid object' }, status: :unprocessable_entity
end

# Check values are positive
if dimensions[:width].to_i <= 0 || dimensions[:height].to_i <= 0
  return render json: { error: 'Dimensions must be positive numbers' }, status: :unprocessable_entity
end
```

### 3. Graceful Empty Result Handling

Return success with appropriate messaging when operations have no data to process.

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

### 4. Parameter Fallback to Model State

For partial updates, use existing model values when optional parameters are missing.

```ruby
def update_resource
  sanitized_name = params[:name].to_s.strip

  # Fallback to existing model value when blank
  sanitized_name = current_resource.name if sanitized_name.blank?

  # Final validation — both param and model could be blank
  raise ArgumentError, 'Name is required' if sanitized_name.blank?

  UpdateResource.perform_now(resource: current_resource, name: sanitized_name)
end
```

Note: `params[:x].to_s.strip` converts `nil` to `""` — always check `.blank?` and fall back to `model.attribute`.

## Decision Tree

| Scenario | Validation Needed | Response Code |
|----------|-------------------|---------------|
| Empty array parameter | Check `.blank?` or `.empty?` | 422 with specific message |
| Missing required param | Check `.present?` | 422 with specific message |
| Wrong data type | Check `.is_a?(Hash)` | 422 with specific message |
| Invalid values | Check ranges, positivity | 422 with specific message |
| Cross-tenant reference | Query with tenant scope, compare size | 422 with security message |
| Empty result set | Check `.empty?` in service layer | 200 with `total: 0` |
| Partial update param | Fallback to `model.attribute` if blank | Use existing value |
