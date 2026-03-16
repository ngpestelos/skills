---
name: scanned-document-extraction
description: Extract structured data from scanned documents (images, PDFs) into markdown notes, preserving all granular detail. Auto-activates when reading scanned receipts, bills, medical records, statements, or any image/PDF containing tabular or itemized data. Trigger keywords: extract, scan, receipt, bill, statement, itemized, hospital bill, statement of account.
license: MIT
metadata:
  author: ngpestelos
  version: "1.1.0"
---

# Scanned Document Extraction

Extract all structured data from scanned images and PDFs into searchable, readable markdown. The purpose of extraction is to make scanned data queryable — compressing it into summaries defeats that purpose. Every line item, quantity, unit price, date, and reference number visible in the scan must appear in the output.

## Workflow

### Step 1: Extract Per Document

Locate all `![[embedded]]` files referenced in the note. Read every image and PDF — do not skip any attachment.

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
- Prescribed items or instructions (best-effort on handwriting — mark unclear portions with [unclear] or [Inference])

### Step 2: Structure the Note

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

## Attachments

![[original attachments preserved]]
```
