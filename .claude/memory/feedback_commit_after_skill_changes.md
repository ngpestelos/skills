---
name: commit-after-skill-changes
description: Always commit and push after completing skill edits in the skills repo, without waiting to be asked
type: feedback
originSessionId: 6224c27a-ed67-465b-a2d8-2f2c50056366
---
After completing any skill edit (optimization, bug fix, new content) in ~/src/skills, always commit and push as the final step — do not stop at validation.

**Why:** Committing is the natural end of the workflow. Stopping at `check.sh` passing leaves the work incomplete and requires a follow-up prompt from the user.

**How to apply:** Any time SKILL.md or marketplace.json is modified in ~/src/skills, run the commit skill immediately after `check.sh` passes, without waiting for an explicit "commit" instruction.
