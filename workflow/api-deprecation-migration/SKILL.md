---
name: api-deprecation-migration
description: "Migrate a skill to a new API provider when the current service is deprecated or sunsetted."
triggers:
  - "is being deprecated"
  - "is being sunsetted"
  - "migrate from"
  - "api is shutting down"
  - "service is ending"
allowed-tools: Read, Write, terminal
---

# API Deprecation Migration

Migrate a skill to a new API provider when the current service is deprecated.

## Steps

1. **Identify replacement service** — Research alternatives:
   - Direct competitors (e.g., Tenor → GIPHY)
   - Community recommendations
   - Feature parity requirements

2. **Update environment variables**:
   ```bash
   # Old
   OLD_API_KEY=***
   
   # New
   NEW_API_KEY=***
   ```

3. **Migrate API calls**:
   | Component | Update |
   |-----------|--------|
   | Base URL | `old.api.com` → `new.api.com` |
   | Auth header/key param | Match new provider's format |
   | Endpoint paths | Update to new structure |
   | Response parsing | Adapt to new JSON schema |

4. **Map equivalent features**:
   - Identify feature parity gaps
   - Document breaking changes
   - Update examples with new response format

5. **Test and commit**:
   - Verify API key works
   - Test search/download flows
   - Update skill version (major bump for breaking changes)

## Common Migration Patterns

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| Tenor GIF API | GIPHY API | Different response structure, env var name |
| OpenWeatherMap v2.5 | v3.0 | New endpoint paths, subscription model |

## Pitfalls

- **Response format changes** — Always check new JSON structure
- **Feature loss** — New provider may lack certain features
- **Rate limits** — May differ significantly
- **Cost changes** — Free tier may differ

## Example: Tenor → GIPHY

**Changed:**
- `TENOR_API_KEY` → `GIPHY_API_KEY`
- `tenor.googleapis.com/v2` → `api.giphy.com/v1`
- `.results[].media_formats.gif.url` → `.data[].images.original.url`
- Response structure: `results[]` → `data[]`
