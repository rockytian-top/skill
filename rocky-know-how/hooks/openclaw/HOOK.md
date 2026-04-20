---
name: rocky-know-how
description: "经验诀窍技能 — 失败≥2次自动搜经验诀窍，解决后写入，支持全自动提取"
metadata:
  {
    "openclaw":
      {
        "emoji": "📚",
        "events": ["agent:bootstrap", "message:received"],
      },
  }
---

# rocky-know-how Hook v1.4.1

Agent 启动时自动注入经验诀窍技能提醒，Agent 接收消息时自动记录任务输入。

## 核心原则

**遇到问题 → 搜经验 → 解决 → 记录 → 优化**

## 功能

- **失败自动搜** — agent:bootstrap 注入指令，失败≥2次时立即搜索经验
- **成功自动记** — 任务成功后立即调用 record.sh 记录经验
- **经验使用后自动评估** — 使用经验解决问题后，主动询问用户是否需要补充优化
- **自动记录** — message:received 事件触发，记录用户输入到 pending 队列
- **动态工作区** — 自动从 sessionKey 推导工作区路径
- **跨 workspace** — 支持 shared 目录和全局安装

## 工作流程

```
1. agent:bootstrap 事件
   → 注入经验诀窍使用提醒到 bootstrapFiles
   → 提醒核心原则：遇到问题 → 搜经验 → 解决 → 记录 → 优化

2. Agent 处理任务
   → 失败≥2次 → 立即执行 search.sh 搜索经验
   → 成功后 → 立即执行 record.sh 写入经验
   → 使用经验后 → 主动询问用户是否需要补充优化

3. message:received 事件
   → 记录用户输入到 pending 队列

4. 定时（每天）或手动
   → 运行 auto-extract.sh 提取经验到 experiences.md
```

## 脚本命令

- search.sh — 搜索经验
- record.sh — 记录新经验
- update.sh — 更新/优化现有经验
- stats.sh — 统计面板
- auto-extract.sh — 从 pending 提取经验

## v1.4.1 更新

- 新增：经验使用后自动评估机制
- 增强 bootstrap 提醒：模型驱动，更明确的自动执行指令
- 新增 update.sh 脚本：支持更新/优化现有经验
