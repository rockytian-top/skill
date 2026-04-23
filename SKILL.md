---
name: rocky-know-how
slug: rocky-know-how
version: 2.8.3
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v2.8.3 — Search learnings when failing 2+ times, write after solving. Layered storage (HOT/WARM/COLD), auto-promotion/demotion, 4-event hook integration (bootstrap/before_compaction/after_compaction/before_reset), one-click install. Fixes: H1 (FILTER_DOMAIN/FILTER_PROJECT regex injection), H2 (agentId path traversal), concurrent write atomicity, format_all robustness, OPENCLAW_STATE_DIR support."
changelog: |
  v2.8.3: 安全修复 (H1/H2)，compact.sh memory.md压缩优化，memory.md 111→18行
  v2.8.2: 一键安装脚本 (install.sh)，自动配置4个Hook事件，auto-restart网关
  v2.7.1: 支持OpenClaw 2026.4.21新Hook(before_compaction/after_compaction/before_reset)
  v2.5.1: 退回简单版，不使用hook注入
metadata: {"openclaw":{"emoji":"📚","requires":{"bins":[]},"os":["darwin","linux","win32"]}}
---

## When to Use

- Task failed 2+ times → Search learnings: use `search.sh` script
- Solved the problem → Write lesson (record.sh)
- Same Tag 3x in 7 days → Promote to HOT (promote.sh)
- Same Tag not used 30+ days → Demote to WARM (demote.sh)
- Session compaction → Auto-create draft (before_compaction hook)
- Task completed → Self-reflect (reflections.md)

## Architecture

Learnings stored at `~/.openclaw/.learnings/`:
- `experiences.md` - Main data file (v1 compatible)
- `memory.md` - HOT layer (≤100 lines, always loaded)
- `domains/` - WARM layer (namespace isolation)
- `projects/` - WARM layer (project isolation)
- `archive/` - COLD layer (90+ days old)

## Hook Events

| Event | Trigger | Function |
|-------|---------|----------|
| agent:bootstrap | AI启动 | 注入经验提醒 + AI判断草稿 |
| before_compaction | 压缩前 | 分析会话，生成经验草稿 |
| after_compaction | 压缩后 | 记录会话摘要 |
| before_reset | 重置前 | 保存状态，生成草稿 |

## One-Click Install

```bash
git clone <repo> ~/.openclaw/skills/rocky-know-how
bash ~/.openclaw/skills/rocky-know-how/scripts/install.sh
```

## Quick Reference

| Topic | File |
|-------|------|
| Setup guide | `setup.md` |
| Scripts | `scripts/*.sh` |
| Hook handler | `hooks/openclaw/handler.js` |

## Quick Queries

| User says | Action |
|-----------|--------|
| "search learnings X" | Use `search.sh` script |
| "learning stats" | Use `stats.sh` |
| "forget X" | Delete from all layers |
