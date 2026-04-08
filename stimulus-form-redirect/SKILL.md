---
name: stimulus-form-redirect
description: "Replace AJAX + DOM manipulation with form submission + server redirect. Trigger keywords: form submission redirect, fetch to form submit, DOM manipulation removal, window.location.href, simplify Stimulus controller, handleSuccess pattern, AJAX to redirect, bulk form submit."
---

# Stimulus Form Redirect

Instead of parsing HTML responses and updating DOM elements (sidebar, content, flash) after AJAX, let the server render the correct state on redirect.

## The Pattern

```javascript
// WRONG — DOM manipulation after AJAX (innerHTML = XSS risk)
handleSuccess(data) {
  this.updateSidebar(data.sidebar_html)
  this.updateContent(data.content_html)
  this.showActionsContainer()
  window.App.showSuccessFlash(data.message)
}

// RIGHT — server redirect handles state
handleSuccess(data) {
  window.location.href = data.redirect_url || window.location.href
}
```

## Bulk Operations via Hidden Form

For bulk operations, create a hidden form and submit it — the server handles the redirect.

```javascript
deleteSelected(event) {
  event.preventDefault()
  if (this.selectedItems.size === 0) return
  if (!window.confirm(`Delete ${this.selectedItems.size} items?`)) return

  const form = document.createElement('form')
  form.method = 'POST'
  form.action = '/items/bulk_destroy'

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

## Server Side

```ruby
def bulk_destroy
  ids = params[:item_ids]
  if ids.present?
    count = current_scope.where(id: ids).destroy_all.count
    flash[:notice] = "#{count} item(s) deleted"
  else
    flash[:error] = 'No items selected'
  end
  redirect_to records_path
end
```

## When NOT to Use

- **Real-time updates** — immediate feedback without page flash needed
- **Partial updates** — only small part of page changes (use Turbo)
- **Long lists** — page reload loses scroll position
- **Form wizards** — multi-step forms need preserved state
