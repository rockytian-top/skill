---
name: rocky-know-how
description: "经验诀窍技能 — 失败≥2次自动搜经验诀窍，解决后写入"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap"]}}
---

# rocky-know-how Hook

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **子agent跳过** — 避免重复注入
- **虚拟文件** — 不污染工作区文件

## 工作流程

```
1. agent:bootstrap 事件触发
2. 从 sessionKey 提取 agentId
3. 推导 workspace: ~/.openclaw/workspace-{agentId}
4. 注入 ROCKY_KNOW_HOW_REMINDER.md 虚拟文件
5. Agent 收到包含使用规则的上下文
```

## 注入的提醒内容

```markdown
## 📚 经验诀窍提醒 (rocky-know-how)

失败≥2次时 → 搜经验诀窍
失败≥2次后成功 → 写入经验诀窍
```

## 工作区动态获取

| sessionKey | workspace |
|------------|-----------|
| `agent:my-agent:main` | `~/.openclaw/workspace-my-agent` |
| `agent:my-agent:subagent:xxx` | 跳过（子agent） |
| `agent:main:main` | `~/.openclaw/workspace-main` |

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

然后重启 Gateway：
```bash
openclaw gateway restart
```

## 验证

```bash
openclaw hooks list | grep rocky-know-how
# 应该显示: ✓ ready
```

## 文件说明

- `handler.js` — 运行时 Hook 处理器（CommonJS，兼容所有 Node 版本）

- `HOOK.md` — 本文档