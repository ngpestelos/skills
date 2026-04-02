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
| [activerecord-application-query-optimization](rails/activerecord-application-query-optimization/) | N+1 prevention, batch preloading, SQL CASE consolidation, duplicate join detection, and 8 N+1 discovery patterns |
| [activerecord-query-performance-patterns](rails/activerecord-query-performance-patterns/) | Three techniques preventing 10-1000x PostgreSQL degradation: ILIKE indexing, two-phase DISTINCT, UNION ALL OR-splitting |
| [activerecord-eager-loading-testing-patterns](rails/activerecord-eager-loading-testing-patterns/) | Testing eager loading with `.loaded?` verification and query count assertions |
| [activerecord-graceful-corrupted-data-handling](rails/activerecord-graceful-corrupted-data-handling/) | Safe handling of missing/corrupted foreign key data with `.find_by` and nil guards |
| [activerecord-idempotent-create-patterns](rails/activerecord-idempotent-create-patterns/) | Idempotent endpoints using `find_or_create_by!` to prevent race conditions |
| [activerecord-transaction-boundary-optimization](rails/activerecord-transaction-boundary-optimization/) | Minimize transaction lock time by moving reads outside transaction blocks |
| [database-migration-termination-safety](general/database-migration-termination-safety/) | Safe, recoverable database migration design |

### Rails Controllers & Views

| Skill | Description |
|-------|-------------|
| [controller-input-validation-edge-cases](rails/controller-input-validation-edge-cases/) | Comprehensive input validation before processing to prevent edge case failures |
| [controller-transaction-render-pattern](rails/controller-transaction-render-pattern/) | Prevent double render errors and connection pool pollution in transactions |
| [model-method-memoization-view-performance](general/model-method-memoization-view-performance/) | Memoize model methods to reduce view rendering allocations |
| [rails-cache-performance](rails/rails-cache-performance/) | Cache invalidation, stale cache detection, request-scoped caching, TTL selection, and logging |
| [rails-testing-patterns](rails/rails-testing-patterns/) | Integration-first test selection, factory pitfalls, and assert_select patterns |
| [backend-contract-format-compliance](rails/backend-contract-format-compliance/) | Detect and resolve format mismatches between frontend/backend with save-time normalization and gradual type strengthening |
| [diagnostic-logging-patterns](rails/diagnostic-logging-patterns/) | 3-layer strategic logging (controller → model → DB verification) with P0/P1/P2 priority and temporary debug protocol |
| [image-cascading-fallback](rails/image-cascading-fallback/) | Defensive image rendering with cascading fallback from missing/404 URLs to alternatives and placeholders |

### Stimulus & Frontend

| Skill | Description |
|-------|-------------|
| [stimulus-controller-integration](frontend/stimulus-controller-integration/) | AJAX initialization, CustomEvent communication, and controller reuse patterns |
| [stimulus-form-redirect](frontend/stimulus-form-redirect/) | Replace AJAX + DOM manipulation with form submission + server redirect |
| [multi-panel-formdata-sync](frontend/multi-panel-formdata-sync/) | Fix querySelector('form') first-form bug in multi-panel Stimulus controllers |
| [static-html-app-development](frontend/static-html-app-development/) | Static HTML/CSS/JS patterns — prevents file:// localStorage trap, browser test suite |

### ActiveJob

| Skill | Description |
|-------|-------------|
| [activejob-design-patterns](rails/activejob-design-patterns/) | Transaction safety, error handling, S3 file sharing, and operation-based idempotency |

### Testing & Quality

| Skill | Description |
|-------|-------------|
| [test-plan-methodology](workflow/test-plan-methodology/) | 4-phase test planning to prevent coverage blind spots |
| [security-patterns](security/security-patterns/) | Rails security checklist: XSS, CSRF, PII logging, multi-tenant isolation, and state machine security |
| [adversarial-agent-validation](workflow/adversarial-agent-validation/) | Three-agent adversarial pattern (Finder/Adversary/Referee) for deep review |
| [dead-code-detection](debugging/dead-code-detection/) | Systematic orphaned file and dead code identification |
| [cyclomatic-complexity-reduction](debugging/cyclomatic-complexity-reduction/) | Reduce cyclomatic complexity via early-return extraction, guard unification, and safe access helpers |

### Process & Problem-Solving

