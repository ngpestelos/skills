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
| [activerecord-application-query-optimization](skills/activerecord-application-query-optimization/) | N+1 prevention, batch preloading, duplicate join detection, and eager loading patterns |
| [activerecord-query-performance-patterns](skills/activerecord-query-performance-patterns/) | Four techniques preventing 10-70x PostgreSQL query degradation |
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
| [security-patterns](skills/security-patterns/) | OWASP top 10 proactive security analysis |
| [adversarial-agent-validation](skills/adversarial-agent-validation/) | Three-agent adversarial pattern (Finder/Adversary/Referee) for deep review |
| [dead-code-detection](skills/dead-code-detection/) | Systematic orphaned file and dead code identification |

### Process & Problem-Solving

| Skill | Description |
|-------|-------------|
| [root-cause-investigation](skills/root-cause-investigation/) | Five Whys + Peeling the Onion dual-mode debugging framework |
| [five-step-optimizer](skills/five-step-optimizer/) | Musk's Five-Step Algorithm for process optimization |

### Claude Code & Tooling

| Skill | Description |
|-------|-------------|
| [claude-code-command-optimizer](skills/claude-code-command-optimizer/) | Design, debug, and optimize Claude Code custom commands |
| [hook-state-cascade-patterns](skills/hook-state-cascade-patterns/) | Stateful hook patterns: cascade routing, cooldowns, and state fallback |
| [skill-decomposition-methodology](skills/skill-decomposition-methodology/) | Refactor bloated skills (>500 lines) into focused sub-skills |

## Compatibility

These skills follow the [Agent Skills specification](https://agentskills.io/specification) and work with any compatible agent:
Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, Goose, and others.

## License

MIT
