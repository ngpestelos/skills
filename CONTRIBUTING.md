# Contributing

## Updating a Skill

1. **Edit** the skill's `SKILL.md` (or files in `references/`)
2. **Audit** the skill against the Agent Skills spec:
   ```
   /skills-audit <skill-name>
   ```
3. **Fix** any spec violations flagged by the audit
4. **Increment** the `version` in the skill's SKILL.md frontmatter (`metadata.version`) and in `.claude-plugin/marketplace.json`
5. **Commit** with a message describing what changed and why

## Adding a New Skill

1. Create `<category>/<skill-name>/SKILL.md` with spec-compliant frontmatter
2. Run `/skills-audit <skill-name>` to validate
3. Add an entry to `.claude-plugin/marketplace.json`
4. Update the skills table in `README.md`
5. Commit and push

## Versioning

Use semver in `metadata.version`:
- **Patch** (1.0.0 → 1.0.1): Typo fixes, wording improvements, no behavior change
- **Minor** (1.0.0 → 1.1.0): New patterns, examples, or sections added
- **Major** (1.0.0 → 2.0.0): Breaking changes to methodology or structure

Both locations must stay in sync:
- `<category>/<name>/SKILL.md` frontmatter: `version` under `metadata:`
- `.claude-plugin/marketplace.json`: `version` field in the plugin entry

## Spec Compliance

All skills must pass the [Agent Skills specification](https://agentskills.io/specification) checks:
- `name`: lowercase + hyphens, 1-64 chars, matches directory name
- `description`: present, <= 1024 chars
- Body: < 500 lines, < 5000 tokens estimated
- No non-standard frontmatter keys outside `metadata:`
