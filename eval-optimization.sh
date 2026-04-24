#!/usr/bin/env python3
"""
Tier 1 LLM-as-judge: adversarially audit a skill optimization for behavioral preservation.

Usage: ./eval-optimization.sh <skill-name> [baseline-ref]
       ./eval-optimization.sh --files <old-file> <new-file> [skill-name]

Cross-model: judge runs on Sonnet by default (the optimization is typically run by Opus).
Override with JUDGE_MODEL=opus in the environment.

Output: JSON verdict on stdout. Exit codes: 0=PASS, 1=FAIL, 2=usage/runtime error.
"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

JUDGE_MODEL = os.environ.get("JUDGE_MODEL", "sonnet")
SCRIPT_DIR = Path(__file__).resolve().parent

SCHEMA = {
    "type": "object",
    "properties": {
        "verdict": {"type": "string", "enum": ["PASS", "FAIL"]},
        "losses": {"type": "array", "items": {"type": "string"}},
        "trigger_concerns": {"type": "array", "items": {"type": "string"}},
        "confirmations": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["verdict", "losses", "trigger_concerns"],
}


def usage():
    print(__doc__, file=sys.stderr)
    sys.exit(2)


def get_old_new_paths(argv):
    if not argv:
        usage()
    if argv[0] == "--files":
        if len(argv) < 3:
            usage()
        old_path = Path(argv[1])
        new_path = Path(argv[2])
        skill_name = argv[3] if len(argv) > 3 else "test-skill"
        if not old_path.is_file() or not new_path.is_file():
            print(f"ERROR  --files requires existing paths", file=sys.stderr)
            sys.exit(2)
        return old_path, new_path, skill_name, None
    skill_name = argv[0]
    baseline_ref = argv[1] if len(argv) > 1 else "HEAD~1"
    new_path = SCRIPT_DIR / skill_name / "SKILL.md"
    if not new_path.is_file():
        print(f"ERROR  skill file not found: {new_path}", file=sys.stderr)
        sys.exit(2)
    rel = f"{skill_name}/SKILL.md"
    try:
        old_content = subprocess.check_output(
            ["git", "show", f"{baseline_ref}:{rel}"],
            cwd=str(SCRIPT_DIR),
            stderr=subprocess.DEVNULL,
        ).decode()
    except subprocess.CalledProcessError:
        print(f"ERROR  cannot read {rel} at {baseline_ref}", file=sys.stderr)
        sys.exit(2)
    tmp = tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".md")
    tmp.write(old_content)
    tmp.close()
    return Path(tmp.name), new_path, skill_name, tmp.name


def build_prompt(old_text, new_text, skill_name):
    return f"""You are auditing whether an edit to a Claude Code skill file preserves the
skill's behavior. The edit is intended to remove redundancy, not to change
methodology, trigger surface, or precision.

Skill name: {skill_name}

OLD version:
<<<OLD_START
{old_text}
OLD_END>>>

NEW version:
<<<NEW_START
{new_text}
NEW_END>>>

Audit aggressively. Your job is to find what was lost, not to confirm
plausibility. Specifically check:

1. Procedures, commands, regex patterns, thresholds, or diagnostic steps in
   OLD that are absent or weakened in NEW. Paraphrasing a verbatim command
   into prose counts as weakening.

2. Trigger keywords or auto-activation conditions in OLD's frontmatter
   description that are absent or generalized in NEW's. Even one missing
   keyword can break invocation.

3. Changes to the skill's scope, applicability, or audience.

If you find real loss in any category, set verdict=FAIL and list the
specific losses in 'losses' or 'trigger_concerns'. If nothing material was
lost, set verdict=PASS and list confirmations (e.g., "all 4 trigger
keywords retained: foo, bar, baz, qux").

Do not say "looks good" or summarize the change. Either name what's lost,
or confirm with evidence."""


def call_claude(prompt):
    cmd = [
        "claude",
        "-p",
        "--model", JUDGE_MODEL,
        "--output-format", "json",
        "--json-schema", json.dumps(SCHEMA),
        "--no-session-persistence",
        "--exclude-dynamic-system-prompt-sections",
        prompt,
    ]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=180,
        )
    except subprocess.TimeoutExpired:
        print("ERROR  claude call timed out after 180s", file=sys.stderr)
        sys.exit(2)
    if result.returncode != 0:
        print(f"ERROR  claude exit {result.returncode}", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(2)
    return result.stdout


def parse_envelope(raw):
    try:
        env = json.loads(raw)
    except json.JSONDecodeError:
        return None, raw
    # When --json-schema is set, claude returns the validated object under
    # 'structured_output'. Fall back to legacy 'result'/'output'/'content' shapes.
    structured = env.get("structured_output")
    if isinstance(structured, dict) and "verdict" in structured:
        return structured, None
    inner = env.get("result") or env.get("output") or env.get("content")
    if isinstance(inner, list):
        inner = inner[0] if inner else ""
    if isinstance(inner, dict):
        inner = inner.get("text") or inner.get("content") or json.dumps(inner)
    if isinstance(inner, str):
        try:
            return json.loads(inner), None
        except json.JSONDecodeError:
            return None, inner
    return inner, None


def main():
    argv = sys.argv[1:]
    old_path, new_path, skill_name, cleanup = get_old_new_paths(argv)
    try:
        old_text = old_path.read_text()
        new_text = new_path.read_text()
        prompt = build_prompt(old_text, new_text, skill_name)
        raw = call_claude(prompt)
        verdict_obj, fallback = parse_envelope(raw)
        if verdict_obj is None:
            print("ERROR  could not parse judge output:", file=sys.stderr)
            print(fallback or raw, file=sys.stderr)
            sys.exit(2)
        print(json.dumps(verdict_obj, indent=2))
        verdict = verdict_obj.get("verdict")
        if verdict == "PASS":
            sys.exit(0)
        if verdict == "FAIL":
            sys.exit(1)
        print(f"ERROR  unexpected verdict: {verdict}", file=sys.stderr)
        sys.exit(2)
    finally:
        if cleanup:
            try:
                os.unlink(cleanup)
            except OSError:
                pass


if __name__ == "__main__":
    main()
