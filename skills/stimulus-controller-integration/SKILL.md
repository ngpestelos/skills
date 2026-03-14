---
name: stimulus-controller-integration
description: "Stimulus controller patterns for AJAX initialization, CustomEvent communication, and controller reuse. Trigger keywords: Stimulus controller, connect timing, MutationObserver, off-DOM construction, readiness polling, CustomEvent detail, sibling communication, dual dispatch, controller reuse, data-controller reinit, event bubbling, data attribute sync, cache key bump. (global)"
allowed-tools: Read, Grep, Glob
---

# Stimulus Controller Integration

## Initialization

### Decision Tree

```
Controllers not initializing?       -> Attribute Manipulation
Parent controllers disconnecting?   -> Container Scoping
MutationObserver not detecting?      -> Off-DOM Construction
this.context still undefined?        -> Bypass Stimulus
User clicks before ready?            -> Readiness Polling
```

Add defensive guards in `connect()`: `if (!this.scope || !this.element) return;`

### Attribute Manipulation (Controllers Not Initializing)

```javascript
reinitializeStimulusControllers(container) {
  setTimeout(() => {
    container.querySelectorAll('[data-controller]').forEach(el => {
      const value = el.dataset.controller;
      el.removeAttribute('data-controller');
      setTimeout(() => {
        if (el.isConnected) el.setAttribute('data-controller', value);
      }, 50);
    });
  }, 10);
}
```

### Container Scoping (Parent Controllers Disconnecting)

```javascript
// WRONG - Wrapper includes parent controller
this.reinitializeStimulusControllers(wrapper);

// RIGHT - Only reinit content children
const contentArea = wrapper.querySelector('.content');
this.reinitializeStimulusControllers(contentArea);
```

### Off-DOM Construction (MutationObserver Not Detecting)

```javascript
// WRONG - Attach empty, add content later
this.wrapper = document.createElement('div');
document.body.appendChild(this.wrapper);
this.wrapper.innerHTML = await fetch(url).then(r => r.text());

// RIGHT - Build complete, attach once
this.wrapper = document.createElement('div');
this.wrapper.innerHTML = await fetch(url).then(r => r.text());
document.body.appendChild(this.wrapper);
```

### Bypass Stimulus (Critical UI with Persistent Timing Issues)

Use `getControllerForElementAndIdentifier()` to access the controller directly when event-based patterns aren't viable.

```javascript
setupDirectHandler() {
  const button = this.wrapper.querySelector('[data-target="modal.button"]');
  if (button.dataset.directHandler) return;
  button.dataset.directHandler = 'true';

  button.addEventListener('click', async (e) => {
    e.preventDefault();
    const controller = this.application.getControllerForElementAndIdentifier(
      this.wrapper.querySelector('[data-controller*="modal"]'), 'modal'
    );
    if (controller?.save) await controller.save();
  });
}
```

### Readiness Polling (User Can Click Before Controller Ready)

```javascript
async waitForControllerReady(element, identifier, { maxAttempts = 20, timeout = 1000 } = {}) {
  const start = Date.now();
  for (let i = 0; i < maxAttempts; i++) {
    if (Date.now() - start > timeout) return null;
    const ctrl = this.application.getControllerForElementAndIdentifier(element, identifier);
    if (ctrl?.scope && ctrl?.element) return ctrl;
    await new Promise(r => setTimeout(r, 50));
  }
  return null;
}
```

## Communication

### CustomEvent Pattern

Always assign data directly to `detail`, never nest it.

```javascript
// Dispatching
triggerProductSelection() {
  const event = new CustomEvent('product:selected', {
    bubbles: true,
    detail: this.productData  // Direct assignment (NOT { productData: ... })
  });
  this.element.dispatchEvent(event);
}

// Handling
handleProductSelected(event) {
  const productData = event.detail;  // Read directly
  if (!productData?.id) return;
}
```

**Event naming**: `namespace:action` (e.g., `product:selected`, `colors:select`, `artwork:drop`).

### Dispatch/Listener Target Matching

Events dispatched to `document` will NOT be received by listeners on `this.element`.

| Dispatch Target | Listener Target | Works? |
|-----------------|-----------------|--------|
| `document` | `document` | Yes |
| `document` | `this.element` | No |
| `this.element` | `document` | Yes (bubbles up) |
| `this.element` | `this.element` | Yes |
| `this.element` | sibling element | No |

**Rule**: If you dispatch to `document`, ALL listeners for that event should be on `document`.

### Sibling Controller Communication

DOM events only bubble UP the tree, not sideways to siblings.

**Option 1: Dispatch to specific sibling by ID**:
```javascript
const sibling = document.getElementById('attachments-container');
if (sibling) {
  sibling.dispatchEvent(new CustomEvent('dropzone:queuecomplete', { bubbles: true }));
}
```

**Option 2: Dispatch to document (global)**:
```javascript
// Dispatcher
document.dispatchEvent(new CustomEvent('dropzone:queuecomplete', {
  bubbles: true, detail: this.uploadResults
}));

// Listener - attach in connect(), remove in disconnect()
connect() {
  this.handler = this.handleUpload.bind(this);
  document.addEventListener('dropzone:queuecomplete', this.handler);
}
disconnect() {
  document.removeEventListener('dropzone:queuecomplete', this.handler);
}
```

### Dual Dispatch for Cross-Subtree Consumers

When consumers exist in different DOM subtrees, dispatch on both `this.element` (for local listeners that bubble) and `document` (for distant listeners).

```javascript
// Local consumers get it via bubbling
this.element.dispatchEvent(new CustomEvent('dropzone:uploadsuccess', {
  bubbles: true, detail: { file: {}, response: artwork }
}));

// Distant consumers get it via document
document.dispatchEvent(new CustomEvent('dropzone:uploadsuccess', {
  detail: { file: {}, response: artwork }
}));
```

| Consumer Location | Same Event Name | Different Event Name |
|-------------------|-----------------|----------------------|
| Same subtree | Element only | Element with both names |
| Different subtree | Element + document | Element with both + document |

## Reuse

### Map Required Targets

Before reusing a controller in a new context, analyze its `static targets`, data attributes, and `data-action` patterns. The new partial must provide all of them.

```javascript
export default class extends Controller {
  static targets = ['quantityCell', 'staticDisplay', 'editInterface',
                    'quantityInput', 'priceCell', 'totalCell'];
  delete(event) { /* uses data-slug, data-id from button */ }
}
```

### Adapt HTML Structure

Change container elements while preserving all data-controller, data-target, and data-action attributes.

**Original (table-based)**:
```erb
<tr data-controller="cart-row" data-sale-slug="<%= sale_slug %>">
  <td data-target="cart-row.quantityCell">
    <span data-target="cart-row.staticDisplay">Qty</span>
  </td>
</tr>
```

**Adapted (list-based)**:
```erb
<li data-controller="cart-row" data-sale-slug="<%= sale_slug %>">
  <span data-target="cart-row.quantityCell">
    <span data-target="cart-row.staticDisplay">Qty</span>
  </span>
</li>
```

For context-specific element logic (e.g., `tagName === 'TD'`), use CSS classes instead of inline styles to handle differences between container types.
