---
name: test-plan-methodology
description: Systematic 4-phase test planning approach to prevent coverage blind spots. Enforces usage-based testing (not just feature-based) to catch multi-location deployment gaps. Use when planning tests, analyzing coverage, performing gap analysis, or testing shared components deployed across multiple pages.
license: MIT
metadata:
  author: ngpestelos
  version: "1.1.0"
---

# Test Plan Methodology

## The Blind Spot: Feature-Based vs Usage-Based Coverage

Coverage tools organize by file/feature, not by deployment location. A shared partial can show comprehensive coverage while entire pages using it have zero tests.

```
Coverage Report Says:              Reality:
  _shared_partial - 28 tests         Index page  - ZERO partial coverage
  controller      - 13 tests         Edit page   - 2 incidental assertions
```

**Fix**: Plan tests per deployment location, not per source file.

## 4-Phase Planning

### 1. Primary Page Integration
Test feature rendering, data attributes, and sub-partials on the main usage page.

### 2. Secondary Page Integration
Test the same feature on every other page that uses it. Verify consistent rendering and data attributes across contexts.

### 3. Backend Integration
Verify endpoint responses: success/error JSON, validation formatting, error handling.

### 4. Cross-Page Consistency
Compare feature structure across pages. Check context-specific IDs and edge cases.

## Workflow

1. **Find all deployment locations**:
   ```bash
   grep -r "render.*[partial_name]" app/views/
   ```
2. **Plan tests per location** using the 4 phases above
3. **Prioritize gaps**: zero coverage > partial coverage > consistency

Never rely on coverage reports alone — they hide multi-location gaps.
