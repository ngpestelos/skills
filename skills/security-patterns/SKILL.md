---
name: security-patterns
description: Proactive security analysis for XSS prevention, CSRF protection, parameter logging, payment security, multi-tenant isolation, and cache poisoning. Use when handling user input, writing templates with dynamic content, implementing AJAX requests, adding logging, processing payments, or working with multi-tenant systems.
license: MIT
compatibility: Best suited for Ruby on Rails applications, but patterns apply to any web framework.
metadata:
  author: ngpestelos
  version: "1.0"
---

# Security-First Patterns

## Core Security Principle

**All user input is untrusted. Every output must be escaped. Every state transition must be validated.**

## Top Security Violations (90% of Issues)

1. **Unescaped user input** (XSS vulnerability)
2. **Parameter values in logs** (PII exposure)
3. **Missing CSRF tokens** in AJAX requests
4. **Console statements** in production code
5. **Payment state transitions** using `return false` (bypass vulnerability)
6. **Multi-tenant scoping** violations
7. **Cache poisoning** in multi-tenant resolution (data isolation breach)

## XSS Prevention (Critical Priority)

### ERB Templates

```erb
<!-- FORBIDDEN: Unescaped user input -->
<h1><%= @product.name %></h1>

<!-- CORRECT: Always escape user input -->
<h1><%= h(@product.name) %></h1>
```

### JavaScript/JS.ERB

```javascript
// FORBIDDEN: Unescaped data in JS context
const userName = "<%= @user.name %>";

// CORRECT: Use j() helper for JavaScript escaping
const userName = "<%= j(@user.name) %>";

// CORRECT: Use textContent for user data
element.textContent = "<%= j(@content) %>";
```

### Tooltip Attributes

```erb
<!-- FORBIDDEN: Unescaped user data in tooltips -->
<button title="<%= @product.name %>">View</button>

<!-- CORRECT: Always escape tooltip content -->
<button title="<%= h(@product.name) %>">View</button>
```

## Parameter Logging (PII Protection)

```ruby
# FORBIDDEN: Logging user input values
Rails.logger.info "User email: #{params[:email]}"
Rails.logger.info "Request params: #{params.inspect}"

# CORRECT: Log field keys only, NEVER values
Rails.logger.error "Invalid input for field: #{field_name}"
Rails.logger.info "User #{current_user.id} updated profile"
```

Never log: `email`, `password`, `card_number`, `cvv`, `ssn`, `phone`, `address`, or any `params[...]` values.

## CSRF Protection

```javascript
// FORBIDDEN: Missing CSRF token
fetch('/api/products', { method: 'POST', body: JSON.stringify(data) });

// CORRECT: Include CSRF token in headers
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
fetch('/api/products', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
  body: JSON.stringify(data)
});
```

## Payment Security

### State Machine Transitions

```ruby
# VULNERABILITY: return false doesn't halt transitions
before_transition to: :paid do |payment|
  return false unless payment.amount_valid?  # DOES NOT HALT!
end

# CORRECT: Use throw(:halt) to stop transitions
before_transition to: :paid do |payment|
  throw(:halt) unless payment.amount_valid?
end
```

## Multi-Tenant Isolation

```ruby
# FORBIDDEN: Unscoped queries (cross-tenant data leak)
Product.all
Order.where(status: 'pending')

# CORRECT: Always scope by current tenant
current_tenant.products
current_tenant.orders.where(status: 'pending')
```

### Cache Poisoning in Multi-Tenant Resolution

Caching in tenant resolution paths can cause catastrophic data isolation breaches. Remove caching entirely — use direct indexed lookups (< 1ms).

**Caching is FORBIDDEN for**: subdomain-to-tenant resolution, user-to-tenant association, any authentication/authorization decision path.

## Security Violation Detection

```bash
# XSS vulnerabilities
grep -r "raw(\|html_safe\|<%==" app/views/

# Parameter logging violations
grep -r "Rails\.logger.*#{.*params" app/

# Console statements in production
grep -r "console\.\(log\|error\|warn\|debug\)" app/javascript/

# CSRF token issues in AJAX
grep -r "fetch\|axios" app/javascript/ | grep -v "X-CSRF-Token"

# Multi-tenant violations
grep -r "Product\.all\|Order\.all\|User\.all" app/controllers/
```

## Quick Security Checklist

- [ ] No `raw()`, `html_safe`, or `<%== %>` with user input
- [ ] All JavaScript interpolation uses `j()`
- [ ] No `params[...]` values in log statements
- [ ] CSRF tokens in all AJAX POST/PUT/DELETE requests
- [ ] No `console.log`, `debugger`, or `alert()` in code
- [ ] Payment state transitions use `throw(:halt)` not `return false`
- [ ] All queries scoped by current tenant
- [ ] File uploads validate extension, double extension, then size
- [ ] Nil guards for payment and user operations
- [ ] No PII in logs
