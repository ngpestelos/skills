---
name: static-html-app-development
description: "Patterns for building and testing static HTML/CSS/JS apps deployed to Cloudflare Pages. Prevents file:// localStorage trap, provides browser-based test suite pattern. Auto-activates when building static sites, using open index.html, generating file:// URLs, debugging localStorage issues, or creating vanilla JS apps. Trigger keywords: static site, vanilla JS, localStorage blocked, file:// URL, browser test, Cloudflare Pages app, open index.html."
allowed-tools: Read, Grep, Glob, Bash
---

# Static HTML App Development

Patterns for building dependency-free web apps as static files deployed to Cloudflare Pages.

## file:// localStorage Trap

**Always serve via HTTP. Never open index.html directly.**

```bash
python3 -m http.server 8788 --directory /path/to/project
open http://localhost:8788
```

Chrome, Brave, and Safari treat `file://` URLs as unique security origins. Code using `localStorage`, `sessionStorage`, or `indexedDB` silently fails — the page renders but interactive features appear broken (clicks do nothing, state doesn't persist). The console shows "Unsafe attempt to load URL" but the connection to localStorage is non-obvious.

**When to suspect this**: Page renders correctly but onclick handlers appear dead. Check the URL bar — if it says `file:///`, that's the problem.

## Browser-Based Test Suite

For vanilla JS apps with no build step, create a `test.html` that loads the app and runs assertions.

```html
<div id="app" style="display:none"></div>
<div id="results"></div>
<script src="app.js"></script>
<script>
let pass = 0, fail = 0;
function assert(cond, name) { cond ? pass++ : fail++; }
function suite(name, fn) { results.push({ suite: name }); fn(); }

suite('Math: generators', () => {
  for (let i = 0; i < 20; i++) {
    const p = genFoo();
    assert(p.answer !== undefined, 'has answer');
  }
});
</script>
```

**Conventions**:
- Serve via HTTP (same localStorage trap applies to tests)
- Hidden `div#app` if app.js references it on load
- Run random generators 20x to catch edge cases
- Clean localStorage before and after state tests
- Render results as colored HTML, not console-only
- When separating CSS/JS from index.html via `sed`, extract with `sed -n 'START,ENDp'`
