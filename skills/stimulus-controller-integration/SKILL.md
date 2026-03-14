---
name: stimulus-controller-integration
description: "Stimulus controller patterns for AJAX initialization, CustomEvent communication, and controller reuse. Trigger keywords: Stimulus controller, connect timing, MutationObserver, off-DOM construction, readiness polling, CustomEvent detail, sibling communication, dual dispatch, controller reuse, data-controller reinit, event bubbling, data attribute sync, cache key bump. (global)"
allowed-tools: Read, Grep, Glob
---

# Stimulus Controller Integration
## Initialization

### Defensive Guards for Timing Races

```javascript
connect() {
  if (!this) return;
  if (!this.scope || !this.element) return;
  // Proceed with initialization
}
```

### Solution 1: Attribute Manipulation (Controllers Not Initializing)

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

### Solution 2: Container Scoping (Parent Controllers Disconnecting)

```javascript
// WRONG - Wrapper includes parent controller
this.reinitializeStimulusControllers(wrapper);

// RIGHT - Only reinit content children
const contentArea = wrapper.querySelector('.content');
this.reinitializeStimulusControllers(contentArea);
```

### Solution 3: Off-DOM Construction (MutationObserver Not Detecting)

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

### Solution 4: Bypass Stimulus (Critical UI with Persistent Timing Issues)

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

### Solution 5: Readiness Polling (User Can Click Before Controller Ready)

```javascript
async waitForControllerReady(element, identifier, options = {}) {
  const { maxAttempts = 20, pollInterval = 50, timeout = 1000 } = options;
  const start = Date.now();

  for (let i = 1; i <= maxAttempts; i++) {
    if (Date.now() - start > timeout) return null;
    const ctrl = this.application.getControllerForElementAndIdentifier(element, identifier);
    if (ctrl?.scope && ctrl?.element) return ctrl;
    await new Promise(r => setTimeout(r, pollInterval));
  }
  return null;
}
```

### Initialization Decision Tree

```
Controllers not initializing?       -> Attribute Manipulation
Parent controllers disconnecting?   -> Container Scoping
MutationObserver not detecting?      -> Off-DOM Construction
this.context still undefined?        -> Bypass Stimulus
User clicks before ready?            -> Readiness Polling
```

## Communication

### Standardized CustomEvent Pattern

Always assign data directly to `detail`, never nest it.

**Dispatcher**:
```javascript
/**
 * Event: 'product:selected'
 * Structure: { detail: productData }
 * Data: { id, display_name, images, selected_color_id }
 * Listeners: canvas-artboard, canvas-colors
 */
triggerProductSelection() {
  const customEvent = new CustomEvent('product:selected', {
    bubbles: true,
    detail: this.productData  // Direct assignment (NOT nested)
  });
  this.element.dispatchEvent(customEvent);

  // Also dispatch on document for global listeners
  document.dispatchEvent(new CustomEvent('product:selected', {
    bubbles: true,
    detail: this.productData
  }));
}
```

**Handler**:
```javascript
async handleProductSelected(event) {
  const productData = event.detail;  // Read directly
  if (!productData) return;
  if (!productData.id) return;
  // Process event...
}
```

### FORBIDDEN: Nested Detail Property

```javascript
// WRONG - Creates confusion, fragile
new CustomEvent('event', {
  detail: { productData: this.productData }  // Nested!
});

// Handlers would need event.detail.productData - easy to forget
```

### Sibling Controller Communication

DOM events only bubble UP the tree, not sideways to siblings.

```html
<div id="parent-container">
  <div data-controller="dropzone">...</div>    <!-- Events bubble UP from here -->
  <div data-controller="attachments">...</div>  <!-- This sibling won't receive them -->
</div>
```

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

