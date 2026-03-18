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
| [activerecord-application-query-optimization](skills/activerecord-application-query-optimization/) | N+1 prevention, batch preloading, SQL CASE consolidation, duplicate join detection, and 8 N+1 discovery patterns |
| [activerecord-query-performance-patterns](skills/activerecord-query-performance-patterns/) | Three techniques preventing 10-1000x PostgreSQL degradation: ILIKE indexing, two-phase DISTINCT, UNION ALL OR-splitting |
| [activerecord-eager-loading-testing-patterns](skills/activerecord-eager-loading-testing-patterns/) | Testing eager loading with `.loaded?` verification and query count assertions |
| [activerecord-graceful-corrupted-data-handling](skills/activerecord-graceful-corrupted-data-handling/) | Safe handling of missing/corrupted foreign key data with `.find_by` and nil guards |
| [activerecord-idempotent-create-patterns](skills/activerecord-idempotent-create-patterns/) | Idempotent endpoints using `find_or_create_by!` to prevent race conditions |
| [activerecord-transaction-boundary-optimization](skills/activerecord-transaction-boundary-optimization/) | Minimize transaction lock time by moving reads outside transaction blocks |
| [database-migration-termination-safety](skills/database-migration-termination-safety/) | Safe, recoverable database migration design |

### Rails Controllers & Views

| Skill | Description |
|-------|-------------|
| [controller-input-validation-edge-cases](skills/controller-input-validation-edge-cases/) | Comprehensive input validation before processing to prevent edge case failures |
| [controller-transaction-render-pattern](skills/controller-transaction-render-pattern/) | Prevent double render errors and connection pool pollution in transactions |
| [model-method-memoization-view-performance](skills/model-method-memoization-view-performance/) | Memoize model methods to reduce view rendering allocations |
| [rails-cache-performance](skills/rails-cache-performance/) | Cache invalidation, stale cache detection, request-scoped caching, TTL selection, and logging |
| [rails-testing-patterns](skills/rails-testing-patterns/) | Integration-first test selection, factory pitfalls, and assert_select patterns |

### Stimulus & Frontend

| Skill | Description |
|-------|-------------|
| [stimulus-controller-integration](skills/stimulus-controller-integration/) | AJAX initialization, CustomEvent communication, and controller reuse patterns |
| [stimulus-form-redirect](skills/stimulus-form-redirect/) | Replace AJAX + DOM manipulation with form submission + server redirect |
| [multi-panel-formdata-sync](skills/multi-panel-formdata-sync/) | Fix querySelector('form') first-form bug in multi-panel Stimulus controllers |

### ActiveJob

| Skill | Description |
|-------|-------------|
| [activejob-design-patterns](skills/activejob-design-patterns/) | Transaction safety, error handling, S3 file sharing, and operation-based idempotency |

### Testing & Quality

| Skill | Description |
|-------|-------------|
| [test-plan-methodology](skills/test-plan-methodology/) | 4-phase test planning to prevent coverage blind spots |
| [security-patterns](skills/security-patterns/) | Rails security checklist: XSS, CSRF, PII logging, multi-tenant isolation, and state machine security |
| [adversarial-agent-validation](skills/adversarial-agent-validation/) | Three-agent adversarial pattern (Finder/Adversary/Referee) for deep review |
| [dead-code-detection](skills/dead-code-detection/) | Systematic orphaned file and dead code identification |
| [cyclomatic-complexity-reduction](skills/cyclomatic-complexity-reduction/) | Reduce cyclomatic complexity via early-return extraction, guard unification, and safe access helpers |

### Process & Problem-Solving

| Skill | Description |
|-------|-------------|
| [root-cause-investigation](skills/root-cause-investigation/) | Five Whys + Peeling the Onion dual-mode debugging framework |
| [five-step-optimizer](skills/five-step-optimizer/) | Musk's Five-Step Algorithm for process optimization |
| [first-principles-debugger](skills/first-principles-debugger/) | First-principles debugging for complex issues that resist conventional approaches |
| [decision-timing-assessor](skills/decision-timing-assessor/) | Framework for optimal decision timing vs. information gathering (Type I/II decisions, reversibility) |
| [counterintuitive-analyst](skills/counterintuitive-analyst/) | Systematically question popular wisdom to reveal strategic insights |