| Skill | Description |
|-------|-------------|
| [root-cause-investigation](general/root-cause-investigation/) | Five Whys + Peeling the Onion dual-mode debugging framework |
| [codebase-due-diligence](general/codebase-due-diligence/) | Phased reconnaissance → setup → architecture mapping → risk zone classification for unfamiliar codebases |
| [capture-what-resonates](general/capture-what-resonates/) | Resonance Filter + Twelve Favorite Problems for deciding what to capture in a Second Brain |
| [pre-learning-prep](general/pre-learning-prep/) | 5-15 min pre-reading checklist: search existing knowledge, activate mental models, set intentions, prime connections |
| [five-step-optimizer](workflow/five-step-optimizer/) | Musk's Five-Step Algorithm for process optimization |
| [vspt-planner](workflow/vspt-planner/) | Vision-Strategies-Projects-Tactics framework for breaking down overwhelming objectives |
| [action-clarity-loop](workflow/action-clarity-loop/) | Generate clarity through action — minimum viable actions reveal information planning can't |
| [iterative-refinement-workflow](workflow/iterative-refinement-workflow/) | Execute, measure, refine, repeat — continuous improvement through feedback loops |
| [framework-to-daily-workflow-integration](workflow/framework-to-daily-workflow-integration/) | Embed abstract strategic frameworks into existing daily/weekly commands as lightweight rituals — 4-step pattern with timescale calibration and data flow wiring |
| [parallel-development-strategy](workflow/parallel-development-strategy/) | Build features in parallel — sketch-to-detail with best possible product at every moment |
| [first-principles-debugger](debugging/first-principles-debugger/) | First-principles debugging for complex issues that resist conventional approaches |
| [first-principles-framework](general/first-principles-framework/) | Three-mode first-principles methodology: problem decomposition (with Rails/Stimulus patterns), foundation building (observations-to-laws), and document summarization |
| [decision-timing-assessor](workflow/decision-timing-assessor/) | Framework for optimal decision timing vs. information gathering (Type I/II decisions, reversibility) |
| [counterintuitive-analyst](general/counterintuitive-analyst/) | Systematically question popular wisdom to reveal strategic insights |
| [framework-epistemology-audit](general/framework-epistemology-audit/) | Pressure-test universal frameworks: 3 tests (falsifiability, independence, predictive specificity) + 4-level Pattern Verification Hierarchy to distinguish laws from metaphors |
| [emerging-market-analysis](general/emerging-market-analysis/) | 5 frameworks: governance trauma cycle, CB signaling, FX-inflation feedback, valuation floors, capital rotation |
| [regret-minimization-framework](general/regret-minimization-framework/) | 10-10-10 rule, action vs inaction regret comparison, minimum regret path selection |
| [risk-first-methodology](general/risk-first-methodology/) | Define max loss before reward, IF-THEN scenario planning, position sizing from risk |
| [bottleneck-identifier](general/bottleneck-identifier/) | Theory of Constraints diagnostic: find THE single constraint, exploit, subordinate, elevate |
| [capability-building-roadmap](general/capability-building-roadmap/) | Transform abstract competence goals into concrete, time-calibrated 90-day action plans |
| [durable-strategy-design](general/durable-strategy-design/) | Build disruption-proof personal strategy: commoditization-scarcity inversion, 4-pillar architecture, personality alignment filter, uncorrelated wealth streams, binary execution gates |
| [clerk-test](general/clerk-test/) | Rowan vs clerk diagnostic: are you executing or accumulating questions? |
| [system-purpose-auditor](general/system-purpose-auditor/) | Evaluate systems by what they DO — POSIWID principle for diagnosing intention-reality gaps |
| [skill-tree-generator](general/skill-tree-generator/) | Prerequisite dependency trees — trunk/branch/leaf with ZPD calibration for learning |
| [clean-commit-staging](workflow/clean-commit-staging/) | Prevent pre-staged files from parallel sessions contaminating your commits |
| [code-review-methodology](workflow/code-review-methodology/) | Review only uncommitted changes with 4-tier priority framework |
| [knowledge-synthesis-framework](general/knowledge-synthesis-framework/) | Cross-domain pattern recognition, paradox exploration, and association surfacing for insight generation |
| [safe-file-deduplication](workflow/safe-file-deduplication/) | Multi-phase content-based file deduplication with dry-run, archive safety, and rollback |
| [hidden-logic-analyst](general/hidden-logic-analyst/) | Identify derived variables that determine winning vs losing — hidden advantages competitors miss |

### Decision-Making & Self-Coaching

