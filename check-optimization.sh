#!/bin/bash
# Validate that a skill optimization preserves load-bearing content.
# Compares the current SKILL.md against an earlier version from git.
# Usage: ./check-optimization.sh <skill-name> [baseline-ref]
#   baseline-ref defaults to HEAD~1
#
# Invariants checked:
#   1. Frontmatter `name` unchanged
#   2. No semantic keyword loss in description (tokenize + set diff)
#   3. Every fenced code block in old appears verbatim in new
#   4. Every backtick span containing path/flag/command syntax preserved
#   5. Numeric threshold lines preserved (WARN only — sometimes rewritten)
#   6. Version bumped in SKILL.md and matches marketplace.json
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MARKETPLACE="$SCRIPT_DIR/.claude-plugin/marketplace.json"

# Test mode: compare two files directly without git
if [ "$1" = "--files" ]; then
  OLD_FILE="$2"
  SKILL_FILE="$3"
  SKILL_NAME="${4:-test-skill}"
  if [ ! -f "$OLD_FILE" ] || [ ! -f "$SKILL_FILE" ]; then
    echo "Usage: $0 --files <old-file> <new-file> [skill-name]"
    exit 2
  fi
  CLEANUP=""
else
  SKILL_NAME="$1"
  BASELINE_REF="${2:-HEAD~1}"

  if [ -z "$SKILL_NAME" ]; then
    echo "Usage: $0 <skill-name> [baseline-ref]"
    echo "       $0 --files <old-file> <new-file> [skill-name]"
    exit 2
  fi

  SKILL_FILE="$SCRIPT_DIR/$SKILL_NAME/SKILL.md"
  SKILL_RELPATH="$SKILL_NAME/SKILL.md"

  if [ ! -f "$SKILL_FILE" ]; then
    echo "FAIL  skill file not found: $SKILL_FILE"
    exit 1
  fi

  OLD_FILE=$(mktemp)
  trap "rm -f $OLD_FILE" EXIT

  if ! (cd "$SCRIPT_DIR" && git show "$BASELINE_REF:$SKILL_RELPATH") > "$OLD_FILE" 2>/dev/null; then
    echo "FAIL  cannot read $SKILL_RELPATH at $BASELINE_REF"
    exit 1
  fi
fi

# Single Python invocation does all heavy lifting and prints findings.
python3 - "$OLD_FILE" "$SKILL_FILE" "$SKILL_NAME" "$MARKETPLACE" <<'PYEOF'
import json
import re
import sys

old_path, new_path, skill_name, marketplace_path = sys.argv[1:5]

with open(old_path) as f:
    old = f.read()
with open(new_path) as f:
    new = f.read()

errors = []
warnings = []

# --- Helpers ---
FRONTMATTER_RE = re.compile(r'^---\n(.*?)\n---\n', re.DOTALL)

def frontmatter(text):
    m = FRONTMATTER_RE.match(text)
    return m.group(1) if m else ''

def field(fm, key):
    # Match "key: value" at top level. Description may be quoted.
    m = re.search(rf'^{re.escape(key)}:\s*(.+?)$', fm, re.MULTILINE)
    if not m:
        return ''
    val = m.group(1).strip()
    if val.startswith('"') and val.endswith('"'):
        val = val[1:-1]
    return val

def version(fm):
    # Try top-level "version:" then under "metadata:"
    m = re.search(r'^version:\s*"?([\d.]+)"?\s*$', fm, re.MULTILINE)
    if m:
        return m.group(1)
    # metadata: block — match version: under it (any indented line below)
    if re.search(r'^metadata:', fm, re.MULTILINE):
        after = fm.split('metadata:', 1)[1]
        m2 = re.search(r'^\s+version:\s*"?([\d.]+)"?', after, re.MULTILINE)
        if m2:
            return m2.group(1)
    return ''

old_fm = frontmatter(old)
new_fm = frontmatter(new)

# --- Check 1: name unchanged ---
old_name = field(old_fm, 'name')
new_name = field(new_fm, 'name')
if old_name != new_name:
    errors.append(f"name changed: {old_name!r} -> {new_name!r}")

# --- Check 2: description token preservation ---
STOPWORDS = set("""
a an the is are was were be been being of in on at to for from with by as if it
its this that these those and or but not no nor both each all any some other
others same such only just also too very can could should would will may might
must do does did done has have had into onto out up down over under via use
used using uses while when where which what who whose whom how why so than then
about across after before because between during many much most more less least
new newest old older
""".split())

def tokenize(text):
    text = text.lower()
    text = re.sub(r'[^a-z0-9]+', ' ', text)
    tokens = set(t for t in text.split() if len(t) > 1 and t not in STOPWORDS)
    return tokens

