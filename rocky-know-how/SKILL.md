---
name: rocky-know-how
slug: rocky-know-how
version: 2.0.0
homepage: https://clawhub.ai/skills/rocky-know-how
description: "经验诀窍技能 v2 — 完全对齐 self-improving 架构。失败≥2次自动搜经验诀窍，解决后写入。分层存储（HOT/WARM/COLD）、自动晋升/降级、命名空间隔离、纠正日志、自我反思、心跳整合。"
changelog: "v2.0.0: 完全重构架构，对齐 self-improving：分层存储、自动晋升/降级、命名空间隔离、纠正日志、自我反思、心跳整合。新增 demote.sh、compact.sh、index.md、reflections.md、corrections.md、boundaries.md、scaling.md。"
metadata: {"openclaw":{"emoji":"📚","requires":{"bins":[]},"os":["darwin","linux","win32"],"configPaths":["~/.openclaw/.learnings/"]}}
---

## When to Use

- 任务失败 ≥2 次 → 搜经验诀窍（search.sh）
- 解决后 → 写入经验诀窍（record.sh），同步纠正日志
- 30 天内同 Tag ≥3 次 → 自动晋升 HOT（promote.sh）
- 任务完成后 → 自我反思（reflections.md）
- 心跳时 → 保守维护（heartbeat-rules.md）

## Architecture

经验诀窍存储在 `~/.openclaw/.learnings/`，完全对齐 self-improving 的分层架构：

```
~/.openclaw/.learnings/
├── memory.md           # HOT: ≤100行，始终加载
├── index.md            # 主题索引（行数统计）
├── heartbeat-state.md  # 心跳状态
├── corrections.md      # 纠正日志（最近50条）
├── reflections.md      # 自我反思日志
├── domains/            # WARM: 领域隔离（code, infra, dev）
├── projects/           # WARM: 项目隔离
└── archive/           # COLD: 归档（显式查询才加载）

~/.openclaw/.learnings/experiences.md  # 向后兼容：v1 格式主数据文件
```

**存储路径**：所有 agent 共用 `~/.openclaw/.learnings/`（跨 agent 共享不变）

**向后兼容**：保留 experiences.md（v1 格式），新增 layered 格式存储结构

## Quick Reference

| 主题 | 文件 |
|------|------|
| 安装指南 | `setup.md` |
| 心跳状态模板 | `heartbeat-state.md` |
| 记忆模板 | `memory-template.md` |
| 心跳种子 | `HEARTBEAT.md` |
| 心跳规则 | `heartbeat-rules.md` |
| 学习机制 | `learning.md` |
| 安全边界 | `boundaries.md` |
| 扩展规则 | `scaling.md` |
| 记忆操作 | `operations.md` |
| 自我反思日志 | `reflections.md` |

## Learning Signals

**经验诀窍自动记录** → 追加到 `experiences.md`，同步到 `corrections.md`：

**纠正信号**：
- "No, that's not right..." → 搜经验诀窍未命中，继续尝试
- "That's wrong..." / "You need to..." → 记录纠正
- "Remember that I always..." → 确认偏好
- "Why do you keep..." → 识别重复错误模式

**经验信号**（成功解决问题后）：
- 失败 ≥2 次后成功 → 写入 experiences.md
- 同 Tag ≥3 次 → 晋升 HOT
- 新技术方案有效 → 记录到 domains/

**忽略**（不记录）：
- 一次性指令（"do X now"）
- 上下文特定（"in this file..."）
- 假设讨论（"what if..."）

## Self-Reflection

完成重要工作后，暂停并评估：

1. **是否符合预期？** — 对比结果与意图
2. **哪里可以改进？** — 识别下次改进点
3. **这是模式吗？** → 是则记录到 `corrections.md`

**何时自我反思**：
- 完成多步骤任务后
- 收到反馈（正面或负面）后
- 修复 Bug 或错误后
- 注意到输出可以更好时

**日志格式**：
```
CONTEXT: [任务类型]
REFLECTION: [我注意到的]
LESSON: [下次要做的不同]
```

**示例**：
```
CONTEXT: 排查 Mac 迁移后网关断连
REFLECTION: 从终端启动正常，但从 LaunchAgent 启动失败
LESSON: 迁移后必须检查 LaunchAgent 注册状态
```

自我反思条目遵循相同晋升规则：3x 成功应用 → 晋升 HOT。

## Quick Queries

