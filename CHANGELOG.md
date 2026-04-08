# Changelog

## 2026-04-08

- **Restructure**: Flatten all skill directories from `<category>/<name>/` to `<name>/`. Rewrite `check.sh` and `install.sh` to use glob discovery instead of hardcoded category lists. Update `marketplace.json` source paths and README links. Remove firecrawl symlinks from repo root.
- **New**: `repo-flattening` — pattern for collapsing two-level directory structures in git repos
- **New**: `AGENTS.md` — shared project instructions for all coding agents; `CLAUDE.md` now imports via `@AGENTS.md`
- **New**: `CHANGELOG.md`

## 2026-04-07

- **New**: `proxy-measurement-designer` — 5-step proxy design with Goodhart's Law defenses
- **New**: `agent-pipeline-design` — inline vs subagent classification, `claude -p` constraints, state management

## 2026-04-06

- **New**: `adversarial-plan-hardening` — stress-test execution plans; adds necessity audit
- **New**: `broken-not-unnecessary` — distinguish broken from obsolete before deleting code
- **Update**: `vision-fallback-claude-code` — correct CLI syntax, Sonnet cost optimization, nix config troubleshooting
- **Update**: `source-verification` — optimized via five-step

## 2026-04-05

- **New**: `skill-registration-troubleshooting` — diagnose skills silently excluded from index (circular symlink detection)

## 2026-04-04

- **New**: `document-baseline-preservation` — protect originals before editing
- **Update**: `reality-filter` v2.0 — merged reality-filter-verifier into core skill

## 2026-04-03

- **New**: `subagent-driven-development`, `skill-to-prompt-porter`, `technical-pattern-extractor`, `state-reset-verification`, `systems-design-diagnostic`

## 2026-04-02

- **New**: `execution-habits-checker`, `api-deprecation-migration`, `scientist-experimenter`, `rumination-interrupt`, `safe-file-deduplication`, `unconscious-goal-detector`, `morning-evening-heart-setting`, `custom-command-audit`, `durable-strategy-design`, `framework-epistemology-audit`, `skill-pattern-alignment`, `framework-to-daily-workflow-integration`, `five-capabilities-audit`, `first-principles-framework`, `existential-framework-builder`, `pre-learning-prep`, `capture-what-resonates`, `codebase-due-diligence`, `steel-manning-technique`, `disk-space-troubleshooting`, `deployment-readiness`, `cv-customization-workflow`, `git-stash-pull-pop`, `external-tool-skill-installation`, `hermes-profile-skill-awareness`, `static-html-app-development`, `skill-tree-generator`, `source-verification`, `system-purpose-auditor`, `parallel-development-strategy`, `iterative-refinement-workflow`, `action-clarity-loop`, `vspt-planner`, `preparation-procrastination-detector`, `life-reset-protocol`, `looking-good-vs-being-right`, `image-cascading-fallback`, `interest-discovery`, `hidden-logic-analyst`, `decision-quality-framework`, `cutting-identifier`, `knowledge-synthesis-framework`, `cloudflare-r2-bill-estimator`, `cloudflare-pages-static-site`, `allostatic-load-monitor`, `regret-minimization-framework`, `quick-document-summary`
- **Tooling**: Add README link linter to `check.sh`

## 2026-04-01

- **New**: `risk-first-methodology`, `emerging-market-analysis`, `dmn-reset`, `diagnostic-logging-patterns`, `code-review-methodology`, `nix-managed-plugin-workaround`, `vision-fallback-claude-code`, `term-definer`, `seasonal-grief-navigator`, `clean-commit-staging`, `clerk-test`, `capability-building-roadmap`, `bottleneck-identifier`, `backend-contract-format-compliance`, `agency-diagnostic`, `active-reading-to-wisdom`, `action-plan-threat-assessment`, `anti-vision-builder`, `financial-decision-heuristics`, `apple-reminders-cli`, `hermes-profiles-version-control`

## 2026-03-31

- **Restructure**: Reorganize flat skills into category subdirectories (`rails/`, `nix/`, `claude-code/`, etc.)
- **New**: `init-nix-shell`, `skills-audit`, `batch-skill-migration`, `bluebubbles-imessage-setup`, `openclaw-installation`, `nix-darwin-activation-scripts`, `shared-memory-across-machines`, `commit` (and 10 others ported from dotfiles)
- **Tooling**: Add `CLAUDE.md` for repo onboarding
- **Optimize**: Four batch passes reducing total line count ~41%

## 2026-03-25

- **New**: `codebase-explorer`

## 2026-03-23

- **New**: Three skills from PARA project (root-cause-investigation, reaction-gap-practice, and one other)
- **Fix**: Add test gate to `dead-code-detection` after false-positive deletions

## 2026-03-22

- **Update**: Add isolated Node wrapper pattern for npm CLI tools

## 2026-03-18

- **New**: `api-endpoint-metadata-verification` and 17 skills migrated from dotfiles repo
- **New**: `frontend-design`

## 2026-03-17

- **New**: `rails-cache-performance`, `decision-timing-assessor`, `counterintuitive-analyst`, `first-principles-debugger`
- **Optimize**: Six-skill parallel optimization pass; stimulus-controller-integration, all activerecord skills

## 2026-03-16

- **New**: `scanned-document-extraction`, `cyclomatic-complexity-reduction`, `response-diversity`
- **Fix**: `security-patterns` version mismatch

## 2026-03-14

- **New**: `activerecord-application-query-optimization` and 14 skills extracted from dotfiles
- **Optimize**: Bulk trim pass — 13 skills reduced 40–80%

## 2026-03-13

- **New**: Initial commit — 5 skills: `activejob-design-patterns`, `activerecord-query-performance-patterns`, `rails-testing-patterns`, `stimulus-controller-integration`, `security-patterns`
- **Tooling**: `install.sh` (bulk symlinker with stale link cleanup), `check.sh` (spec validation with pre-commit hook), `CONTRIBUTING.md`
