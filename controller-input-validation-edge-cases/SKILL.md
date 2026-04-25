---
name: controller-input-validation-edge-cases
description: "Proactive input validation in Rails controllers to prevent downstream errors and edge case failures: type checking, bounds validation, early failure patterns, multi-tenant scoping, parameter fallback to model state, and bulk operation validation."
license: MIT
metadata:
  category: rails
  author: ngpestelos
  version: 1.1.1
allowed-tools: Read, Grep, Glob
---

# Controller Input Validation Edge Cases

Validate inputs proactively before business logic. Rescue blocks catching `NoMethodError` or `ParameterMissing` produce generic errors and hide security issues.

## 1. Multi-Tenant Scoping

Always scope queries by tenant, then compare counts to detect cross-tenant references. Use the scoped IDs downstream, never the raw params.

```ruby
valid_ids = Resource.where(id: params[:resource_ids], tenant_id: Current.tenant.id).pluck(:id)

if valid_ids.size != params[:resource_ids].size
  return render json: { error: 'Resource does not belong to this account' }, status: :unprocessable_entity
end
```

Apply the same pattern to nested context: `current_sale.products.where(id: product_ids).pluck(:id)`.

## 2. Parameter Fallback to Model State

For partial updates, `params[:x].to_s.strip` converts `nil` to `""`. Fall back to the existing model value, then validate — both param and model could be blank.

```ruby
sanitized_name = params[:name].to_s.strip
sanitized_name = current_resource.name if sanitized_name.blank?
raise ArgumentError, 'Name is required' if sanitized_name.blank?
```

## 3. Bulk Operation Responses

Return success with `total: 0` when no items match, rather than erroring. Pluralize counts in notices.

```ruby
if result[:total] == 0
  render json: { notice: 'No items found to process', total: 0 }, status: :ok
else
  render json: { notice: "Applied to #{result[:completed]} item(s)", total: result[:total] }, status: :created
end
```

## Quick Reference

| Scenario | Pattern | Status |
|----------|---------|--------|
| Cross-tenant reference | Scope query + compare count | 422 |
| Partial update param | `.to_s.strip` → fallback to model | Use existing |
| Empty bulk input | Check `.blank?` before processing | 422 |
| Zero results after processing | Return success with `total: 0` | 200 |
