---
name: cloudflare-r2-bill-estimator
description: "Estimates monthly Cloudflare R2 costs from usage data. Applies free tier deductions. Trigger keywords: R2 bill, R2 cost, R2 estimate, cloudflare bill, storage cost."
---

# Cloudflare R2 Bill Estimator

Operations almost always fall within the free tier for personal use. Storage is typically the only billable component.

| Component | Rate | Free Tier |
|---|---|---|
| Storage | $0.015/GB/month | 10 GB |
| Class A Ops (writes) | $4.50/million | 1M/month |
| Class B Ops (reads) | $0.36/million | 10M/month |
| Egress | $0 | — |

**Infrequent Access**: Storage $0.01/GB + $0.01/GB retrieval. Same operation rates.

Subtract free tier from each component, then multiply billable amounts by rates.

## Optimization History

- **March 23, 2026**: Five-step optimizer pass 1. 84 → 30 lines (64%).
- **April 2, 2026**: Five-step optimizer pass 2. Deleted calculation steps (Claude does math), source wikilink. 30 → 12 lines (60%).
