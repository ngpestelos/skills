---
name: multi-panel-formdata-sync
description: "Fixes the querySelector('form') first-form bug in controllers wrapping repeated panels with per-item forms. Trigger: wrong form submitted, hidden field from first panel, querySelector form first, FormData sync."
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: "2.0.1"
---

# Multi-Panel FormData Sync

> **Problem**: `this.element.querySelector('form')` returns the **first** `<form>` in the subtree — not the one belonging to the selected panel. Any hidden field that varies per panel submits stale data.

## Principles

1. Per-panel identity flows from server (data attribute) to client (dataset read), not from which form was collected.
2. `formData.delete()` + `formData.append()` corrects stale fields after initial `new FormData(form)`.
3. Emit data attributes **conditionally** — never render `data-foo=""` when the value is nil.

## Required Pattern

**ERB** — conditional data attribute on each panel container:

```erb
<div class="panel-container"
     id="panel-container-<%= item.id %>"
     <%= "data-item-address-id=\"#{item.bulk_address_id}\"" if item.bulk_address_id %>>
```

**JS** — sync FormData after radio selection resolves:

```javascript
const form = this.element.querySelector('form'); // OK for shared fields
const formData = new FormData(form);
formData.append('shipping_methods', shippingMethodId);

// Sync per-panel hidden field from the SELECTED panel's data attribute
const panel = document.getElementById(`panel-container-${shippingMethodId}`);
const panelValue = panel?.dataset.itemAddressId;
if (panelValue) {
  formData.delete('hidden_field_name');
  formData.append('hidden_field_name', panelValue);
}
```

The panel container ID must use the same identifier carried by the radio value so the lookup works.

## Forbidden Pattern

```javascript
// WRONG — hidden fields come from panel 1 even when panel 3 is selected
const form = this.element.querySelector('form');
const formData = new FormData(form);
// formData now has stale per-panel values
```

## Decision Table

| Situation | Action |
|-----------|--------|
| One form per controller | `querySelector('form')` is fine |
| Multiple panels, each with a form | Data attribute on panel + FormData sync |
| Hidden field varies per panel | `formData.delete` + `formData.append` after radio resolve |
| Value may be nil | Conditional ERB emission (no bare `data-foo="<%= val %>"`) |

## Common Mistake

Syncing only the primary field (e.g., `shipping_methods`) but forgetting other per-panel hidden fields (e.g., `default_shipping_address_id`). Every hidden field that encodes per-panel state needs explicit `delete` + `append`.

## Violation Detection

```bash
# Controllers using querySelector('form') on a wrapping element
grep -rn "querySelector.*'form'" app/javascript/controllers/
# ERB with unconditional data-*-id that might be nil
grep -rn 'data-.*-id="<%= ' app/views/ | grep -v "if "
```

## Activation Triggers

- Bug report: "wrong address/option shown" after selecting a non-first item
- `querySelector('form')` in a controller handling multi-option panel selection
- Submitted parameter always matches the first item regardless of selection
