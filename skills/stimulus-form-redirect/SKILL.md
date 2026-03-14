---
name: stimulus-form-redirect
description: "Replace AJAX + DOM manipulation with form submission + server redirect. Trigger keywords: form submission redirect, fetch to form submit, DOM manipulation removal, window.location.href, simplify Stimulus controller, handleSuccess pattern, updateSidebar, AJAX to redirect, bulk form submit, server-side redirect. (global)"
---

# Stimulus Form Submission Redirect Simplification

### Before: Complex AJAX + DOM Manipulation

```javascript
// Complex pattern - maintaining client-side state
export default class extends Controller {
  submit(event) {
    event.preventDefault()

    fetch(this.element.action, {
      method: 'POST',
      headers: { 'X-CSRF-Token': this.csrfToken },
      body: new FormData(this.element)
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.handleSuccess(data)
      }
    })
  }

  handleSuccess(data) {
    // Complex DOM manipulation
    this.updateSidebar(data.sidebar_html)
    this.updateContent(data.content_html)
    this.showActionsContainer()
    window.App.showSuccessFlash(data.message)
  }

  updateSidebar(html) {
    const sidebar = document.getElementById('sidebar-list')
    if (sidebar && html) {
      sidebar.innerHTML = html // Potential XSS, complexity
    }
  }
}
```

### After: Simple Form Submission + Redirect

```javascript
// Simplified pattern - server handles state
export default class extends Controller {
  submit(event) {
    event.preventDefault()

    fetch(this.element.action, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.csrfToken,
        'Accept': 'application/json'
      },
      body: new FormData(this.element)
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.handleSuccess(data)
      } else {
        this.handleError(data)
      }
    })
  }

  handleSuccess(data) {
    // Simple redirect - server renders correct state
    if (data.redirect_url) {
      window.location.href = data.redirect_url
    } else {
      window.location.reload()
    }
  }

  handleError(data) {
    const errors = data.errors || ['An error occurred']
    window.App.showErrorFlash(errors.join(', '))
  }
}
```

## Bulk Operations via Form Submission

For bulk operations (deleting multiple items), create a hidden form:

```javascript
deleteSelected(event) {
  event.preventDefault()

  if (this.selectedItems.size === 0) return

  if (!window.confirm(`Delete ${this.selectedItems.size} items?`)) {
    return
  }

  // Create form dynamically
  const form = document.createElement('form')
  form.method = 'POST'
  form.action = '/items/bulk_destroy'

  // Method override for DELETE
  const methodInput = document.createElement('input')
  methodInput.type = 'hidden'
  methodInput.name = '_method'
  methodInput.value = 'delete'
  form.appendChild(methodInput)

  // CSRF token
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  const tokenInput = document.createElement('input')
  tokenInput.type = 'hidden'
  tokenInput.name = 'authenticity_token'
  tokenInput.value = csrfToken
  form.appendChild(tokenInput)

  // Item IDs
  this.selectedItems.forEach(id => {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = 'item_ids[]'
    input.value = id
    form.appendChild(input)
  })

  document.body.appendChild(form)
  form.submit()
}
```

## Server-Side Support

Controller returns JSON with redirect_url:

```ruby
def create
  @record = current_scope.build(record_params)

  respond_to do |format|
    if @record.save
      format.json do
        render json: {
          success: true,
          redirect_url: records_path,
          message: 'Created successfully'
        }
      end
    else
      format.json do
        render json: {
          success: false,
          errors: @record.errors.full_messages
        }
      end
    end
  end
end

# Bulk operations use redirect directly
def bulk_destroy
  ids = params[:item_ids]

  if ids.present?
    destroyed_count = current_scope.where(id: ids).destroy_all.count
    flash[:notice] = "#{destroyed_count} item(s) deleted"
  else
    flash[:error] = 'No items selected'
  end

  redirect_to records_path
end
```

## Updating JavaScript Tests

### Before: DOM Manipulation Tests

```javascript
// Tests for old DOM manipulation - no longer needed
test('updates sidebar with new HTML', () => {
  // Verified complex DOM updates
})
```

### After: Redirect Behavior Tests

```javascript
describe('handleSuccess', () => {
  let originalLocation

  beforeEach(() => {
    originalLocation = window.location
    delete window.location
    window.location = { href: '', reload: jest.fn() }
  })

  afterEach(() => {
    window.location = originalLocation
  })

  test('redirects to redirect_url when provided', () => {
    controller.handleSuccess({
      success: true,
      redirect_url: '/items'
    })

    expect(window.location.href).toBe('/items')
  })

  test('reloads page when no redirect_url', () => {
    controller.handleSuccess({ success: true })

    expect(window.location.reload).toHaveBeenCalled()
  })
})
```

## Benefits

1. **Reduced Complexity**: No client-side HTML parsing or DOM updates
2. **Single Source of Truth**: Server templates render correct state
3. **Simpler Testing**: Test redirect behavior, not DOM manipulation
4. **Fewer Edge Cases**: No partial update failures or stale DOM
5. **Better Maintainability**: UI changes only need template updates
6. **Security**: No XSS risk from client-side HTML insertion

## When NOT to Use

- **Real-time Updates**: When immediate feedback without page flash is required
- **Partial Updates**: When only small part of page needs updating (use Turbo)
- **Long Lists**: When page reload would lose scroll position
- **Form Wizards**: When multi-step forms need to preserve state

