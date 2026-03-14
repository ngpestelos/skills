---
name: stimulus-form-redirect
description: "Replace AJAX + DOM manipulation with form submission + server redirect. Trigger keywords: form submission redirect, fetch to form submit, DOM manipulation removal, window.location.href, simplify Stimulus controller, handleSuccess pattern, updateSidebar, AJAX to redirect, bulk form submit, server-side redirect. (global)"
---

# Stimulus Form Submission Redirect Simplification

Replace client-side DOM manipulation after AJAX with server redirect. Instead of parsing HTML responses and updating multiple DOM elements (sidebar, content, flash), let the server render the correct state on redirect.

## The Pattern

```javascript
// WRONG - Complex DOM manipulation after AJAX
handleSuccess(data) {
  this.updateSidebar(data.sidebar_html)    // innerHTML = XSS risk
  this.updateContent(data.content_html)
  this.showActionsContainer()
  window.App.showSuccessFlash(data.message)
}

// RIGHT - Server redirect handles state
handleSuccess(data) {
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
```

## Bulk Operations via Hidden Form

For bulk operations (deleting multiple items), create a hidden form and submit it. The server handles the redirect.

```javascript
deleteSelected(event) {
  event.preventDefault()
  if (this.selectedItems.size === 0) return
  if (!window.confirm(`Delete ${this.selectedItems.size} items?`)) return

  const form = document.createElement('form')
  form.method = 'POST'
  form.action = '/items/bulk_destroy'

  // Add hidden fields: _method=delete, authenticity_token, item_ids[]
  const addField = (name, value) => {
    const input = Object.assign(document.createElement('input'), {
      type: 'hidden', name, value
    })
    form.appendChild(input)
  }

  addField('_method', 'delete')
  addField('authenticity_token', document.querySelector('meta[name="csrf-token"]')?.content)
  this.selectedItems.forEach(id => addField('item_ids[]', id))

  document.body.appendChild(form)
  form.submit()
}
```

## Server-Side Support

Controller returns JSON with `redirect_url` for AJAX, or redirects directly for form submissions.

```ruby
# Bulk operations redirect directly
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

## When NOT to Use

- **Real-time Updates**: When immediate feedback without page flash is required
- **Partial Updates**: When only small part of page needs updating (use Turbo)
- **Long Lists**: When page reload would lose scroll position
- **Form Wizards**: When multi-step forms need to preserve state
