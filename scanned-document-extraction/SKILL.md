---
name: scanned-document-extraction
description: Extract structured data from scanned documents (images, PDFs) into markdown notes, preserving all granular detail. Auto-activates when reading scanned receipts, bills, medical records, statements, or any image/PDF containing tabular or itemized data. Trigger keywords: extract, scan, receipt, bill, statement, itemized, hospital bill, statement of account.
license: MIT
metadata:
  author: ngpestelos
  version: "1.2.1"
---

# Scanned Document Extraction

Every line item, quantity, unit price, date, and reference number visible in the scan must appear in the output. Compressing into summaries defeats the purpose — make the data queryable.

## OCR Method (How to Extract)

**For images/receipts:** The `vision_analyze` tool times out on OCR tasks. Use Claude Code via subagent delegation instead:

```
delegate_task:
  goal: "Extract all transaction details from the receipt image using Claude Code vision"
  context: "Image path: /path/to/receipt.png. Run: claude -p 'Extract all details' <image_path> --dangerously-skip-permissions"
```

The `--dangerously-skip-permissions` flag auto-approves file access and enables reliable OCR extraction.

**For PDFs:** Use `pdftotext` or `pdf2txt.py` if available; otherwise delegate to Claude Code.

## Workflow

### Step 1: Extract Per Document

Locate all `![[embedded]]` files referenced in the note. Read every image and PDF — do not skip any attachment.

**For images:** Use the OCR method above (Claude Code delegation). **For PDFs:** Use `pdftotext` or `pdf2txt.py` if available; otherwise delegate to Claude Code.

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
