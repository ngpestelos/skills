---
name: skill-automation-readiness
description: "Prepare skills and scripts for background/cron automation. Adds quiet modes, random selection, idempotency, and exit codes. Use when: cron jobs, background agents, scheduled tasks. Trigger: automate skill, cron-ready, background mode, daemonize."
metadata:
  version: "1.0.1"
---

# Skill Automation Readiness

Transform interactive skills/scripts into reliable background automation. Goes beyond the five-step optimizer by adding automation-specific infrastructure.

## When to Use

- Converting a manual skill to run on a schedule (cron)
- Preparing scripts for background agent delegation
- Creating daemon-friendly utilities that run unattended

## Automation Requirements Checklist

| Requirement | Why | Implementation |
|-------------|-----|----------------|
| `--quiet` flag | Prevents log spam | Print only errors + final count |
| `--random` flag | Non-deterministic sampling | Pick one item from pool randomly |
| Exit codes | Success/failure detection | `0` = success, `1` = error, `2` = no-op |
| Idempotent operations | Safe to re-run | Skip already-processed items |
| Minimal side effects | Predictable behavior | Read-only by default, `--live` to write |
| State tracking | Resume support | JSON state file with processed IDs |

## Step-by-Step

### 1. Add CLI Flags

```python
parser.add_argument("--quiet", action="store_true", help="Minimal output for cron")
parser.add_argument("--random", action="store_true", help="Process one random item")
parser.add_argument("--live", action="store_true", help="Actually write changes")
```

### 2. Implement Random Mode

```python
if args.random:
    items = [random.choice(items)]
    args.batch = 1
```

### 3. Add Quiet Output Logic

```python
if not args.quiet:
    print(f"Processing {len(items)} items...")
# ... work ...
if not args.quiet:
    print(f"Completed: {count} items")
elif count > 0:
    print(f"Done: {count}")  # minimal for cron logs
```

### 4. Ensure Proper Exit Codes

```python
if not items:
    print("No items to process.", file=sys.stderr)
    sys.exit(2)  # No-op, not error
# ... at end ...
sys.exit(0 if success else 1)
```

### 5. Create Cron Job

```bash
# Run every 2 hours, pick random note, auto-commit results
cd ~/src/PARA && python3 script.py --random --quiet --live
```

## Anti-Patterns to Avoid

- **Interactive prompts**: Never use `input()` in automation
- **Progress bars**: Use percentage or count only
- **Color output**: Strip ANSI codes or detect TTY
- **Relative paths**: Always use absolute paths or check `cwd`
- **Verbose logging**: Log files grow unbounded; use syslog or minimal stdout

## Verification

Test before scheduling:
```bash
# Test dry-run
python3 script.py --random --quiet --dry-run

# Test live with immediate output
python3 script.py --random --live

# Verify exit codes
echo $?  # Should be 0, 1, or 2
```

## Example: Before/After

**Before** (interactive):
```python
# Prints progress every item
# Processes all items sequentially
# Requires terminal
```

**After** (automation-ready):
```python
# --quiet: only prints if work was done
# --random: picks one item unpredictably
# --live: writes changes (default is dry-run)
# Returns 0 on success, 2 if nothing to do
```
