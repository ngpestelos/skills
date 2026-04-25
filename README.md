# ngpestelos/skills

Production-tested [Agent Skills](https://agentskills.io) for software engineering, debugging, and process optimization.

## Installation

### All skills (symlink)

```bash
git clone git@github.com:ngpestelos/skills.git ~/src/skills
cd ~/src/skills && ./install.sh
```

This symlinks every skill into `~/.claude/skills/` so they stay in sync with `git pull`.

### Individual skills (plugin)

```bash
# Add marketplace (one-time)
/plugin marketplace add ngpestelos/skills

# Install individual skills
/plugin install root-cause-investigation@ngpestelos-skills
/plugin install five-step-optimizer@ngpestelos-skills
/plugin install security-patterns@ngpestelos-skills
/plugin install activerecord-application-query-optimization@ngpestelos-skills
/plugin install adversarial-agent-validation@ngpestelos-skills
/plugin install activejob-design-patterns@ngpestelos-skills
```

## Available Skills

### ActiveRecord & Database

| Skill | Description |
|-------|-------------|
| [activerecord-application-query-optimization](./activerecord-application-query-optimization/) | N+1 prevention, batch preloading, SQL CASE consolidation, duplicate join detection, and 8 N+1 discovery patterns |
| [activerecord-query-performance-patterns](./activerecord-query-performance-patterns/) | Three techniques preventing 10-1000x PostgreSQL degradation: ILIKE indexing, two-phase DISTINCT, UNION ALL OR-splitting |
| [activerecord-eager-loading-testing-patterns](./activerecord-eager-loading-testing-patterns/) | Testing eager loading with `.loaded?` verification and query count assertions |
| [activerecord-graceful-corrupted-data-handling](./activerecord-graceful-corrupted-data-handling/) | Safe handling of missing/corrupted foreign key data with `.find_by` and nil guards |
| [activerecord-idempotent-create-patterns](./activerecord-idempotent-create-patterns/) | Idempotent endpoints using `find_or_create_by!` to prevent race conditions |
| [activerecord-transaction-boundary-optimization](./activerecord-transaction-boundary-optimization/) | Minimize transaction lock time by moving reads outside transaction blocks |
| [database-migration-termination-safety](./database-migration-termination-safety/) | Safe, recoverable database migration design |

### Rails Controllers & Views

| Skill | Description |
|-------|-------------|
| [controller-input-validation-edge-cases](./controller-input-validation-edge-cases/) | Comprehensive input validation before processing to prevent edge case failures |
| [controller-transaction-render-pattern](./controller-transaction-render-pattern/) | Prevent double render errors and connection pool pollution in transactions |
| [model-method-memoization-view-performance](./model-method-memoization-view-performance/) | Memoize model methods to reduce view rendering allocations |
| [rails-cache-performance](./rails-cache-performance/) | Cache invalidation, stale cache detection, request-scoped caching, TTL selection, and logging |
| [rails-testing-patterns](./rails-testing-patterns/) | Integration-first test selection, factory pitfalls, and assert_select patterns |
| [technical-pattern-extractor](./technical-pattern-extractor/) | Extract and generalize project-specific Rails patterns into reusable skills and knowledge notes |
| [backend-contract-format-compliance](./backend-contract-format-compliance/) | Detect and resolve format mismatches between frontend/backend with save-time normalization and gradual type strengthening |
| [diagnostic-logging-patterns](./diagnostic-logging-patterns/) | 3-layer strategic logging (controller → model → DB verification) with P0/P1/P2 priority and temporary debug protocol |
| [image-cascading-fallback](./image-cascading-fallback/) | Defensive image rendering with cascading fallback from missing/404 URLs to alternatives and placeholders |

### Stimulus & Frontend

| Skill | Description |
|-------|-------------|
| [stimulus-controller-integration](./stimulus-controller-integration/) | AJAX initialization, CustomEvent communication, and controller reuse patterns |
| [stimulus-form-redirect](./stimulus-form-redirect/) | Replace AJAX + DOM manipulation with form submission + server redirect |
| [multi-panel-formdata-sync](./multi-panel-formdata-sync/) | Fix querySelector('form') first-form bug in multi-panel Stimulus controllers |
| [static-html-app-development](./static-html-app-development/) | Static HTML/CSS/JS patterns — prevents file:// localStorage trap, browser test suite |
| [browser-resource-hints-optimization](./browser-resource-hints-optimization/) | Use preconnect, dns-prefetch, preload, prefetch to optimize page load for CDNs and external resources |

### ActiveJob

| Skill | Description |
|-------|-------------|
| [activejob-design-patterns](./activejob-design-patterns/) | Transaction safety, error handling, S3 file sharing, and operation-based idempotency |

### Testing & Quality

| Skill | Description |
|-------|-------------|
| [test-plan-methodology](./test-plan-methodology/) | 4-phase test planning to prevent coverage blind spots |
| [security-patterns](./security-patterns/) | Rails security checklist: XSS, CSRF, PII logging, multi-tenant isolation, and state machine security |
| [adversarial-agent-validation](./adversarial-agent-validation/) | Three-agent adversarial pattern (Finder/Adversary/Referee) for deep review |
| [dead-code-detection](./dead-code-detection/) | Systematic orphaned file and dead code identification |
| [cyclomatic-complexity-reduction](./cyclomatic-complexity-reduction/) | Reduce cyclomatic complexity via early-return extraction, guard unification, and safe access helpers |
| [background-agent-verification](./background-agent-verification/) | Verify output from delegated background agents before proceeding — prevents silent work loss from rate limits or zero-output failures |
| [broken-not-unnecessary](./broken-not-unnecessary/) | Before deleting a feature that "rarely works," verify WHY — failure mode often reveals a fixable bug rather than a real removal requirement |
| [parallel-git-contention](./parallel-git-contention/) | Prevent silent incomplete staging when parallel agents run concurrent git operations (rm/add/mv) against a shared index |

### Process & Problem-Solving

| Skill | Description |
|-------|-------------|
| [root-cause-investigation](./root-cause-investigation/) | Five Whys + Peeling the Onion dual-mode debugging framework |
| [codebase-due-diligence](./codebase-due-diligence/) | Phased reconnaissance → setup → architecture mapping → risk zone classification for unfamiliar codebases |
| [capture-what-resonates](./capture-what-resonates/) | Resonance Filter + Twelve Favorite Problems for deciding what to capture in a Second Brain |
| [pre-learning-prep](./pre-learning-prep/) | 5-15 min pre-reading checklist: search existing knowledge, activate mental models, set intentions, prime connections |
| [five-step-optimizer](./five-step-optimizer/) | Musk's Five-Step Algorithm for process optimization |
| [vspt-planner](./vspt-planner/) | Vision-Strategies-Projects-Tactics framework for breaking down overwhelming objectives |
| [action-clarity-loop](./action-clarity-loop/) | Generate clarity through action — minimum viable actions reveal information planning can't |
| [iterative-refinement-workflow](./iterative-refinement-workflow/) | Execute, measure, refine, repeat — continuous improvement through feedback loops |
| [framework-to-daily-workflow-integration](./framework-to-daily-workflow-integration/) | Embed abstract strategic frameworks into existing daily/weekly commands as lightweight rituals — 4-step pattern with timescale calibration and data flow wiring |
| [parallel-development-strategy](./parallel-development-strategy/) | Build features in parallel — sketch-to-detail with best possible product at every moment |
| [first-principles-debugger](./first-principles-debugger/) | First-principles debugging for complex issues that resist conventional approaches |
| [first-principles-framework](./first-principles-framework/) | Three-mode first-principles methodology: problem decomposition (with Rails/Stimulus patterns), foundation building (observations-to-laws), and document summarization |
| [decision-timing-assessor](./decision-timing-assessor/) | Framework for optimal decision timing vs. information gathering (Type I/II decisions, reversibility) |
| [counterintuitive-analyst](./counterintuitive-analyst/) | Systematically question popular wisdom to reveal strategic insights |
| [framework-epistemology-audit](./framework-epistemology-audit/) | Pressure-test universal frameworks: 3 tests (falsifiability, independence, predictive specificity) + 4-level Pattern Verification Hierarchy to distinguish laws from metaphors |
| [emerging-market-analysis](./emerging-market-analysis/) | 5 frameworks: governance trauma cycle, CB signaling, FX-inflation feedback, valuation floors, capital rotation |
| [regret-minimization-framework](./regret-minimization-framework/) | 10-10-10 rule, action vs inaction regret comparison, minimum regret path selection |
| [risk-first-methodology](./risk-first-methodology/) | Define max loss before reward, IF-THEN scenario planning, position sizing from risk |
| [bottleneck-identifier](./bottleneck-identifier/) | Theory of Constraints diagnostic: find THE single constraint, exploit, subordinate, elevate |
| [capability-building-roadmap](./capability-building-roadmap/) | Transform abstract competence goals into concrete, time-calibrated 90-day action plans |
| [durable-strategy-design](./durable-strategy-design/) | Build disruption-proof personal strategy: commoditization-scarcity inversion, 4-pillar architecture, personality alignment filter, uncorrelated wealth streams, binary execution gates |
| [clerk-test](./clerk-test/) | Rowan vs clerk diagnostic: are you executing or accumulating questions? |
| [system-purpose-auditor](./system-purpose-auditor/) | Evaluate systems by what they DO — POSIWID principle for diagnosing intention-reality gaps |
| [systems-design-diagnostic](./systems-design-diagnostic/) | Four failure archetypes for projects/products/orgs: hidden control, bootstrap paradox, second-system effect, innovator's dilemma |
| [skill-tree-generator](./skill-tree-generator/) | Prerequisite dependency trees — trunk/branch/leaf with ZPD calibration for learning |
| [clean-commit-staging](./clean-commit-staging/) | Prevent pre-staged files from parallel sessions contaminating your commits |
| [code-review-methodology](./code-review-methodology/) | Review only uncommitted changes with 4-tier priority framework |
| [knowledge-synthesis-framework](./knowledge-synthesis-framework/) | Cross-domain pattern recognition, paradox exploration, and association surfacing for insight generation |
| [safe-file-deduplication](./safe-file-deduplication/) | Multi-phase content-based file deduplication with dry-run, archive safety, and rollback |
| [hidden-logic-analyst](./hidden-logic-analyst/) | Identify derived variables that determine winning vs losing — hidden advantages competitors miss |
| [document-baseline-preservation](./document-baseline-preservation/) | Prevents destructive overwrites of important documents — confirm overwrite vs dated copy before rewriting |
| [proxy-measurement-designer](./proxy-measurement-designer/) | Design observable proxies for invisible phenomena using thermal equilibrium, calibration, and Goodhart's Law defenses |

### Decision-Making & Self-Coaching

| Skill | Description |
|-------|-------------|
| [agency-diagnostic](./agency-diagnostic/) | Three-layer diagnostic for blocked action: blindness detection, low-agency traps, internal obstacle voices |
| [action-plan-threat-assessment](./action-plan-threat-assessment/) | Stress-test execution plans with weakness-threat interaction matrices and urgency-ordered defensive actions |
| [anti-vision-builder](./anti-vision-builder/) | Articulate the life you refuse to live — 5-step process producing a single-sentence decision filter |
| [existential-framework-builder](./existential-framework-builder/) | Transform vague existential distress into structured inquiry frameworks across 7 angles: future, past, counterfactual, relational, existential, synthesis, application |
| [five-capabilities-audit](./five-capabilities-audit/) | Identify AI-era development priorities across five irreplaceable human capabilities: Computation, Transformation, Variation, Selection, Attention |
| [life-reset-protocol](./life-reset-protocol/) | 1-day protocol for radical life clarity: morning excavation, autopilot interruption, evening synthesis |
| [preparation-procrastination-detector](./preparation-procrastination-detector/) | Flags when endless preparation substitutes for action — 20% rule, riskless audit, MVA test |
| [financial-decision-heuristics](./financial-decision-heuristics/) | ATM Test, risk assessment, asset vs liability, trading up, carrying cost, and lifestyle creep detection |
| [active-reading-to-wisdom](./active-reading-to-wisdom/) | 2-step reading intention and application cycle — bridge insights to concrete life actions |
| [reaction-gap-practice](./reaction-gap-practice/) | Name-Pause-Choose protocol for creating space between emotional trigger and behavioral response |
| [allostatic-load-monitor](./allostatic-load-monitor/) | Track cumulative stress: Type 1 (energy deficit) vs Type 2 (ongoing conflict) with weekly/daily assessment |
| [dmn-reset](./dmn-reset/) | 5-minute protocol for interrupting racing thoughts: breathwork, anchoring, reframing, gratitude, autosuggestion |
| [execution-habits-checker](./execution-habits-checker/) | 10-habit self-assessment from "A Message to Garcia" with evidence-based rating and keystone habit identification |
| [rumination-interrupt](./rumination-interrupt/) | 30-second interventions for breaking rumination: physical interrupt, CIA next-fastest-thing, high agency escape |
| [seasonal-grief-navigator](./seasonal-grief-navigator/) | Navigate calendar-tied grief: anniversary patterns, navigate vs fix reframing, achievable peace |
| [cutting-identifier](./cutting-identifier/) | Identify the single decisive action that determines success in any domain (Musashi + Lynch synthesis) |
| [decision-quality-framework](./decision-quality-framework/) | Five-bias audit, pre-mortem failure analysis, six-dimension quality scoring — judge process, not outcome |
| [interest-discovery](./interest-discovery/) | Discover genuine interests through behavioral evidence and conversational exploration — play, not obligation |
| [looking-good-vs-being-right](./looking-good-vs-being-right/) | Surface where social pressure compromises effectiveness — IBM trap check, appearance vs substance matrix |
| [morning-evening-heart-setting](./morning-evening-heart-setting/) | Guided daily recommitment ritual — Tsunetomo's morning/evening heart-setting with 3 questions, commitment statements, weekly extension |
| [unconscious-goal-detector](./unconscious-goal-detector/) | Reveal hidden goals behind "lack of discipline" — 5-step framework exposing that repeated failures are successful pursuit of unconscious objectives |
| [scientist-experimenter](./scientist-experimenter/) | Transform challenges into hypothesis-test-learn experiments — block diagnosis, reframing, impossible goal decomposition |

### Communication & Framing

| Skill | Description |
|-------|-------------|
| [response-diversity](./response-diversity/) | Vary response framing by context (learner, engineer, family, researcher) |
| [quick-document-summary](./quick-document-summary/) | Concise verbal summaries without modifying files — lead with insights, not descriptions |
| [term-definer](./term-definer/) | Context-aware definitions with adaptive complexity: simple, moderate, or full treatment with etymology |
| [steel-manning-technique](./steel-manning-technique/) | Present the strongest version of opposing arguments before engaging — manual protocol and LLM-assisted variant |

### Writing

| Skill | Description |
|-------|-------------|
| [cv-customization-workflow](./cv-customization-workflow/) | Role-specific CV variants and cover letters: skills match scoring, reframing, de-AI voice pass, two-agent quality gate |

### Productivity

| Skill | Description |
|-------|-------------|
| [cloudflare-pages-static-site](./cloudflare-pages-static-site/) | Deploy static HTML/CSS to Cloudflare Pages with custom domain in under an hour |
| [cloudflare-r2-bill-estimator](./cloudflare-r2-bill-estimator/) | R2 pricing table with free tier — operations usually free, storage is the only billable component |
| [scanned-document-extraction](./scanned-document-extraction/) | Extract structured data from scanned images/PDFs into markdown, preserving all granular detail |
| [apple-reminders-cli](./apple-reminders-cli/) | Manage Apple Reminders from the terminal via `remindctl` — setup, common operations, troubleshooting |
| [crypto-price-scraping](./crypto-price-scraping/) | Scrape live cryptocurrency prices and market data from CoinMarketCap via firecrawl |
| [philippine-cinema-search](./philippine-cinema-search/) | Find Philippine movie release dates and cinema info via ClickTheCity — bypasses Google CAPTCHA |
| [openclaw-installation](./openclaw-installation/) | Install OpenClaw from source on Nix-managed macOS — pnpm prerequisites, build, onboarding, daemon setup |
| [bluebubbles-imessage-setup](./bluebubbles-imessage-setup/) | BlueBubbles server setup for iMessage integration with OpenClaw — permissions, Private API, channel wiring |

### Nix & System Configuration

| Skill | Description |
|-------|-------------|
| [neovim-configuration](./neovim-configuration/) | Neovim config via home-manager: plugin management, nvim-tree, theme consistency, buffer navigation |
| [nix-darwin-multi-user](./nix-darwin-multi-user/) | Multi-user nix-darwin with home-manager: mkDarwinConfig, activation scripts, file conflicts |
| [nix-darwin-zsh-completion](./nix-darwin-zsh-completion/) | Fix compinit insecure directories warning: enableGlobalCompInit vs completionInit |
| [nix-github-release-packaging](./nix-github-release-packaging/) | Package GitHub release binaries as Nix derivations: fetchurl, SHA256 hash workflow |
| [nix-template-deployment](./nix-template-deployment/) | Deploy shell.nix + .envrc for per-directory packages via direnv |
| [disk-space-troubleshooting](./disk-space-troubleshooting/) | macOS disk space diagnosis and cleanup: Nix GC first, then caches, with 5-level risk hierarchy |
| [nodejs-version-management](./nodejs-version-management/) | Node.js/npm version management in Nix flakes: synchronization, pnpm, native installers |
| [overriding-flake-input-packages](./overriding-flake-input-packages/) | Fix external flake input build failures with overrideAttrs |
| [nix-managed-plugin-workaround](./nix-managed-plugin-workaround/) | Install Claude Code plugins when settings.json is a nix-managed symlink |
| [init-nix-shell](./init-nix-shell/) | Initialize a nix-shell environment in a project directory — shell.nix template and direnv wiring |
| [nix-darwin-activation-scripts](./nix-darwin-activation-scripts/) | Reliable nix-darwin activation scripts — ownership guards, user-scoped execution, error surfacing, Nix escaping |

### AI Tool Configuration

| Skill | Description |
|-------|-------------|
| [ai-coding-tool-portability](./ai-coding-tool-portability/) | Portable configuration across Claude Code and OpenCode: feature mapping, command mirroring |
| [portable-ai-cli-patterns](./portable-ai-cli-patterns/) | Dual-tool Claude Code + OpenCode config: compatibility matrix, single-source commands |
| [configuring-dynamic-attribution](./configuring-dynamic-attribution/) | Dynamic placeholders for model names in commit co-author attributions |

### Claude Code & Tooling

| Skill | Description |
|-------|-------------|
| [hook-state-cascade-patterns](./hook-state-cascade-patterns/) | Stateful hook patterns: cascade routing, cooldowns, state fallback, portable date parsing, and live file verification |
| [skill-decomposition-methodology](./skill-decomposition-methodology/) | Refactor bloated skills (>500 lines) into focused sub-skills |
| [claude-code-hook-development](./claude-code-hook-development/) | Create and deploy Claude Code hooks: JSON input, exit codes, transcript JSONL parsing |
| [skill-stack-deduplication](./skill-stack-deduplication/) | Eliminate duplication across agent/skill/command layers via reference hierarchies |
| [skill-to-prompt-porter](./skill-to-prompt-porter/) | Port skills into standalone prompts for external LLMs: methodology extraction, infrastructure stripping, modality adaptation |
| [custom-command-audit](./custom-command-audit/) | 3-question test to evaluate custom commands for archival: covered by skills? unique protocol? actively used? |
| [reality-filter](./reality-filter/) | Uncertainty labeling, evidence hierarchy, agent output verification, and self-correction |
| [red-team-framework-review](./red-team-framework-review/) | Adversarial review of strategic frameworks: assumption challenges, correlated failure modes |
| [repo-flattening](./repo-flattening/) | Flatten a two-level category/name directory structure to flat name/ in a git repo, with collision detection, script updates, and symlink restoration |
| [changing-defaults-systematically](./changing-defaults-systematically/) | Zero-regression constant/default changes: find all references, update atomically |
| [git-atomic-commit-organizer](./git-atomic-commit-organizer/) | Organize uncommitted changes into logical, atomic commits |
| [source-verification](./source-verification/) | Verify cited sources before publication — prevent WebFetch circular verification |
| [state-reset-verification](./state-reset-verification/) | Safe deduplication verification: backup-reset-test-restore workflow for state-independent sync systems |
| [subagent-driven-development](./subagent-driven-development/) | Execute implementation plans via fresh subagents per task with two-stage review (spec compliance then code quality) |
| [git-stash-pull-pop](./git-stash-pull-pop/) | Update from remote when pull is blocked by unstaged changes: stash, pull, pop |
| [deployment-readiness](./deployment-readiness/) | 5-phase production deployment checklist: verify, commit, PR, deploy, monitor |
| [qmd-local-search](./qmd-local-search/) | QMD semantic search patterns: MCP tools, index rebuild, troubleshooting |
| [vision-fallback-claude-code](./vision-fallback-claude-code/) | Fallback when vision analysis fails: CLI delegation and browser accessibility tree extraction |
| [agent-pipeline-design](./agent-pipeline-design/) | Multi-phase agent pipeline patterns: inline vs subagent classification, claude -p delegation, state management, skill-to-skill invocation |
| [adversarial-plan-hardening](./adversarial-plan-hardening/) | Iterative adversarial review loop for plans — run passes, resolve BLOCKERs, fold WARNINGs, audit necessity, prepare handoff |
| [eval-gated-bulk-edits](./eval-gated-bulk-edits/) | Run bulk LLM-driven content edits with mechanical + LLM-judge gating, canary regression injection, and pilot-then-scale phasing |
| [api-deprecation-migration](./api-deprecation-migration/) | Migrate a skill to a new API provider when the current service is deprecated or sunsetted |
| [api-endpoint-metadata-verification](./api-endpoint-metadata-verification/) | Debug missing metadata in API integrations — endpoint comparison, response structure verification, data enrichment |
| [capture-skill](./capture-skill/) | Extract patterns from the current session into a reusable skill file |
| [claude-audit](./claude-audit/) | Audit CLAUDE.md files for redundancy, verbosity, stale references, and conflicting rules |
| [codebase-explorer](./codebase-explorer/) | Interactive Q&A exploration of onboarded codebases — architecture walkthroughs and pattern extraction across sessions |
| [commands-audit](./commands-audit/) | Audit custom commands for structural completeness across global and project scopes |
| [commit](./commit/) | Organize uncommitted changes into atomic git commits with scope awareness and out-of-scope confirmation |
| [external-tool-skill-installation](./external-tool-skill-installation/) | Install external tool skills (e.g. Firecrawl) that expose AI-compatible `skills add` interfaces |
| [hermes-profile-credential-resolution](./hermes-profile-credential-resolution/) | Resolve credential location mismatches when Hermes profiles use profile-specific .env files |
| [hermes-profile-skill-awareness](./hermes-profile-skill-awareness/) | Make a Hermes profile aware of a project-local skill — updates profile SOUL.md with docs and invocation patterns |
| [hermes-profiles-version-control](./hermes-profiles-version-control/) | Manage Hermes profiles in git — move profiles to version control with symlinks |
| [learn](./learn/) | Extract learnings from the current session and persist them as new skills, memory entries, or workflow improvements |
| [onboard](./onboard/) | Initialize a project with CLAUDE.md, install dependencies, and produce an orientation summary |
| [parallel-skills-audit](./parallel-skills-audit/) | Triage all skills then spawn parallel agents to deep-audit flagged ones |
| [recall](./recall/) | Restore project memory context by summarizing recent MEMORY.md changes within a configurable time window |
| [recap](./recap/) | Summarize recent git commits for context restoration — grouped by directory or theme with resume points |
| [reflect](./reflect/) | Summarize the current session to answer "where were we?" after interruptions — progress, decisions, open questions |
| [research](./research/) | Systematic first-principles web research producing layered knowledge documents with citations |
| [session](./session/) | Structured dump of the current session — files read/written, searches, tools invoked, agents spawned, open items |
| [shared-memory-across-machines](./shared-memory-across-machines/) | Store Claude Code memory in project repos with symlinks for cross-machine sync |
| [skill-automation-readiness](./skill-automation-readiness/) | Prepare skills and scripts for background/cron automation — quiet modes, random selection, idempotency, exit codes |
| [skill-pattern-alignment](./skill-pattern-alignment/) | Refactor a skill to match an existing reference skill's structure, conventions, and patterns |
| [skill-registration-troubleshooting](./skill-registration-troubleshooting/) | Diagnose why a Hermes skill isn't appearing in the skill index despite a valid SKILL.md |
| [skills-audit](./skills-audit/) | Inventory and audit skills for spec compliance — triage (scan all) and deep audit (single skill) modes |
| [update-memory](./update-memory/) | Persist session learnings to memory files |

### Third-Party

| Skill | Description | Origin |
|-------|-------------|--------|
| [frontend-design](./frontend-design/) | Create distinctive, production-grade frontend interfaces with high design quality | [Anthropic](https://github.com/anthropics/claude-plugins-official) |

## Compatibility

These skills follow the [Agent Skills specification](https://agentskills.io/specification) and work with any compatible agent:
Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, Goose, and others.

## Author

[Nestor Pestelos](https://ngpestelos.com) — freelance product developer, Manila.

## License

MIT
