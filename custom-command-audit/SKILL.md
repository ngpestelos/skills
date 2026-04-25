---
name: custom-command-audit
description: Systematic methodology for evaluating custom commands for archival by checking skill coverage, unique value, and active usage. Auto-activates when auditing commands, reviewing command inventory, cleaning up commands, retiring commands, archiving commands. Trigger keywords: audit commands, command inventory, archive command, retire command, command cleanup, review commands, command sprawl, too many commands.
metadata:
  version: 1.0.1
---

## Three-Question Test

For each command, read the full file, then answer:

1. **Is it covered?** Do existing skills, agents, or shell scripts already handle this?
2. **Is it unique?** Does it have a specific personal protocol or conversational structure that can't be reproduced ad hoc?
3. **Is it active?** Is it tied to a current project/need, or is it stale?

**Archive**: covered by 2+ skills, thin wrapper, redirect stub, stale project, simple enough to request ad hoc. Move to `.claude/archives/[name].md.archived` via `mv` + `git add`.
**Keep**: unique personal protocol, core daily workflow, structured review cadence.
