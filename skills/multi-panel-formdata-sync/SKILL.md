---
name: multi-panel-formdata-sync
description: "Fixes the querySelector('form') first-form bug when a Stimulus controller wraps a repeated list where each panel has its own hidden-field form. Auto-activates when: panel list with per-item forms, radio selection with hidden fields, Stimulus findFormElement, wrong form submitted, first address shown. Covers: data attribute DOM contract, FormData sync after radio resolution, conditional ERB attribute emission. Trigger keywords: querySelector form first, wrong form submitted, hidden field sync, shipping method panel, formData delete append. (project)"
allowed-tools: Read, Grep, Glob, Bash
---

# Multi-Panel FormData Sync

> **Purpose**: Fix the "first form wins" bug in Stimulus controllers that call `querySelector('form')` over a repeated panel list where each panel has its own hidden fields.

## Core Principles

1. `this.element.querySelector('form')` always returns the **first** `<form>` in the DOM subtree — not the one belonging to the selected panel.
2. Per-panel identifiers must flow from server (ERB data attribute) to client (JS reads dataset), not from which form was collected.
3. FormData sync (`delete` + `append`) corrects stale field values after the initial collection.
4. Emit data attributes **conditionally** — only when the server has a real value; never render `data-foo=""`.

## ✅ REQUIRED Patterns

### Step 1: ERB — emit data attribute on each panel container (conditionally)

```erb
<div class="panel-container"
     id="panel-container-<%= item.id %>"
     <%= "data-item-address-id=\"#{item.bulk_address_id}\"" if item.bulk_address_id %>
     style="<%= panel_style %>">
```

### Step 2: JS — sync FormData after radio selection resolves

```javascript
// Inside addShippingMethodParameter (or equivalent):
formData.append('shipping_methods', shippingMethodId);

// Sync hidden field to match the selected panel, not the first form
const selectedPanel = document.getElementById(
  `panel-container-${shippingMethodId}`
);
const panelValue = selectedPanel?.dataset.itemAddressId;
if (panelValue) {
  formData.delete('hidden_field_name');
  formData.append('hidden_field_name', panelValue);
}
```

## ❌ FORBIDDEN Patterns

### Always-first form selection

```javascript
// WRONG — picks the first <form> regardless of which panel is active
const form = this.element.querySelector('form');
const formData = new FormData(form);
// formData now has hidden fields from panel 1 even if panel 3 is selected
```

### Unconditional nil data attribute

```erb
<%# WRONG — renders data-foo="" on every item when value is nil %>
<div data-foo="<%= item.some_id %>">
```

## Quick Decision Tree

| Situation | Solution |
|-----------|----------|
| One form per controller | `querySelector('form')` is fine |
| Multiple panels, each with a form | Data attribute on panel + FormData sync |
| Hidden field differs per panel | Always sync via `formData.delete` + `formData.append` |
| Value may be nil/absent | Conditionally emit the attribute |

## Common Mistakes

1. **Fixing only `shipping_methods` but not `default_shipping_address_id`** — the radio detection correctly finds the selected method ID, but any other hidden field that encodes per-panel state must also be synced explicitly.
2. **Empty-string data attribute** — `data-foo=""` is falsy in JS (`dataset.foo === ""`) so the `if (panelValue)` guard works, but the attribute is still misleading HTML. Always use conditional ERB emission.
3. **Wrong ID convention** — the panel container ID must use the same identifier that the radio value carries (e.g., `panel-container-${shippingMethodId}` matches `value="${shippingMethodId}"`).

## Examples

### ❌ WRONG — First form's hidden field always submitted

```javascript
// findFormElement() returns Newport's form even when SAC is selected
const form = this.element.querySelector('form');
const formData = new FormData(form);
// formData['default_shipping_address_id'] = Newport's ID  ← bug
formData.append('shipping_methods', sacMethodId);  // correct method ID
// server gets: shipping_methods=SAC, default_shipping_address_id=Newport  ← wrong address
```

### ✅ RIGHT — Sync from panel data attribute

```javascript
const form = this.element.querySelector('form');  // still OK to use for other fields
const formData = new FormData(form);

// After resolving the selected radio:
formData.append('shipping_methods', shippingMethodId);

const selectedPanel = document.getElementById(
  `shipping-method-panel-container-${shippingMethodId}`
);
const bulkAddressId = selectedPanel?.dataset.bulkAddressId;
if (bulkAddressId) {
  formData.delete('default_shipping_address_id');
  formData.append('default_shipping_address_id', bulkAddressId);
}
// server gets: shipping_methods=SAC, default_shipping_address_id=SAC  ← correct
```

## Violation Detection

```bash
# Find Stimulus controllers that use querySelector('form') on a wrapping element
grep -n "querySelector.*'form'" app/javascript/controllers/*.js

# Find ERB partials rendering unconditional data-*-id attributes that might be nil
grep -n 'data-.*-id="<%= ' app/views/shared/*.erb | grep -v "if "
```

## Integration

- **Related Skills**: [Stimulus Form Redirect skill](/.claude/skills/stimulus-form-redirect/SKILL.md)
- **Discovered**: 2026-03-04, fixing `fix-wrong-shipping-address-shown-order-review` (Carl Baker report)

## When to Use This Skill

Auto-activates when:
- A Stimulus controller wraps a list of panels where each panel has a `<form>` with hidden fields
- A bug report says "wrong address/option shown" after selecting a non-first item from a list
- `findFormElement()` or `querySelector('form')` appears in a controller that handles multi-option selection
- Debugging why a submitted parameter matches the first item's value regardless of selection

## Key Takeaway

`querySelector('form')` is unaware of which panel the user selected. Use a `data-*` attribute on the panel container (emitted conditionally from ERB) and sync the affected FormData fields in JS using `delete` + `append` after radio resolution.
