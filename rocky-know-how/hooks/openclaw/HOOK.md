---
name: rocky-know-how
description: "经验诀窍技能 Hook v2.0.0 — 完全对齐 self-improving 架构"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap"]}}
---

# rocky-know-how Hook v2.0.0

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **跨 workspace** — 支持 shared 目录和全局安装
- **数据检测** — 自动检测经验数据状态和 v2 分层存储
- **子agent跳过** — 避免重复注入
- **虚拟文件** — 不污染工作区文件

## v2.0.0 更新

- 完全对齐 self-improving 架构
- 新增 WARM/COLD 分层存储支持
- 心跳状态自动追踪
- 跨 agent 共享 `.learnings/` 目录

## 工作流程

```
1. agent:bootstrap 事件触发
2. 从 sessionKey 提取 agentId
3. 推导 workspace: ~/.openclaw/workspace-{agentId}
4. 动态搜索 scripts 目录（支持多种安装路径）
5. 检测经验数据状态（v1 experiences.md / v2 layered）
6. 注入经验诀窍使用规则到上下文
```

## 启用方式

install.sh 会自动完成配置（添加到 extraDirs），无需手动操作。

如需手动启用，在 openclaw.json 的 hooks.internal.load.extraDirs 中添加本 hooks 目录路径。
