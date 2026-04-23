---
name: rocky-know-how
slug: rocky-know-how
version: 2.8.7
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v2.8.7 — Search learnings when failing 2+ times, write after solving. Layered storage (HOT/WARM/COLD), auto-promotion/demotion, 4-event hook integration. Core innovations: (1) Auto-record mechanism, (2) Vector search with LM Studio, (3) Auto-fallback when no embedding model. Fixes: H1 (regex injection), H2 (path traversal), concurrent write lock, format_all robustness, OPENCLAW_STATE_DIR support."
changelog: |
  v2.8.7: 文档统一 - 批量更新所有文档中的版本号引用为 2.8.6（13个文件，50+处更新）
  v2.8.6: 文档完善 - 新增 INDEX.md（文档导航地图）和 FAQ.md（17个常见问题解答），根目录说明文档完整
  v2.8.5: 文档完善 - 新增 advanced-features.md 详细说明三大核心创新（自动写入、向量搜索、自动降级），README 顶部突出展示
  v2.8.4: 文档完善 - 新增 QUICKSTART.md，详细说明自动写入流程、触发条件、使用场景、验证步骤
  v2.8.3: 安全修复 (H1/H2)，compact.sh memory.md压缩优化，memory.md 111→18行
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