### Communication & Framing

| Skill | Description |
|-------|-------------|
| [response-diversity](skills/response-diversity/) | Vary response framing by context (learner, engineer, family, researcher) |

### Productivity

| Skill | Description |
|-------|-------------|
| [scanned-document-extraction](skills/scanned-document-extraction/) | Extract structured data from scanned images/PDFs into markdown, preserving all granular detail |

### Nix & System Configuration

| Skill | Description |
|-------|-------------|
| [neovim-configuration](skills/neovim-configuration/) | Neovim config via home-manager: plugin management, nvim-tree, theme consistency, buffer navigation |
| [nix-darwin-multi-user](skills/nix-darwin-multi-user/) | Multi-user nix-darwin with home-manager: mkDarwinConfig, activation scripts, file conflicts |
| [nix-darwin-zsh-completion](skills/nix-darwin-zsh-completion/) | Fix compinit insecure directories warning: enableGlobalCompInit vs completionInit |
| [nix-github-release-packaging](skills/nix-github-release-packaging/) | Package GitHub release binaries as Nix derivations: fetchurl, SHA256 hash workflow |
| [nix-template-deployment](skills/nix-template-deployment/) | Deploy shell.nix + .envrc for per-directory packages via direnv |
| [nodejs-version-management](skills/nodejs-version-management/) | Node.js/npm version management in Nix flakes: synchronization, pnpm, native installers |
| [overriding-flake-input-packages](skills/overriding-flake-input-packages/) | Fix external flake input build failures with overrideAttrs |

### AI Tool Configuration

| Skill | Description |
|-------|-------------|
| [ai-coding-tool-portability](skills/ai-coding-tool-portability/) | Portable configuration across Claude Code and OpenCode: feature mapping, command mirroring |
| [portable-ai-cli-patterns](skills/portable-ai-cli-patterns/) | Dual-tool Claude Code + OpenCode config: compatibility matrix, single-source commands |
| [configuring-dynamic-attribution](skills/configuring-dynamic-attribution/) | Dynamic placeholders for model names in commit co-author attributions |

### Claude Code & Tooling

| Skill | Description |
|-------|-------------|
| [hook-state-cascade-patterns](skills/hook-state-cascade-patterns/) | Stateful hook patterns: cascade routing, cooldowns, state fallback, portable date parsing, and live file verification |
| [skill-decomposition-methodology](skills/skill-decomposition-methodology/) | Refactor bloated skills (>500 lines) into focused sub-skills |
| [claude-code-hook-development](skills/claude-code-hook-development/) | Create and deploy Claude Code hooks: JSON input, exit codes, transcript JSONL parsing |
| [skill-stack-deduplication](skills/skill-stack-deduplication/) | Eliminate duplication across agent/skill/command layers via reference hierarchies |
| [reality-filter](skills/reality-filter/) | Uncertainty labeling and verification standards: evidence hierarchy, self-correction |
| [red-team-framework-review](skills/red-team-framework-review/) | Adversarial review of strategic frameworks: assumption challenges, correlated failure modes |
| [changing-defaults-systematically](skills/changing-defaults-systematically/) | Zero-regression constant/default changes: find all references, update atomically |
| [git-atomic-commit-organizer](skills/git-atomic-commit-organizer/) | Organize uncommitted changes into logical, atomic commits |
| [qmd-local-search](skills/qmd-local-search/) | QMD semantic search patterns: MCP tools, index rebuild, troubleshooting |

### Third-Party

| Skill | Description | Origin |
|-------|-------------|--------|
| [frontend-design](skills/frontend-design/) | Create distinctive, production-grade frontend interfaces with high design quality | [Anthropic](https://github.com/anthropics/claude-plugins-official) |

## Compatibility

These skills follow the [Agent Skills specification](https://agentskills.io/specification) and work with any compatible agent:
Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, Goose, and others.

## License

MIT
