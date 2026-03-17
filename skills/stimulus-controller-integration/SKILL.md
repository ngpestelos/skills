---
name: stimulus-controller-integration
description: "Stimulus controller patterns for AJAX initialization, CustomEvent communication, and controller reuse. Trigger keywords: Stimulus controller, connect timing, MutationObserver, readiness polling, CustomEvent detail, sibling communication, event bubbling, data-controller reinit."
license: MIT
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# Stimulus Controller Integration

## Initialization

Controllers not initializing? → Attribute Manipulation. Parent disconnecting? → Scope reinit to content container, not parent. MutationObserver not detecting? → Build complete off-DOM, attach once. `this.context` undefined? → Use `getControllerForElementAndIdentifier()` as escape hatch. User clicks before ready? → Readiness Polling.

Add defensive guards in `connect()`: `if (!this.scope || !this.element) return;`

### Attribute Manipulation (Controllers Not Initializing)

Remove and re-add `data-controller` to force Stimulus reconnection. Scope to content container (not parent wrapper) to avoid disconnecting parent controllers.

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

Always assign data directly to `detail`, never nest it. Event naming: `namespace:action` (e.g., `product:selected`, `artwork:drop`).

```javascript
// Dispatching
const event = new CustomEvent('product:selected', {
  bubbles: true,
  detail: this.productData  // Direct assignment (NOT { productData: ... })
});
this.element.dispatchEvent(event);

// Handling
handleProductSelected(event) {
  const productData = event.detail;  // Read directly
  if (!productData?.id) return;
}
```

### Dispatch/Listener Target Matching

Events dispatched to `document` will NOT be received by listeners on `this.element`.

| Dispatch Target | Listener Target | Works? |
|-----------------|-----------------|--------|
| `document` | `document` | Yes |
| `document` | `this.element` | No |
| `this.element` | `document` | Yes (bubbles up) |
| `this.element` | `this.element` | Yes |
| `this.element` | sibling element | No |

**Rule**: If you dispatch to `document`, ALL listeners must be on `document`.

### Sibling / Cross-Subtree Communication

DOM events only bubble UP, not sideways. Dispatch to `document` for siblings. When consumers span subtrees, dispatch on both `this.element` (for local bubbling) and `document` (for distant listeners). Attach in `connect()`, remove in `disconnect()`.

```javascript
connect() {
  this.handler = this.handleUpload.bind(this);
  document.addEventListener('dropzone:queuecomplete', this.handler);
}
disconnect() {
  document.removeEventListener('dropzone:queuecomplete', this.handler);
}
```

## Reuse

Before reusing a controller in a new context: verify all `static targets`, data attributes, and `data-action` patterns exist in the new partial. Change container elements freely (`<tr>` → `<li>`) but preserve all data attributes. Use CSS classes instead of `tagName` checks for context-specific styling.
