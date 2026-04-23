---
name: rocky-know-how
description: "经验诀窍技能 Hook v2.8.6 — 对齐 OpenClaw 2026.4.21，4事件Hook集成"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap","before_compaction","after_compaction","before_reset"]}}
---

# rocky-know-how Hook v2.8.6

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 支持的事件

| 事件 | 触发时机 | 功能 |
|------|----------|------|
| agent:bootstrap | AI 启动 | 注入经验提醒 + 检查草稿（仅提醒） |
| before_compaction | 压缩前 | 保存会话状态到 .compaction-state.tmp |
| after_compaction | 压缩后 | 生成会话总结（session-summaries.md） |
| before_reset | 重置前 | **生成草稿**（drafts/draft-*.json，状态 pending_review） |

## ⚠️ 重要：两阶段机制

### 阶段1: 自动草稿（Hook 完成）
- **before_reset** 触发 → 分析会话 → 生成草稿 JSON
- 草稿位置: `~/.openclaw/.learnings/drafts/`
- 草稿状态: `"pending_review"`（待审核）
- **不自动写入** `experiences.md`

### 阶段2: 审核草稿（人工/AI 辅助）
- 执行 `summarize-drafts.sh` 批量生成建议
- 查看 `~/.openclaw/.learnings/.summarize.log`
- **人工执行** `record.sh` 命令写入正式经验

### 为什么这样设计？
- ✅ 防止测试对话、闲聊污染经验库
- ✅ 质量把关：只有值得复用的经验才入库
- ✅ 可追溯：草稿保留原始上下文
- ✅ 安全：避免自动执行带来的风险

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **跨 workspace** — 支持 shared 目录和全局安装
- **数据检测** — 自动检测经验数据状态和 v2 分层存储
- **子agent跳过** — 避免重复注入
- **虚拟文件** — 不污染工作区文件
- **草稿AI判断** — 下次bootstrap时AI判断是否写入经验库

## v2.8.1 更新

- **一键安装** — install.sh 自动配置4个Hook事件
- **自动重启网关** — 配置完成后自动重启使配置生效
- **修复append-record.sh** — 修正AWK逻辑，精确插入到预防之后

## v2.7.1 更新

- 支持 OpenClaw 2026.4.21 新 Hook
- 草稿生成后 AI 自动判断是否写入经验库
- 支持更新旧经验、追加新方式
- 超过3天草稿自动清理

## 工作流程（v2.8.6+ 两阶段）

```
第1步: agent:bootstrap → 注入经验提醒（不自动判断草稿）
第2步: before_compaction → 保存会话状态到 .compaction-state.tmp
第3步: after_compaction → 记录会话总结到 session-summaries.md
第4步: before_reset → 生成草稿 (drafts/draft-*.json)
    ↓
    草稿状态: pending_review（待审核）
    ↓
第5步: [人工] 执行 summarize-drafts.sh 批量审核
    → 生成 record.sh 建议命令
    ↓
第6步: [人工] 执行 record.sh 写入正式经验
    ↓ experiences.md ✅
```

**关键更正**:
- ❌ "草稿生成后 AI 自动判断写入" — 已废弃（v2.8.6+）
- ✅ "草稿生成后需人工审核" — 当前机制
- ⚠️ `summarize-drafts.sh` 只输出建议，不自动执行

## 启用方式

```bash
bash install.sh
```

自动完成：目录创建 → 文件初始化 → Hook配置 → 网关重启

## 一键安装 v2.8.1

```bash
git clone <repo> ~/.openclaw/skills/rocky-know-how
bash ~/.openclaw/skills/rocky-know-how/scripts/install.sh
```
