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
/plugin install test-plan-methodology@ngpestelos-skills
/plugin install database-migration-termination-safety@ngpestelos-skills
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [root-cause-investigation](skills/root-cause-investigation/) | Five Whys + Peeling the Onion dual-mode debugging framework |
| [five-step-optimizer](skills/five-step-optimizer/) | Musk's Five-Step Algorithm for process optimization |
| [security-patterns](skills/security-patterns/) | OWASP top 10 proactive security analysis |
| [test-plan-methodology](skills/test-plan-methodology/) | 4-phase test planning to prevent coverage blind spots |
| [database-migration-termination-safety](skills/database-migration-termination-safety/) | Safe, recoverable database migration design |

## Compatibility

These skills follow the [Agent Skills specification](https://agentskills.io/specification) and work with any compatible agent:
Claude Code, Cursor, VS Code Copilot, Gemini CLI, OpenCode, Goose, and others.

## License

MIT
