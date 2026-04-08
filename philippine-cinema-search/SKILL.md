---
name: philippine-cinema-search
version: 2.0
description: "Find Philippine movie release dates and cinema info via ClickTheCity — bypasses Google CAPTCHA issues."
triggers:
  - "when will [movie] be shown in the Philippines"
  - "Philippines movie release date"
  - "cinema schedule Philippines"
  - "movie showing Philippines"
allowed-tools: browser_navigate, browser_snapshot, browser_click
---

# Philippine Cinema Search

Find movie release dates and cinema information for the Philippine market.

## Steps

1. **Navigate to ClickTheCity**
   ```
   browser_navigate: https://www.clickthecity.com/movies/
   ```

2. **Locate the movie**
   - Check "New This Week" / "Also This Week" carousels
   - Or "Now Showing" / "Coming Soon" sections

3. **Click movie entry** and get snapshot

4. **Extract**
   - Release Date
   - Rating (PG, R-13, R-16)
   - Runtime
   - Synopsis (to confirm correct movie)

## Pitfalls

- **ClickTheCity loads dynamically** — wait for content before snapshot
- **Element refs change** — always use fresh snapshot refs
- **Don't search Google first** — triggers CAPTCHA
