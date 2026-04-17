---
name: rocky-know-how
description: "经验诀窍技能 — 失败≥2次自动搜经验诀窍，解决后写入"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap"]}}
---

# rocky-know-how Hook v1.3.0

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **跨 workspace** — 支持 shared 目录和全局安装
- **数据检测** — 自动检测经验数据是否存在
- **子agent跳过** — 避免重复注入
- **虚拟文件** — 不污染工作区文件

## 工作流程

```
1. agent:bootstrap 事件触发
2. 从 sessionKey 提取 agentId
3. 推导 workspace: ~/.openclaw/workspace-{agentId}
4. 动态搜索 scripts 目录（支持多种安装路径）
5. 检测经验数据状态
6. 注入 ROCKY_KNOW_HOW_REMINDER.md 虚拟文件
7. Agent 收到包含使用规则的上下文
```

## v1.3.0 更新

- 搜索支持 --tag / --area / 相关度排序
- record.sh 支持 --dry-run
- 新增 import.sh / archive.sh --auto 说明
- 跨 workspace 共享优化
- Dreaming 整合标记

## 启用方式

在 `openclaw.json` 中配置：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "load": {
        "extraDirs": [
          "/path/to/rocky-know-how/hooks"
        ]
      }
    }
  }
}
```

## 文件说明

- `handler.js` — 运行时 Hook 处理器（CommonJS，兼容所有 Node 版本）
- `HOOK.md` — 本文档
