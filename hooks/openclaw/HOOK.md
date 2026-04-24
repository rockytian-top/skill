---
name: rocky-know-how
description: "经验诀窍技能 Hook v2.9.1 — 对齐 OpenClaw 2026.4.21，直接处理模式"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap","before_compaction","after_compaction","before_reset"]}}
---

# rocky-know-how Hook v2.9.1

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 支持的事件

| 事件 | 触发时机 | 功能 |
|------|----------|------|
| agent:bootstrap | AI 启动 | 注入经验提醒 + 检查草稿（仅提醒） |
| before_compaction | 压缩前 | 保存会话状态到 .compaction-state.tmp |
| after_compaction | 压缩后 | 生成会话总结（session-summaries.md） |
| before_reset | 重置前 | **生成草稿**（drafts/draft-*.json，状态 pending_review） |

## ⚠️ v2.9.1 重大更新：直接处理模式

### 核心变化
- ❌ 不再触发 `openclaw agent`（避免队列等待）
- ✅ Hook 直接调用 LLM 判断 + 处理
- ✅ 压缩完成后立即处理，无延迟

### 工作流程（v2.9.1 直接处理）

```
第1步: before_compaction → 保存内容到 pending/
第2步: after_compaction → 直接调用 LLM 判断
    ↓
    worth=true → 生成草稿 + auto-review → 写入 experiences.md
    worth=false → 归档到 pending/archive/
第3步: before_reset → 保存内容到 pending/
```

### 为什么这样设计？
- ✅ 压缩完成立即处理，无等待
- ✅ 不依赖 Agent 队列
- ✅ 使用 GLM-4-Flash API（成本低）
- ✅ 自动过滤低价值内容

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **跨 workspace** — 支持 shared 目录和全局安装
- **数据检测** — 自动检测经验数据状态和 v2 分层存储
- **子agent跳过** — 避免重复注入
- **虚拟文件** — 不污染工作区文件
- **直接LLM判断** — 不触发新 Agent

## v2.9.1 更新

- **直接处理模式** — after_compaction 直接处理 pending，不触发 agent
- **解决队列等待** — 不依赖 Agent 队列

## 启用方式

```bash
bash install.sh
```

自动完成：目录创建 → 文件初始化 → Hook配置 → 网关重启
