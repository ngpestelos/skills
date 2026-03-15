---
name: scanned-document-extraction
description: Extract structured data from scanned documents (images, PDFs) into markdown notes, preserving all granular detail. Auto-activates when reading scanned receipts, bills, medical records, statements, or any image/PDF containing tabular or itemized data. Trigger keywords: extract, scan, receipt, bill, statement, itemized, hospital bill, statement of account.
license: MIT
metadata:
  author: ngpestelos
  version: "1.0.0"
---

# Scanned Document Extraction

Extract all structured data from scanned images and PDFs into searchable, readable markdown. The purpose of extraction is to make scanned data queryable — compressing it into summaries defeats that purpose.

## Core Rule

**Preserve all granular detail.** Every line item, quantity, unit price, date, reference number, and name visible in the scan must appear in the output. Present both itemized detail AND a summary table — never drop line items to save space.

## Workflow

### Step 1: Read All Attachments

Locate all `![[embedded]]` files referenced in the note. Read each image and PDF. Do not skip any attachment — the text portion of a note may be incomplete without its embeds.

### Step 2: Extract Per Document

For each scanned document, extract into the appropriate format:

**Receipts / Statements of Account:**
- Header: facility, date, reference/receipt numbers
- Patient/customer details: name, address, ID numbers
- Itemized charges table: item, quantity, unit price
- Subtotals, discounts, insurance/PhilHealth deductions
- Payment method, cashier, timestamps

**Prescriptions / Medical Notes:**
- Doctor: name, specialty, credentials, clinic location
- Patient name, date of visit
- Prescribed items or instructions (best-effort on handwriting)

**Contracts / Legal Documents:**
- Parties, dates, key terms, obligations
- Monetary amounts, schedules, conditions

### Step 3: Structure the Note

```markdown
# [Procedure/Transaction Name]

**Date**: [date]
**Facility/Issuer**: [name, location]
**Type**: [procedure type, transaction type]
**Key Personnel**: [doctor, officer, etc.]

## Cost Summary

| Component | Gross | Deductions | Net Paid |
|-----------|-------|------------|----------|
| [item] | [amount] | [amount] | [amount] |
| **Total** | **[amount]** | **[amount]** | **[amount]** |

## Itemized Charges

| Item | Qty | Price |
|------|-----|-------|
| [every line item from the scan] | | |

## [Other sections as needed]

## Attachments

![[original attachments preserved]]
```

### Step 4: Verify Completeness

- Cross-check totals: do line items sum to the stated total?
- Flag discrepancies (e.g., receipt amount differs from bill)
- Ensure every attachment was read and extracted

## Key Rules

- **Summary does not replace detail** — always include both
- **Handwritten text**: extract best-effort, mark unclear portions with [unclear] or [Inference]
- **Multiple documents**: extract each separately, then add a cross-document summary if they relate (e.g., hospital bill + receipt = total cost breakdown)
- **Preserve original attachments** at the bottom of the note — the extractions supplement, not replace, the scans
