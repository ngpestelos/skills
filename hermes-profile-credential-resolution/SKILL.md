---
name: hermes-profile-credential-resolution
version: 1.0
description: Resolve credential location mismatches when Hermes profiles use profile-specific .env files but scripts/tools look in default locations. Handles firecrawl and other API key resolution issues.
trigger: hermes profile credentials, api key not found, firecrawl credentials, skill can't find api key, profile .env, credential location
allowed-tools:
  - Bash
  - Read
  - Grep
---

# Hermes Profile Credential Resolution

> **Problem:** Hermes stores credentials in profile-specific `.env` files (`~/.hermes/profiles/<profile>/.env`), but scripts and tools often look in the default location (`~/.hermes/.env`), causing "API key not found" errors even when credentials are configured.

## The Pattern

### 1. Check Where Credentials Actually Are

```bash
# Check Hermes profile .env
cat ~/.hermes/profiles/$(whoami)/.env | grep -i api_key

# Check default Hermes .env
cat ~/.hermes/.env | grep -i api_key

# Check current environment
env | grep -i api_key
```

### 2. Export from Profile .env to Current Session

When a script can't find the API key:

```bash
# Export from profile .env before running the tool
export FIRECRAWL_API_KEY=$(grep "FIRECRAWL_API_KEY" ~/.hermes/profiles/belvedere/.env | cut -d'=' -f2)

# Then run the script
python3 .claude/scripts/firecrawl-fetch.py scrape URL -o output.md
```

### 3. Link External Skills to Hermes

Skills installed via `npx skills add` go to `~/.agents/skills/` but Hermes looks in `~/src/skills/`:

```bash
# Link all firecrawl skills for Hermes access
for skill in ~/.agents/skills/firecrawl*; do
  name=$(basename "$skill")
  ln -sf "$skill" ~/src/skills/"$name"
done
```

## Common Symptoms

- "FIRECRAWL_API_KEY not found in env, Keychain, or ~/.hermes/.env"
- Tool prompts for API key despite it being configured
- Skill loads but can't access credentials
- Script works in Claude Code but not in Hermes

## Resolution Priority

1. **Check profile .env first** — Hermes uses profile-specific env files
2. **Export explicitly** — `export KEY=$(grep KEY ~/.hermes/profiles/<profile>/.env | cut -d'=' -f2)`
3. **Link skills** — Ensure `~/.agents/skills/` are symlinked to `~/src/skills/`
4. **Verify env var** — Run `env | grep KEY` to confirm it's exported

## Reference Locations

| Location | Purpose |
|----------|---------|
| `~/.hermes/profiles/<profile>/.env` | Hermes profile credentials (actual location) |
| `~/.hermes/.env` | Default Hermes env (may be empty or missing) |
| `~/.agents/skills/` | Skills installed via `npx skills add` |
| `~/src/skills/` | Hermes skill search path |

## See Also

- **`external-tool-skill-installation`** — Installing skills from external tools (install skills first, then resolve credentials)
- **`dotenv-shell-export`** — Loading .env files as environment variables (different pattern for shell vs env vars)