// Listener
connect() {
  this.handler = this.handleUpload.bind(this);
  document.addEventListener('dropzone:queuecomplete', this.handler);
}
disconnect() {
  document.removeEventListener('dropzone:queuecomplete', this.handler);
}
```

**Option 3: Listen on common ancestor**:
```javascript
const ancestor = document.getElementById('parent-container');
if (ancestor) {
  this.handler = this.handleUpload.bind(this);
  ancestor.addEventListener('dropzone:queuecomplete', this.handler);
}
```

### Listener Target Must Match Dispatch Target

Events dispatched to `document` will NOT be received by listeners on `this.element`.

| Dispatch Target | Listener Target | Works? |
|-----------------|-----------------|--------|
| `document` | `document` | Yes |
| `document` | `this.element` | No |
| `this.element` | `document` | Yes (bubbles up) |
| `this.element` | `this.element` | Yes |
| `this.element` | sibling element | No |

**Rule**: If you dispatch to `document`, ALL listeners for that event should be on `document`.

### Dual Dispatch for Multiple Consumers

When different consumers expect different event names or are in different DOM subtrees.

```javascript
async uploadFile(file) {
  const artwork = await response.json();

  // Event 1: dropzone:upload for artboard (clear loading spinner)
  this.element.dispatchEvent(new CustomEvent('dropzone:upload', {
    bubbles: true, detail: { file: {}, response: artwork }
  }));

  // Event 2: dropzone:uploadsuccess on element (for local listeners)
  this.element.dispatchEvent(new CustomEvent('dropzone:uploadsuccess', {
    bubbles: true, detail: { file: {}, response: artwork }
  }));

  // Event 3: Same event on document (for different DOM subtree listeners)
  document.dispatchEvent(new CustomEvent('dropzone:uploadsuccess', {
    detail: { file: {}, response: artwork }
  }));
}
```

**Decision Matrix**:

| Consumer Location | Consumer Event Name | Dispatch Strategy |
|-------------------|---------------------|-------------------|
| Same subtree | Same event | Element only |
| Same subtree | Different event | Element with both event names |
| Different subtree | Same event | Element + document |
| Different subtree | Different event | Element with both names + document |

### Event-Based Architecture for Controller Timing Issues

When you CAN'T safely access controller instance properties, use events instead of polling.

**Problem**: `getControllerForElementAndIdentifier()` returns controller instance, but property getters throw errors before `connect()` completes. No safe way to check readiness.

**Sender**:
```javascript
saveButton.addEventListener('click', async (e) => {
  e.preventDefault();
  const saveEvent = new CustomEvent('modal:triggerSave', {
    bubbles: true, cancelable: true,
    detail: { source: 'footer-save-button', button: saveButton }
  });
  this.wrapper.dispatchEvent(saveEvent);
});
```

**Receiver**:
```javascript
connect() {
  this.handleSaveEvent = this.handleSaveEvent.bind(this);
  this.element.addEventListener('modal:triggerSave', this.handleSaveEvent);
}

disconnect() {
  if (this.handleSaveEvent) {
    this.element.removeEventListener('modal:triggerSave', this.handleSaveEvent);
  }
}

async handleSaveEvent(event) {
  try {
    const button = event.detail?.button;
    const saved = await this.triggerAutosave(button);
    if (!saved) event.preventDefault();  // Signal failure
  } catch (error) {
    event.preventDefault();  // Signal failure
  }
}
```

**Why this works**: No controller instance access, self-timing (receiver handles when IT'S ready), no race conditions, memory safe with proper cleanup.

### Event Naming Convention

Pattern: `namespace:entity:action` (e.g., `product:selected`, `colors:select`, `artwork:drop`, `placement:updated`).

### Event Communication Checklist

**Before Dispatching**:
- Event name follows `namespace:action` pattern
- Data assigned directly to `detail` (not nested)
- `bubbles: true` set if event should propagate
- Event structure documented in comment

**Before Handling**:
- Listener attached in `connect()`, removed in `disconnect()`
- Handler bound with `.bind(this)`
- Guard clause checks for missing/invalid data
- Listener target matches dispatch target

## Reuse

### Identify Reuse Opportunities

Before creating a new controller, check if existing controller can be reused.

```bash
# Search for existing controllers with similar functionality
grep -r "delete\|update\|increment\|decrement" app/javascript/controllers/
```

**Key Indicator**: If you're about to write `class NewController extends Controller` with methods that duplicate existing controller logic, stop and consider reuse.

### Map Required Targets

Analyze existing controller's `static targets`, data attributes, and `data-action` patterns. Ensure the new partial provides all of them.

```javascript
// Existing controller
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

