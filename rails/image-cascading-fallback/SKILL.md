---
name: image-cascading-fallback
description: "Defensive image rendering with automatic fallback from missing/404 URLs to alternative sources and placeholders. Auto-activates for image fallback, 404 handling, S3 missing images, client-side fallback cascade. Trigger keywords: image fallback, 404 detection, missing images, placeholder, cascading URLs, IMG onerror, background-image fallback."
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Image Cascading Fallback Pattern

Defensive image rendering with automatic fallback from missing/404 URLs to alternative sources and placeholders.

## Server-Side: Fallback URL Generation

```ruby
def fallback_urls_for(style = :large)
  urls = []
  placeholder = style == :small ? '/placeholder_th.jpg' : '/placeholder.jpg'
  return [placeholder] if Rails.env.test?

  begin
    if primary_image.present?
      url = primary_image.url(style)
      urls << url if url.present? && url != placeholder
    end
    if alternative_image.present? && alternative_image != primary_image
      url = alternative_image.url(style)
      urls << url if url.present? && url != placeholder
    end
    urls << placeholder
  rescue StandardError => e
    Rails.logger.error("Error generating fallback URLs: #{e.message}")
    urls = [placeholder]
  end
  urls.uniq
end
```

## Template Integration (Stimulus 1.1.0)

```erb
<%
  fallback_urls = if record.respond_to?(:fallback_urls_for)
                    record.fallback_urls_for(:large)
                  else
                    [record.image_url || '/placeholder.jpg']
                  end
  primary_url = fallback_urls.first
%>
<div class="image-container"
     style="background-image: url(<%= primary_url %>);"
     data-controller="image-fallback"
     data-fallback-urls="<%= fallback_urls.to_json %>"></div>
```

## Client-Side: Stimulus Fallback Controller

Stimulus 1.1.0: `import from '../stimulus'`, custom data attributes, no `static values`.

```javascript
import { Controller } from '../stimulus';

export default class extends Controller {
  connect() {
    const urlsJson = this.element.getAttribute('data-fallback-urls');
    if (!urlsJson) return;
    try { this.urls = JSON.parse(urlsJson); } catch (e) { return; }
    if (!this.urls || this.urls.length === 0) return;

    this.currentIndex = 0;
    this.isImgElement = this.element.tagName === 'IMG';

    if (this.isImgElement) {
      this.boundHandleError = this.handleImgError.bind(this);
      this.element.addEventListener('error', this.boundHandleError);
    } else {
      this.tryCurrentUrl();
    }
  }

  disconnect() {
    if (this.isImgElement && this.boundHandleError) {
      this.element.removeEventListener('error', this.boundHandleError);
      this.boundHandleError = null;
    }
    if (this.imageLoader) {
      this.imageLoader.onload = null; this.imageLoader.onerror = null; this.imageLoader = null;
    }
  }

  handleImgError() {
    this.currentIndex++;
    if (this.currentIndex >= this.urls.length) return;
    this.element.src = this.urls[this.currentIndex];
  }

  tryCurrentUrl() {
    const url = this.urls[this.currentIndex];
    if (!url) return;
    if (this.imageLoader) { this.imageLoader.onload = null; this.imageLoader.onerror = null; }
    this.imageLoader = new Image();
    this.imageLoader.onload = () => this.cleanup();
    this.imageLoader.onerror = () => this.handleError();
    this.imageLoader.src = url;
  }

  handleError() {
    this.currentIndex++;
    if (this.currentIndex >= this.urls.length) { this.cleanup(); return; }
    this.element.style.backgroundImage = `url(${this.urls[this.currentIndex]})`;
    this.tryCurrentUrl();
  }

  cleanup() {
    if (this.imageLoader) { this.imageLoader.onload = null; this.imageLoader.onerror = null; this.imageLoader = null; }
  }
}
```

## IMG vs Background-Image

| Use IMG | Use Background-Image |
|---------|---------------------|
| Semantic content, alt text | Decorative, complex layouts |
| SEO, native lazy loading | Background positioning |

## Key Rules

- Never do server-side HTTP validation (latency, rate limits)
- URL order: primary → alternative → placeholder
- Always clean up event handlers in `disconnect()`
