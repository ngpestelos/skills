---
name: broken-not-unnecessary
description: Before deleting or removing a feature that "rarely works" or "never completes," verify WHY it fails. The failure mode often reveals an implementation bug with a fixable root cause rather than a genuine requirement to remove. Trigger keywords: rarely completes, never fires, dead code, delete step, remove feature, noop, informational screen, collects no data, always fails.
version: 1.1.0
---

# Broken Not Unnecessary

> **Is the failure intrinsic to the requirement, or is it an implementation constraint?**

A plan proposes removing a feature because it "rarely completes," "collects no data," or "never fires." The plan is correct about the symptom but wrong about the cause.

**Example (2026-04-06):** Dealer onboarding Step 2 (Stripe Connect) "rarely completes during the wizard." Plan said: delete it. Actual reason: `POST /api/stripe/connect/onboard` requires `requireAuth` — the owner user doesn't exist yet at that wizard step, so the endpoint is unreachable. Fix: move Owner Account before Stripe Connect. Deleting it would have broken payment processing platform-wide.

## Process

1. Read the actual handler — understand what it does when it runs correctly
2. Find the failure path — why does it fail or rarely complete?
3. If the implementation constraint were removed, would this feature be valuable?
   - Yes → fix the constraint, keep the feature
   - No → delete it

## Signals: Fix, Not Delete

- Feature works in one context (post-login) but not another (pre-login wizard)
- Feature requires auth/session/config that doesn't exist at the call site
- Deleting it breaks a cross-app integration (payments, SSO, webhooks)

## Signals: Delete

- Data collected is provably never read or forwarded
- Feature only sets a progress flag and discards the payload
- No cross-app impact; business requirement has changed