old_desc = field(old_fm, 'description')
new_desc = field(new_fm, 'description')
old_tokens = tokenize(old_desc)
new_tokens = tokenize(new_desc)
lost_tokens = old_tokens - new_tokens
if lost_tokens:
    errors.append(f"description tokens lost: {sorted(lost_tokens)}")

# --- Check 3: fenced code-block preservation ---
def code_blocks(text):
    # Match ```...``` blocks; capture inner content.
    return [m.group(1).strip() for m in re.finditer(r'```[^\n]*\n(.*?)\n```', text, re.DOTALL)]

old_blocks = code_blocks(old)
new_blocks_set = set(code_blocks(new))
missing_blocks = [b for b in old_blocks if b not in new_blocks_set]
if missing_blocks:
    summaries = []
    for b in missing_blocks[:3]:
        first = b.split('\n', 1)[0][:80]
        summaries.append(first)
    errors.append(f"{len(missing_blocks)} code block(s) lost. First: {summaries}")

# --- Check 4: inline-code spans (path/flag/command) ---
INLINE_CMD_PREFIXES = (
    'git ', 'npm ', 'nix ', 'bundle ', 'rake ', 'node ', 'python', 'ruby ',
    'cd ', 'ls ', 'cp ', 'mv ', 'rm ', 'grep ', 'awk ', 'sed ', 'find ',
    'chmod ', 'mkdir ', 'cat ', 'echo ', 'export ', 'source ', 'sudo ',
    'apt ', 'brew ', 'pip ', 'docker ', 'kubectl ', 'curl ', 'wget ',
    'ssh ', 'scp ', 'tar ', 'zip ', 'unzip ', 'cargo ', 'go ', './',
)
def is_loadbearing_inline(span):
    inner = span.strip('`')
    if '/' in inner or '--' in inner:
        return True
    if any(s in inner for s in ('.sh', '.md', '.json', '.toml', '.yaml', '.yml', '.py', '.rb', '.js')):
        return True
    if any(inner.startswith(p) for p in INLINE_CMD_PREFIXES):
        return True
    return False

def inline_spans(text):
    return set(s for s in re.findall(r'`[^`\n]+`', text) if is_loadbearing_inline(s))

old_inline = inline_spans(old)
new_inline = inline_spans(new)
lost_inline = old_inline - new_inline
if lost_inline:
    errors.append(f"inline-code spans lost: {sorted(lost_inline)[:5]}")

# --- Check 5: numeric threshold lines (WARN only) ---
THRESHOLD_RE = re.compile(r'\b\d+\s*(lines?|chars?|MB|GB|KB|sec(?:onds?)?|min(?:utes?)?|hours?|ms|%|files?|tokens?)\b', re.IGNORECASE)
def threshold_lines(text):
    return set(line.strip() for line in text.split('\n') if THRESHOLD_RE.search(line))

old_thresholds = threshold_lines(old)
new_thresholds = threshold_lines(new)
lost_thresholds = old_thresholds - new_thresholds
if lost_thresholds:
    sample = list(lost_thresholds)[:3]
    warnings.append(f"{len(lost_thresholds)} threshold line(s) changed/removed (review): {sample}")

# --- Check 6: version bump ---
old_ver = version(old_fm)
new_ver = version(new_fm)

def semver_tuple(v):
    try:
        return tuple(int(x) for x in v.split('.'))
    except ValueError:
        return None

if not new_ver:
    errors.append("no version in new SKILL.md")
elif old_ver and new_ver == old_ver:
    errors.append(f"version not bumped: {old_ver}")
elif old_ver and semver_tuple(new_ver) and semver_tuple(old_ver):
    if semver_tuple(new_ver) <= semver_tuple(old_ver):
        errors.append(f"new version not greater: {old_ver} -> {new_ver}")

# Marketplace version match
try:
    with open(marketplace_path) as f:
        mp = json.load(f)
    mp_ver = ''
    for p in mp.get('plugins', []):
        if p.get('name') == skill_name:
            mp_ver = p.get('version', '')
            break
    if mp_ver and new_ver and mp_ver != new_ver:
        errors.append(f"marketplace version mismatch: SKILL.md={new_ver} marketplace={mp_ver}")
    elif new_ver and not mp_ver:
        warnings.append(f"no marketplace.json entry for {skill_name}")
except (FileNotFoundError, json.JSONDecodeError) as e:
    warnings.append(f"could not read marketplace.json: {e}")

# --- Output ---
for w in warnings:
    print(f"WARN  {w}")
for e in errors:
    print(f"FAIL  {e}")

if errors:
    print(f"\nRESULT: FAIL ({len(errors)} error(s))")
    sys.exit(1)
print("\nRESULT: PASS")
sys.exit(0)
PYEOF
