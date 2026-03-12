---
name: test-plan-methodology
description: Systematic 4-phase test planning approach to prevent coverage blind spots. Enforces usage-based testing (not just feature-based) to catch multi-location deployment gaps. Use when planning tests, analyzing coverage, performing gap analysis, or testing shared components deployed across multiple pages.
license: MIT
metadata:
  author: ngpestelos
  version: "1.0"
---

# Test Plan Methodology

## Purpose

Prevent test coverage blind spots by enforcing **usage-based test planning** across all feature deployment locations. Discovered during analysis where shared partials had comprehensive tests in one context but ZERO coverage in other deployment locations.

## Critical Discovery: Linter Blind Spot

**Feature-based test organization creates coverage blind spots:**

```
Linter Report:
  _shared_partial.html.erb - COMPREHENSIVE coverage (28 JS tests)
  controller.rb - PARTIAL coverage (13 backend tests)

Reality:
  Primary Index page - ZERO coverage for shared partial
  Secondary Edit page - 2 incidental assertions only
```

**Why This Happens**: Linters organize tests by file/feature, not by usage location. A partial can have comprehensive tests in one context but ZERO tests in other deployment locations. Coverage reports don't reveal multi-location gaps.

## 4-Phase Test Planning Methodology

### Phase 1: Primary Page Integration Tests

**Focus**: Test feature rendering and structure on main usage page

- Does the feature render on the primary page?
- Are all data attributes present and correct?
- Are CSS framework classes preserved?
- Are sub-partials rendering correctly?

**Typical Test Count**: 4-6 tests per primary page

### Phase 2: Secondary Page Integration Tests

**Focus**: Test feature rendering on ALL other deployment locations

- Does the feature render on secondary pages?
- Are data attributes consistent across pages?
- Does the feature work identically in all contexts?

**Typical Test Count**: 2-4 tests per secondary page

### Phase 3: Backend Integration Tests

**Focus**: Verify AJAX endpoint responses and JSON structure

- Do endpoints return correct JSON for success/error cases?
- Are validation errors properly formatted?
- Are server errors handled gracefully?

**Typical Test Count**: 3-5 tests per endpoint

### Phase 4: Multi-Page Consistency Tests

**Focus**: Verify feature behaves consistently across deployment locations

- Is the feature structurally identical across pages?
- Are unique IDs generated correctly for different contexts?
- Are there any page-specific edge cases?

**Typical Test Count**: 2-3 consistency tests

## Steps: Planning Tests for a New Feature

1. **Identify ALL usage locations**:
   ```bash
   grep -r "render.*[partial_name]" app/views/
   ```

2. **Plan tests for EACH location separately**:
   - Phase 1: Primary page integration tests (4-6 tests)
   - Phase 2: Secondary page integration tests (2-4 tests per page)
   - Phase 3: Backend integration tests (3-5 tests)
   - Phase 4: Multi-page consistency tests (2-3 tests)

3. **Don't rely on linter coverage reports alone** — feature-based organization hides multi-location gaps.

## Gap Analysis Methodology

1. Document current coverage per layer (JS, backend, integration)
2. Identify ALL deployment locations
3. Calculate target: ~15-25 tests for comprehensive coverage
4. Prioritize by risk: HIGH (zero coverage) > MEDIUM (partial) > LOW (consistency)

## Quick Decision Tree

```
Planning tests?
  New feature -> Apply 4-phase methodology
  Coverage review -> Check usage-based coverage
    Find deployments -> grep render statements
    Check each location -> Separate test files
    Document gaps -> Create test plan
  Gap discovery -> Systematic gap analysis
```