| Skill | Description |
|-------|-------------|
| [agency-diagnostic](general/agency-diagnostic/) | Three-layer diagnostic for blocked action: blindness detection, low-agency traps, internal obstacle voices |
| [action-plan-threat-assessment](general/action-plan-threat-assessment/) | Stress-test execution plans with weakness-threat interaction matrices and urgency-ordered defensive actions |
| [anti-vision-builder](general/anti-vision-builder/) | Articulate the life you refuse to live — 5-step process producing a single-sentence decision filter |
| [existential-framework-builder](general/existential-framework-builder/) | Transform vague existential distress into structured inquiry frameworks across 7 angles: future, past, counterfactual, relational, existential, synthesis, application |
| [five-capabilities-audit](general/five-capabilities-audit/) | Identify AI-era development priorities across five irreplaceable human capabilities: Computation, Transformation, Variation, Selection, Attention |
| [life-reset-protocol](general/life-reset-protocol/) | 1-day protocol for radical life clarity: morning excavation, autopilot interruption, evening synthesis |
| [preparation-procrastination-detector](general/preparation-procrastination-detector/) | Flags when endless preparation substitutes for action — 20% rule, riskless audit, MVA test |
| [financial-decision-heuristics](general/financial-decision-heuristics/) | ATM Test, risk assessment, asset vs liability, trading up, carrying cost, and lifestyle creep detection |
| [active-reading-to-wisdom](general/active-reading-to-wisdom/) | 2-step reading intention and application cycle — bridge insights to concrete life actions |
| [reaction-gap-practice](general/reaction-gap-practice/) | Name-Pause-Choose protocol for creating space between emotional trigger and behavioral response |
| [allostatic-load-monitor](general/allostatic-load-monitor/) | Track cumulative stress: Type 1 (energy deficit) vs Type 2 (ongoing conflict) with weekly/daily assessment |
| [dmn-reset](general/dmn-reset/) | 5-minute protocol for interrupting racing thoughts: breathwork, anchoring, reframing, gratitude, autosuggestion |
| [execution-habits-checker](general/execution-habits-checker/) | 10-habit self-assessment from "A Message to Garcia" with evidence-based rating and keystone habit identification |
| [rumination-interrupt](general/rumination-interrupt/) | 30-second interventions for breaking rumination: physical interrupt, CIA next-fastest-thing, high agency escape |
| [seasonal-grief-navigator](general/seasonal-grief-navigator/) | Navigate calendar-tied grief: anniversary patterns, navigate vs fix reframing, achievable peace |
| [cutting-identifier](general/cutting-identifier/) | Identify the single decisive action that determines success in any domain (Musashi + Lynch synthesis) |
| [decision-quality-framework](general/decision-quality-framework/) | Five-bias audit, pre-mortem failure analysis, six-dimension quality scoring — judge process, not outcome |
| [interest-discovery](general/interest-discovery/) | Discover genuine interests through behavioral evidence and conversational exploration — play, not obligation |
| [looking-good-vs-being-right](general/looking-good-vs-being-right/) | Surface where social pressure compromises effectiveness — IBM trap check, appearance vs substance matrix |
| [morning-evening-heart-setting](general/morning-evening-heart-setting/) | Guided daily recommitment ritual — Tsunetomo's morning/evening heart-setting with 3 questions, commitment statements, weekly extension |
| [unconscious-goal-detector](general/unconscious-goal-detector/) | Reveal hidden goals behind "lack of discipline" — 5-step framework exposing that repeated failures are successful pursuit of unconscious objectives |
| [scientist-experimenter](general/scientist-experimenter/) | Transform challenges into hypothesis-test-learn experiments — block diagnosis, reframing, impossible goal decomposition |

### Communication & Framing

| Skill | Description |
|-------|-------------|
| [response-diversity](general/response-diversity/) | Vary response framing by context (learner, engineer, family, researcher) |
| [quick-document-summary](general/quick-document-summary/) | Concise verbal summaries without modifying files — lead with insights, not descriptions |
| [term-definer](general/term-definer/) | Context-aware definitions with adaptive complexity: simple, moderate, or full treatment with etymology |

### Writing

| Skill | Description |
|-------|-------------|
| [cv-customization-workflow](writing/cv-customization-workflow/) | Role-specific CV variants and cover letters: skills match scoring, reframing, de-AI voice pass, two-agent quality gate |

### Productivity

| Skill | Description |
|-------|-------------|
| [cloudflare-pages-static-site](general/cloudflare-pages-static-site/) | Deploy static HTML/CSS to Cloudflare Pages with custom domain in under an hour |
| [cloudflare-r2-bill-estimator](general/cloudflare-r2-bill-estimator/) | R2 pricing table with free tier — operations usually free, storage is the only billable component |
| [scanned-document-extraction](general/scanned-document-extraction/) | Extract structured data from scanned images/PDFs into markdown, preserving all granular detail |

### Nix & System Configuration

