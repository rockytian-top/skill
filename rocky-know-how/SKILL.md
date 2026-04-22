---
name: rocky-know-how
slug: rocky-know-how
version: 2.6.0
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v2 — Aligns with self-improving. Search learnings when failing 2+ times, write after solving. Layered storage (HOT/WARM/COLD), auto-promotion/demotion, namespace isolation, corrections log, reflections, heartbeat integration."
changelog: "v2.6.0: 支持OpenClaw 2026.4.21新Hook(before_compaction/after_compaction/before_reset)

v2.5.1: 退回简单版，不使用hook注入

v2.5.0: 恢复exec+search.sh原版行为
metadata: {"openclaw":{"emoji":"📚","requires":{"bins":[]},"os":["darwin","linux","win32"]}}
---

## When to Use

- Task failed 2+ times → Search learnings: use `search.sh` script
- Solved the problem → Write lesson (record.sh)
- Same Tag 3x in 30 days → Promote to HOT (promote.sh)
- Task completed → Self-reflect (reflections.md)

## Architecture

Learnings stored at `~/.openclaw/.learnings/`:
- `experiences.md` - Main data file
- `memory.md` - HOT layer
- `domains/` - WARM layer
- `archive/` - COLD layer

## Quick Reference

| Topic | File |
|-------|------|
| Setup guide | `setup.md` |

## Quick Queries

| User says | Action |
|-----------|--------|
| "search learnings X" | Use `search.sh` script |
| "learning stats" | Use `stats.sh` |
| "forget X" | Delete from all layers |
