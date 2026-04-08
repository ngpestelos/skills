---
name: browser-resource-hints-optimization
description: "Provides guidance on using browser resource hints (preconnect, dns-prefetch, preload, prefetch) to optimize page load performance. Auto-activates when discussing CDN performance, external resources, page load optimization, layout head sections, or connection latency. Trigger keywords: preconnect, dns-prefetch, preload, prefetch, resource hints, CDN performance, page load, connection latency, external resources, unpkg, cdnjs, font loading, script loading, layout head, _head.html.erb."
allowed-tools: Read, Grep, Glob
---

# Browser Resource Hints Optimization

Use browser resource hints to establish early connections to external domains and optimize page load performance.

## Resource Hint Types

| Hint Type | What It Does | When to Use |
|-----------|--------------|-------------|
| `preconnect` | DNS + TCP + TLS connection | CDNs used on every page |
| `dns-prefetch` | DNS lookup only | Domains used occasionally |
| `preload` | Force immediate download | Critical above-fold resources |
| `prefetch` | Download for future navigation | Resources for likely next page |

## Correct Pattern

Add preconnect hints at the **top** of `<head>`, before any other tags:

```erb
<!-- app/views/layouts/_head.html.erb -->
<link rel="preconnect" href="https://unpkg.com" crossorigin>
<link rel="preconnect" href="https://cdnjs.cloudflare.com" crossorigin>

<meta charset="utf-8" />
<!-- ... rest of head content ... -->
```

Saves ~200-400ms per domain on initial page load (DNS ~50-100ms + TCP ~50-100ms + TLS ~100-200ms).

## Key Rules

- Place hints at the top of `<head>` — maximum time for browser to establish connections
- Use `crossorigin` attribute for CORS resources (scripts/stylesheets from CDNs)
- Only preconnect to 2-4 critical domains — browser limits concurrent connections
- Never place resource hints after stylesheets — browser already blocked on download
- Missing `crossorigin` on CDN resources means browser can't reuse the connection for CORS fetch

## Optimization History

- **March 13, 2026**: Applied five-step optimizer. 157 → 67 lines (61%).
- **March 23, 2026**: Five-step optimizer pass 2. Deleted Common External Domains table (project-specific, goes stale — grep views instead) and Violation Detection section (standard grep patterns). 67 → 42 lines (37%).
