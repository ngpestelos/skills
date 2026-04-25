---
name: stimulus-controller-integration
description: "Stimulus controller patterns for AJAX initialization, CustomEvent communication, and controller reuse. Trigger keywords: Stimulus controller, connect timing, MutationObserver, readiness polling, CustomEvent detail, sibling communication, event bubbling, data-controller reinit."
license: MIT
metadata:
  author: ngpestelos
  version: "2.1.1"
---

# Stimulus Controller Integration

## Initialization

Controllers not initializing? → Attribute Manipulation. Parent disconnecting? → Scope reinit to content container, not parent. `this.context` undefined? → `getControllerForElementAndIdentifier()`. User clicks before ready? → Readiness Polling. Always guard `connect()`: `if (!this.scope || !this.element) return;`

### Attribute Manipulation

Remove and re-add `data-controller` to force reconnection. Scope to content container (not parent) to avoid disconnecting parent controllers.

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

### Readiness Polling

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

Assign data directly to `detail` (never nest). Name events `namespace:action` (e.g., `product:selected`).

```javascript
// Dispatch
this.element.dispatchEvent(new CustomEvent('product:selected', {
  bubbles: true,
  detail: this.productData  // Direct — NOT { productData: ... }
}));

// Handle
handleProductSelected(event) {
  const productData = event.detail;
  if (!productData?.id) return;
}
```

### Dispatch/Listener Target Matching

| Dispatch Target | Listener Target | Works? |
|-----------------|-----------------|--------|
| `document` | `document` | Yes |
| `document` | `this.element` | **No** |
| `this.element` | `document` | Yes (bubbles) |
| `this.element` | `this.element` | Yes |
| `this.element` | sibling element | **No** |

Siblings need `document` as dispatch target. For cross-subtree consumers, dispatch on both `this.element` and `document`. Always attach in `connect()`, remove in `disconnect()`.

## Reuse

Before reusing a controller: verify all `static targets`, data attributes, and `data-action` exist in the new partial. Container elements can change (`<tr>` → `<li>`) — data attributes cannot. Use CSS classes instead of `tagName` checks.
