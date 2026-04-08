---
name: security-patterns
description: "Quick-reference security checklist for XSS, CSRF, PII logging, console statements, multi-tenant isolation, and state machine security in Rails views, controllers, and JavaScript. Auto-activates when writing or modifying controllers, views, or JavaScript that handle user input, reviewing code for security violations, or pre-commit security verification."
license: MIT
compatibility: Ruby on Rails applications with ERB templates and JavaScript frontends.
metadata:
  author: ngpestelos
  version: "2.0.0"
---

# Security-First Quick Reference

**All user input is untrusted. Every output must be escaped. Every state transition must be validated.**

## Security Violations: Fix + Detect

| Priority | Violation | Quick Fix | Detection |
|----------|-----------|-----------|-----------|
| 1 | Unescaped user input (XSS) | `h()` in ERB, `j()` in JS, `textContent` not `innerHTML` | `grep -r "<%=\s*@\w\+\." app/views/ \| grep -v " h(\| html_escape(\| j("` |
| 2 | Parameter values in logs (PII) | Log keys only, never values | `grep -r "Rails\.logger.*#{.*params" app/` |
| 3 | Missing CSRF tokens in AJAX | `X-CSRF-Token` header on all POST/PUT/DELETE | `grep -r "fetch\|axios" app/javascript/ \| grep -v "X-CSRF-Token"` |
| 4 | Console/alert in production | Remove or use structured logging | `grep -r "console\.\(log\|error\|warn\|debug\)" app/javascript/` |
| 5 | `return false` in state machines | `throw(:halt)` to actually stop transitions | Check state machine callbacks for `return false` |
| 6 | Multi-tenant scoping violations | Always scope by `current_tenant` | `grep -r "Product\.all\|Order\.all\|User\.all" app/controllers/` |
| 7 | Cache poisoning in tenant resolution | Remove caching from auth/tenant paths | Review tenant resolution for memoization or caching |

## PII Fields (Never Log Values Of)

`email`, `password`, `card_number`, `cvv`, `ssn`, `tax_id`, `phone`, `address`, any `params[...]`
