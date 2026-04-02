---
name: disk-space-troubleshooting
description: "Provides guidance on diagnosing and resolving disk space issues on macOS, particularly for Nix users. Covers Nix garbage collection, cache cleanup, large file discovery, and safe deletion patterns. Trigger keywords: disk full, no space left, NoSpaceLeft, nix-collect-garbage, free space, disk usage, df -h, du -sh, cache cleanup, 100% disk."
metadata:
  version: 1.0.0
---

# Troubleshooting Disk Space Issues on macOS

## Quick Diagnosis

```bash
df -h /
df -h /nix 2>/dev/null || echo "Nix uses root partition"
du -sh ~/* 2>/dev/null | sort -h | tail -20
du -sh ~/.[!.]* 2>/dev/null | sort -h | tail -10
du -sh /nix/store 2>/dev/null
```

**Warning signs**: `Use%` at 95%+, available space under 5GB, under 3GB blocks most Nix builds.

## Safe Cleanup Hierarchy (Ascending Risk)

### Level 1: Nix Garbage Collection (Safest)

```bash
nix-collect-garbage -d
nix-collect-garbage --delete-older-than 7d
nix-store --gc --print-dead  # dry run
```

Removes old profile generations, unused store paths, failed build artifacts. **Typical recovery: 5-20GB.**

### Level 2: System Caches

```bash
rm -rf ~/Library/Caches/Homebrew/*
brew cleanup --prune=all
npm cache clean --force
pip cache purge
yarn cache clean
```

### Level 3: Development Caches

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
xcrun simctl delete unavailable
pod cache clean --all
```

### Level 4: Application Caches (Review First)

```bash
du -sh ~/Library/Caches/* 2>/dev/null | sort -h | tail -20
# Remove specific app cache after review
```

### Level 5: AI/Model Caches

```bash
rm -rf ~/.cache/huggingface/
rm -rf ~/.cache/qmd/
```

Will re-download on next use.

## Nix-Specific Reference

| Symptom | Cause | Solution |
|---------|-------|----------|
| `NoSpaceLeft` during build | Disk full | `nix-collect-garbage -d` |
| `/nix/store` very large | Accumulated packages | `nix-collect-garbage -d` |
| Old generations exist | Never cleaned | `nix-collect-garbage -d` |
| Build sandbox failure | Temp space full | Clear `/tmp` or increase space |

## Rules

- Never manually delete from `/nix/store` — always use `nix-collect-garbage -d`
- Always use `-d` flag — without it, cleanup is minimal
- Quit applications before clearing their caches
