---
name: hermes-profile-role-adaptation
description: "When porting a pattern (Output Style, state protocol, cron) between Hermes profiles, adapt for the target role's modes and privacy boundaries — don't paste verbatim from Selma/Sensei. Use when cloning Selma's structure to a new profile, when a profile has multiple operational modes with different format needs, or when private/sacred content shouldn't leak into git-tracked state. Trigger keywords: profile pattern porting, cross-profile, role adaptation, mode-aware output, privacy scoping, sacred mode, paste verbatim, mirror profile."
metadata:
  category: hermes
  version: "1.1.0"
---

# Adapting Patterns to Profile Roles

When porting a pattern from Selma or Sensei to a new Hermes profile, the shape (file paths, headers, prune scripts) is constant — but **scope and tone vary by role**. Pasting verbatim produces subtly wrong output that takes a second pass to fix.

## Three role-adaptation rules

### 1. Mode-aware Output Style

If the profile has multiple operational modes with different output needs, segment Output Style by mode — don't apply Selma's uniform bullet format. Bullet-heavy output undermines reflective/conversational modes.

Example (Martinson, 2026-04-26):
- Sounding-board mode → prose, short paragraphs, one question per turn, no headlines
- Red-team mode → bullets, lens-structured, severity-tagged, lead with unfalsifiable flags

If the role has only one mode (Selma: monitor, Sensei: tutor), Selma's uniform Output Style ports fine.

### 2. Privacy-scope the state file

If the profile has private/sacred conversation modes, **exclude that content from the vault state file**. Vault auto-sync gives broader visibility than messaging surfaces — a git-tracked file is not the right home for "sacred" content.

Implementation:
- Operational Protocol explicitly says "no write" for sacred-only sessions
- HTML comment header in the state file documents the scope rule for future readers
- Format spec accommodates only the non-private mode

### 3. A reactive profile's first cron is often the prune

Don't block on "but this profile has no cron jobs configured." The daily state-prune is itself a legitimate cron and the only one a reactive profile may need. Pattern proven on Sensei (reactive tutor) and Martinson (reactive advisor).

## Decision checklist (run before paste-mirroring)

1. List the profile's operational modes — if more than one, plan a mode-aware Output Style
2. List the privacy boundaries from SOUL.md (Boundaries section + any "sacred" / "private" declarations)
3. For each pattern element being ported, ask: does it conflict with a constraint above? If yes, adapt.

## Pitfalls

- **Don't add a state file when the role has no continuity need.** State helps when the profile re-does work or re-discovers the same findings (Sensei's re-explain, Martinson's re-flag). No such failure mode → no state file.
- **Don't extend privacy-scope to "skip state entirely."** Privacy-scope means exclude private modes from the file, not skip the file. Martinson's state file exists; it just covers red-team only.
