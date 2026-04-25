---
name: optimizer-agent-biases
description: Recurring optimizer-agent failure modes that require explicit prompt guards
type: feedback
originSessionId: 52a48115-a243-4f1c-adfe-67135741a789
---
Subagents running the five-step optimizer on SKILL.md files have these consistent biases. The agent prompt MUST guard against each, or the eval (Tier 0/Tier 1) will catch it as a regression.

**Why:** Observed across 17 batches in the 2026-04-25 Phase B sweep. Each bias produced at least one revert or manual fix. Encoding the guards in the optimizer prompt cut later batches' fix rate.

**How to apply:** When prompting an optimizer subagent, include explicit "NEVER do this" rules:

1. **Don't strip `allowed-tools:`.** The five-step-optimizer skill calls these "artificial restrictions," but in this repo they are intentional user-set scoping. Verbatim-preserve.
2. **Don't collapse similar fenced code blocks** even if they look near-duplicate (e.g., `# config/environments/development.rb` and `# config/environments/test.rb` — file-path comments inside code blocks are load-bearing).
3. **Don't compress structured tables to prose** when rows have distinct named pairs ("Old | New", "Symptom | Fix") — at least one row will be lost. If a table has N rows, the prose summary will preserve N-1.
4. **Don't drop numbered principles/rules** without verifying each is fully covered elsewhere. Common false-positive: agent classifies a list of behavioral guidelines as "restated by steps" when only the first one is.
5. **Don't pick one when frontmatter has duplicate `description:` keys.** MERGE both, preserving all keywords from each.
6. **Don't delete non-standard `triggers:` / `trigger:` frontmatter blocks** without folding their keywords into `description:` first. Trigger keywords drive auto-activation.
7. **Don't classify "When to Use" / "Activation Triggers" sections as keyword duplicates** if they contain concrete scenarios or applicability criteria (vs literal keyword copies).
8. **Decorative quotes, "Optimization History" / "Discovery Context" dated meta-doc, `## Instructions` wrapper headers, and H1 + 1-line intros that exactly restate the description ARE safe to cut** — these are the categories the optimizer reliably gets right.