| Skill | Description |
|-------|-------------|
| [neovim-configuration](general/neovim-configuration/) | Neovim config via home-manager: plugin management, nvim-tree, theme consistency, buffer navigation |
| [nix-darwin-multi-user](nix/nix-darwin-multi-user/) | Multi-user nix-darwin with home-manager: mkDarwinConfig, activation scripts, file conflicts |
| [nix-darwin-zsh-completion](nix/nix-darwin-zsh-completion/) | Fix compinit insecure directories warning: enableGlobalCompInit vs completionInit |
| [nix-github-release-packaging](nix/nix-github-release-packaging/) | Package GitHub release binaries as Nix derivations: fetchurl, SHA256 hash workflow |
| [nix-template-deployment](nix/nix-template-deployment/) | Deploy shell.nix + .envrc for per-directory packages via direnv |
| [disk-space-troubleshooting](nix/disk-space-troubleshooting/) | macOS disk space diagnosis and cleanup: Nix GC first, then caches, with 5-level risk hierarchy |
| [nodejs-version-management](nix/nodejs-version-management/) | Node.js/npm version management in Nix flakes: synchronization, pnpm, native installers |
| [overriding-flake-input-packages](nix/overriding-flake-input-packages/) | Fix external flake input build failures with overrideAttrs |
| [nix-managed-plugin-workaround](nix/nix-managed-plugin-workaround/) | Install Claude Code plugins when settings.json is a nix-managed symlink |

### AI Tool Configuration

| Skill | Description |
|-------|-------------|
| [ai-coding-tool-portability](claude-code/ai-coding-tool-portability/) | Portable configuration across Claude Code and OpenCode: feature mapping, command mirroring |
| [portable-ai-cli-patterns](claude-code/portable-ai-cli-patterns/) | Dual-tool Claude Code + OpenCode config: compatibility matrix, single-source commands |
| [configuring-dynamic-attribution](claude-code/configuring-dynamic-attribution/) | Dynamic placeholders for model names in commit co-author attributions |

### Claude Code & Tooling

| Skill | Description |
|-------|-------------|
| [hook-state-cascade-patterns](claude-code/hook-state-cascade-patterns/) | Stateful hook patterns: cascade routing, cooldowns, state fallback, portable date parsing, and live file verification |
| [skill-decomposition-methodology](claude-code/skill-decomposition-methodology/) | Refactor bloated skills (>500 lines) into focused sub-skills |
| [claude-code-hook-development](claude-code/claude-code-hook-development/) | Create and deploy Claude Code hooks: JSON input, exit codes, transcript JSONL parsing |
| [skill-stack-deduplication](claude-code/skill-stack-deduplication/) | Eliminate duplication across agent/skill/command layers via reference hierarchies |
| [custom-command-audit](claude-code/custom-command-audit/) | 3-question test to evaluate custom commands for archival: covered by skills? unique protocol? actively used? |
| [reality-filter](general/reality-filter/) | Uncertainty labeling and verification standards: evidence hierarchy, self-correction |
| [red-team-framework-review](general/red-team-framework-review/) | Adversarial review of strategic frameworks: assumption challenges, correlated failure modes |
| [changing-defaults-systematically](workflow/changing-defaults-systematically/) | Zero-regression constant/default changes: find all references, update atomically |
| [git-atomic-commit-organizer](workflow/git-atomic-commit-organizer/) | Organize uncommitted changes into logical, atomic commits |
| [source-verification](workflow/source-verification/) | Verify cited sources before publication — prevent WebFetch circular verification |
| [git-stash-pull-pop](workflow/git-stash-pull-pop/) | Update from remote when pull is blocked by unstaged changes: stash, pull, pop |
| [deployment-readiness](workflow/deployment-readiness/) | 5-phase production deployment checklist: verify, commit, PR, deploy, monitor |
| [qmd-local-search](general/qmd-local-search/) | QMD semantic search patterns: MCP tools, index rebuild, troubleshooting |
| [vision-fallback-claude-code](claude-code/vision-fallback-claude-code/) | Fallback when vision analysis fails: CLI delegation and browser accessibility tree extraction |

### Third-Party

| Skill | Description | Origin |
|-------|-------------|--------|
| [frontend-design](frontend/frontend-design/) | Create distinctive, production-grade frontend interfaces with high design quality | [Anthropic](https://github.com/anthropics/claude-plugins-official) |

## Compatibility

These skills follow the [Agent Skills specification](https://agentskills.io/specification) and work with any compatible agent:
Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, Goose, and others.

## Author

[Nestor Pestelos](https://ngpestelos.com) — freelance product developer, Manila.

## License

MIT
