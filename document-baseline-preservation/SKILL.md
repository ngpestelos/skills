---
name: document-baseline-preservation
description: "Prevents destructive overwrites of important documents. Auto-activates when rewriting, replacing, or substantially editing existing files — especially identity documents (CV, profiles), strategic documents, and any file the user may want to compare versions of. Trigger keywords: rewrite, overwrite, replace, redo, new version, update CV, reframe."
metadata:
  version: "1.0.1"
---

# Preserving Document Baselines Before Editing

Before substantially rewriting any existing document, confirm with the user: overwrite or create a dated copy?

## Before Rewriting

1. **Confirm intent**: Ask "overwrite or dated copy?" — "rewrite my CV" means "produce a new version," not "destroy the original"
2. **If modifying in place**: Verify the file is committed to git first
3. **If creating new version**: Use `YYYYMMDD [Document Name].md` naming
4. **Identity/strategic documents**: Default to dated copy unless user explicitly says "overwrite"

