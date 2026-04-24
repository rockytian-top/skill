---
name: rocky-know-how
slug: rocky-know-how
version: 2.9.2
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v2.9.2 — Search learnings when failing 2+ times, write after solving. Layered storage (HOT/WARM/COLD), auto-promotion/demotion, 4-event hook integration. Core innovations: (1) Auto-draft mechanism (two-phase: draft→review→formal), (2) Vector search with LM Studio, (3) Auto-fallback when no embedding model, (4) before_compaction→pending/after_compaction→LLM判断→写入experiences.md. Fixes: H1 (regex injection), H2 (path traversal), concurrent write lock. v2.9.2: LLM判断create/append替代关键词匹配，draft/pending双归档，block regex修复。"
changelog: |
  v2.9.2: feat: LLM判断"新增 vs 追加"替代关键词匹配 - decideCreateOrAppend()语义判断+相似经验全文对比。
  v2.9.2: feat: draft文件处理后归档到drafts/archive/，保持与auto-review.sh一致的归档行为。
  v2.9.2: fix: searchSimilarExperiences block regex修复 - 匹配含标题行的经验条目格式。
  v2.9.2: fix: processPendingItem worth=true时pending文件未归档bug修复。
  v2.9.2: fix: 移除硬编码模型，callLLMJudge仅从openclaw.json的zai provider读取配置。
  v2.9.1: 🎯 直接处理模式 - after_compaction直接处理pending，不再触发子agent。
  v2.9.1: after_compaction集成LLM判断流程 - callLLMJudge→decideCreateOrAppend→record/append。
  v2.9.1: 压缩前生成草稿/压缩后写入正式经验，两阶段分工明确。
  v2.9.1: after_compaction全自动草稿审核集成。
  v2.9.1: ✅ 完整体测试验证通过。
  v2.9.1: 🆕 auto-review.sh全自动草稿审核脚本。
  v2.9.1: 安全修复 (H1/H2)，compact.sh memory.md压缩优化。
metadata: {"openclaw":{"emoji":"📚","requires":{"bins":[]},"os":["darwin","linux","win32"]}}
---

## When to Use

- Task failed 2+ times → Search learnings: use `search.sh` script
- Solved the problem → Write lesson (record.sh)
- Same Tag 3x in 7 days → Promote to HOT (promote.sh)
- Same Tag not used 30+ days → Demote to WARM (demote.sh)
- Session compaction → Auto-extract context + LLM judge → write to experiences (fully automatic)

## Architecture

Learnings stored at `~/.openclaw/.learnings/`:
- `experiences.md` - Main data file (v1 compatible)
- `memory.md` - HOT layer (≤100 lines, always loaded)
- `domains/` - WARM layer (namespace isolation)
- `projects/` - WARM layer (project isolation)
- `archive/` - COLD layer (90+ days old)
- `drafts/` - Drafts (auto-archived after processing)
- `pending/` - Pending context items (auto-archived after processing)

## Hook Events

| Event | Trigger | Function |
|-------|---------|----------|
| agent:bootstrap | AI启动 | 注入经验提醒 |
| before_compaction | 压缩前 | 提取task/tools/errors保存到pending + autoSearch注入相关经验 |
| after_compaction | 压缩后 | LLM判断worth→生成草稿→LLM判断create/append→写入experiences→归档 |
| before_reset | 重置前 | 保存pending（兜底） |

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
