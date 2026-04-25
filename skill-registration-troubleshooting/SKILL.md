---
name: skill-registration-troubleshooting
description: "Diagnose why a Hermes skill isn't appearing in the skill index despite having a valid SKILL.md file. Auto-activates when skills aren't discovered after symlink creation, skill_view fails for existing skills, or skill count doesn't increase. Covers circular symlink detection, directory structure validation, and skill loader behavior."
allowed-tools: Read, Bash
metadata:
  version: "1.0.1"
  category: hermes
---

# Skill Registration Troubleshooting

Diagnose why a skill with a valid SKILL.md isn't being discovered by the skill loader.

## Quick Checklist

1. **Symlink exists in `~/.claude/skills/`?**
   ```bash
   ls -la ~/.claude/skills/ | grep <skill-name>
   ```

2. **SKILL.md is valid YAML frontmatter?**
   - Must have `name`, `description` fields
   - Frontmatter delimited by `---`

3. **No circular symlinks in skill directory?**
   ```bash
   ls -la <skill-path>/
   ```
   - Should ONLY contain `SKILL.md`
   - ❌ Remove any self-referencing symlinks

4. **Symlink points to directory with SKILL.md?**
   ```bash
   file ~/.claude/skills/<skill-name>
   # Should say: directory
   ```

## Common Root Causes

### Circular Symlink (Most Common)

**Symptom:** Skill exists but never appears in index.

**Cause:** Symlink command run from wrong directory creates self-reference:
```bash
# WRONG - run from skill directory
ln -s . perplexity-space-prompt-builder

# Creates: skill-dir/perplexity-space-prompt-builder -> skill-dir (infinite loop)
```

**Fix:**
```bash
rm <skill-path>/<skill-name>  # Remove circular symlink
```

### Missing Symlink

**Symptom:** `skill_view()` says "Skill not found" but file exists in project.

**Fix:**
```bash
ln -s <project-path>/.claude/skills/<name> ~/.claude/skills/<name>
```

### Invalid Frontmatter

**Symptom:** Skill appears in list but `skill_view()` fails or returns partial data.

**Check:**
- YAML syntax valid (no tabs, proper quoting)
- Required fields: `name`, `description`
- `name` matches directory name

## Diagnostic Commands

```bash
# Compare with working skill
ls -la ~/.claude/skills/<working-skill>/
ls -la <skill-path>/

# Check for circular references
find <skill-path> -type l -exec ls -la {} \;

# Validate symlink target
readlink -f ~/.claude/skills/<skill-name>
```

## Skill Loader Behavior

- Skills are indexed at **gateway startup**
- New symlinks require **restart** to appear
- Circular symlinks cause **silent skipping** — loader traverses recursively; any symlink cycle silently excludes the skill with no error messages
- Invalid YAML causes **partial loading** or errors

## Recovery Protocol

1. Verify SKILL.md is valid standalone file
2. Ensure skill directory contains ONLY SKILL.md (no nested symlinks)
3. Create/update symlink in `~/.claude/skills/`
4. Restart Hermes gateway to re-index
5. Verify with `skills_list()` and `skill_view(name)`