| 用户说 | 操作 |
|--------|------|
| "搜经验诀窍 X" | 搜索所有层（search.sh） |
| "查看所有经验" | 显示 experiences.md 全部 |
| "最近学到了什么？" | 显示最近10条从 corrections.md |
| "有哪些模式？" | 列出 memory.md (HOT) |
| "查看 [项目] 模式" | 加载 projects/{name}.md |
| "warm 层有什么？" | 列出 domains/ + projects/ 文件 |
| "经验统计" | 显示每层条数统计 |
| "忘记 X" | 从所有层删除（先确认） |
| "导出经验" | ZIP 所有文件 |

## Memory Stats

执行 "经验统计" 时报告：

```
📊 rocky-know-how 经验诀窍统计

🔥 HOT (始终加载):
  memory.md: X 条目

🌡️ WARM (按需加载):
  domains/: X 文件
  projects/: X 文件

❄️ COLD (归档):
  archive/: X 文件

经验诀窍 (v1兼容):
  experiences.md: X 条

最近7天:
  新纠正: X
  晋升到HOT: X
  降级到WARM: X
```

## Common Traps

| 陷阱 | 为什么失败 | 更好做法 |
|------|----------|---------|
| 从沉默中学习 | 创建错误规则 | 等待明确纠正或重复证据 |
| 晋升太快 | 污染 HOT 记忆 | 保持新教训暂定直到重复确认 |
| 读取每个命名空间 | 浪费 context | 只加载 HOT + 最小的匹配文件 |
| 压缩时删除 | 失去信任和历史 | 合并、摘要或降级 |

## Core Rules

### 1. 从纠正和自我反思中学习
- 记录用户明确纠正的内容
- 记录自己识别出的工作改进
- 绝不从沉默中推断
- 3次相同教训 → 询问确认作为规则

### 2. 分层存储
| 层 | 位置 | 大小限制 | 行为 |
|----|------|---------|------|
| HOT | memory.md | ≤100行 | 始终加载 |
| WARM | projects/, domains/ | ≤200行 | 按 context 匹配加载 |
| COLD | archive/ | 不限 | 显式查询才加载 |

### 3. 自动晋升/降级
- 7天内同 Tag 出现 3次 → 晋升 HOT
- 30天未使用 → 降级到 WARM
- 90天未使用 → 归档到 COLD
- 永不删除（不询问不删除）

### 4. 命名空间隔离
- 项目模式保持在 `projects/{name}.md`
- 全局偏好 → HOT 层（memory.md）
- 领域模式（code, infra, dev）→ `domains/`
- 跨命名空间继承：global → domain → project

### 5. 冲突解决
当模式矛盾时：
1. 最具体优先（project > domain > global）
2. 最新优先（同级）
3. 不明确 → 询问用户

### 6. 压缩
当文件超过限制：
1. 合并相似纠正为单一规则
2. 归档未使用模式
3. 摘要冗长条目
4. 永不丢失已确认偏好

### 7. 透明度
- 每次从记忆行动 → 引用来源："使用 X（来自 domains/code.md:12）"
- 每周摘要可用：学到的模式、降级的、归档的
- 随时完整导出：所有文件 ZIP

### 8. 安全边界
参见 `boundaries.md` — 永不存储凭证、健康数据、第三方信息。

### 9. 优雅降级
如果 context 限制触发：
1. 只加载 memory.md（HOT）
2. 按需加载相关命名空间
3. 永不静默失败 — 告知用户未加载什么

## Scope

本技能**只做**：
- 从用户纠正和自我反思中学习
- 在本地文件存储偏好（`~/.openclaw/.learnings/`）
- 在 workspace 整合心跳时维护 `heartbeat-state.md`
- 激活时读取自己的记忆文件

本技能**永不**：
- 访问日历、邮件或联系人
- 发出网络请求
- 读取 `~/.openclaw/.learnings/` 以外的文件
- 从沉默或观察中推断偏好
- 在心跳清理期间删除或盲目重写 rocky-know-how 记忆
- 修改自己的 SKILL.md

## Data Storage

本地状态在 `~/.openclaw/.learnings/`：

- `memory.md` — HOT 规则和已确认偏好
- `corrections.md` — 明确纠正和可复用教训
- `experiences.md` — v1 格式经验诀窍（向后兼容）
- `domains/` — 领域隔离模式
- `projects/` — 项目隔离模式
- `archive/` — 衰减或休眠模式
- `heartbeat-state.md` — 循环维护标记

---

## 反馈

- 有用的话：`clawhub star rocky-know-how`
- 保持更新：`clawhub sync`
