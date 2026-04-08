---
name: deployment-readiness
description: "Guides systematic preparation for production deployment when major feature work or test coverage expansion is complete. Automatically activates when discussing deployment readiness, production deployment, commit preparation, pull request creation, or post-deployment monitoring. Trigger keywords: deployment readiness, production deployment, commit preparation, pull request creation, deployment checklist, git commit message, post-deployment monitoring, ready to deploy, uncommitted changes."
metadata:
  version: 1.1.0
---

# Deployment Readiness

## Phase 1: Verify Completion (5-10 min)

- All tests passing (0 failures, 0 errors, 0 skips)
- No console.log, debugger, or temporary debug code
- Edge cases covered (nil values, zero amounts, empty collections)
- No breaking changes (or migration plan exists)
- Database migrations tested (if applicable)
- Documentation updated

## Phase 2: Prepare Commit (15-30 min)

Stage in order: production code → test files → documentation → configuration. Use `git rm` for moved/deleted files. Commit message: summary line + sections covering metrics (test counts, coverage %, bugs fixed), business impact.

## Phase 3: Create Pull Request (10-20 min)

Include: summary, coverage metrics, bug fixes with file:line refs, before/after quality table, deployment checklist, post-deployment monitoring plan.

## Phase 4: Production Deployment (30-60 min)

**Pre**: Final test suite, staging verification, rollback plan, team notification.
**Deploy**: Low-traffic window, monitor errors immediately, check dashboards, verify features.
**Post**: Smoke tests, migration verification, background job queues, monitoring/alerts.

## Phase 5: Post-Deployment Monitoring (1-2 weeks)

**First 24h**: Error rates, performance metrics, user-reported issues, background jobs, query performance.
**Ongoing**: Business metrics, edge case occurrences, financial accuracy, CI/CD stability.

**Issue response**: Minor → ticket + schedule fix. Moderate → hot-fix PR. Critical → rollback.

## Deployment Patterns

| Pattern | Risk | Approach |
|---------|------|----------|
| Large test coverage expansion | Low | Single comprehensive commit, standard deploy |
| Feature development with tests | Higher | Separate commits, feature flag, staging test, phased rollout |
| Production bug fixes | Urgent | Hot-fix branch, minimal scope, expedited review, immediate deploy |