### Handle Context-Specific Element References

```javascript
// Controller checks element type for table-specific logic
if (this.quantityCellTarget.tagName === 'TD') {
  this.quantityCellTarget.colSpan = 3;
}
// Or use CSS classes instead of inline styles
this.priceCellTarget.classList.add('hidden');
```

### Page Reload for State-Changing Operations

Deletion operations require page reload to synchronize all UI elements.

```javascript
delete(event) {
  fetch(url, { method: 'POST', body: `ids=${lineItemId}` })
    .then(response => response.json())
    .then(jsonResponse => {
      if (jsonResponse.success) {
        if (jsonResponse.message && window.App?.showSuccessFlash) {
          window.App.showSuccessFlash(jsonResponse.message);
        }
        window.location.reload();  // Sync cart total, badges, empty state
      }
    });
}
```

### Sync Data Attributes for Dynamic Content

When images/content change dynamically, ALL related data attributes must be synced in EVERY place content changes.

```javascript
// Gallery controller - orientation photo selection
updateMainImage(imageUrl, originalUrl) {
  const imgElement = this.currentPhotoTarget.querySelector('img');
  if (imgElement) {
    imgElement.src = imageUrl;
    if (originalUrl) imgElement.dataset.originalUrl = originalUrl;  // CRITICAL
  }
}

// Product details controller - color swatch click
selectColor(event) {
  const imageUrl = event.currentTarget.dataset.imageUrl;
  const originalUrl = event.currentTarget.dataset.originalUrl;
  if (this.hasImageTarget && imageUrl) {
    this.imageTarget.src = imageUrl;
    if (originalUrl) this.imageTarget.dataset.originalUrl = originalUrl;  // CRITICAL
  }
}
```

**Common failure**: Color selection changes `src` but not `data-original-url`, so zoom modal shows wrong image.

### Bump Cache Key Versions

When changing HTML structure for controller reuse, bump fragment cache key versions.

```erb
# v2: Added image-zoom controller for click-to-zoom functionality
cache_key = ['product-show-v2', 'photo', color_variant.id, color_variant.updated_at.to_i]
```

### Add CSS for New Container Classes

```scss
/* Original - dealer page */
.product-photo-primary[data-controller="image-zoom"] {
  position: relative; overflow: hidden;
}
/* New - retail page */
.current-photo[data-controller="image-zoom"] {
  position: relative; overflow: hidden;
}
```

## FORBIDDEN Patterns

```javascript
// Reinit on large containers (disconnects parent)
this.reinitializeStimulusControllers(document.body);

// Checking context.scope (may be undefined)
if (controller.context.scope) { }  // WRONG
if (controller.scope) { }          // RIGHT

// Attaching empty then filling (MutationObserver misses)
document.body.appendChild(wrapper);
wrapper.innerHTML = html;  // WRONG order

// Nested detail property
detail: { productData: obj }  // Fragile

// Mismatched dispatch/listener targets
document.dispatchEvent(event);
this.element.addEventListener('event', handler);  // Never fires

// Duplicate controller for identical functionality
class CheckoutLineItemController extends Controller {
  delete(event) { /* Same logic as cart_row#delete */ }
}

// Missing required targets in reused controller
<li data-controller="cart-row">
  <span>Qty</span>  <!-- No targets! Controller will fail -->
</li>
```

## Violation Detection

```bash
# Find problematic attachment patterns
grep -A 10 "appendChild.*wrapper" app/javascript/controllers/*.js | grep -B 5 "innerHTML"

# Find reinit on large containers
grep -r "reinitializeStimulusControllers" app/javascript/ | grep "document.body\|this.wrapper"

# Find duplicate controllers
grep -r "delete(event)" app/javascript/controllers/ | cut -d: -f1 | sort | uniq

# Find missing data attribute syncing
grep -A5 "\.src =" app/javascript/controllers/*.js | grep -v "dataset\."
```
