---
name: rocky-know-how
slug: rocky-know-how
version: 2.0.0
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v2 — Aligns with self-improving. Search learnings when failing 2+ times, write after solving. Layered storage (HOT/WARM/COLD), auto-promotion/demotion, namespace isolation, corrections log, reflections, heartbeat integration."
changelog: "v2.0.0: Full architecture refactor, aligned with self-improving: layered storage, auto-promotion/demotion, namespace isolation, corrections log, reflections, heartbeat integration. New: demote.sh, compact.sh, index.md, reflections.md, corrections.md, boundaries.md, scaling.md."
metadata: {"openclaw":{"emoji":"📚","requires":{"bins":[]},"os":["darwin","linux","win32"]}}
---

## When to Use / 何时使用

- Task failed 2+ times → Search learnings (search.sh) / 任务失败 ≥2 次 → 搜经验诀窍
- Solved the problem → Write lesson (record.sh) / 解决后 → 写入经验诀窍
- Same Tag 3x in 30 days → Promote to HOT (promote.sh) / 同 Tag ≥3 次 → 自动晋升 HOT
- Task completed → Self-reflect (reflections.md) / 任务完成后 → 自我反思
- On heartbeat → Conservative maintenance (heartbeat-rules.md) / 心跳时 → 保守维护

## Architecture / 架构说明

**Learnings stored at** `~/.openclaw/.learnings/`, fully aligned with self-improving layered architecture.
**经验诀窍存储在** `~/.openclaw/.learnings/`，完全对齐 self-improving 的分层架构：

```
~/.openclaw/.learnings/
├── memory.md           # HOT: ≤100 lines, always loaded / ≤100行，始终加载
├── index.md            # Topic index (line counts) / 主题索引
├── heartbeat-state.md  # Heartbeat state / 心跳状态
├── corrections.md      # Corrections log (last 50) / 纠正日志（最近50条）
├── reflections.md      # Self-reflection log / 自我反思日志
├── domains/            # WARM: domain isolation / 领域隔离
├── projects/           # WARM: project isolation / 项目隔离
└── archive/           # COLD: archive / 归档（显式查询才加载）

~/.openclaw/.learnings/experiences.md  # v1 compatibility / v1 向后兼容
```

**Storage**: Shared across all agents / 所有 agent 共用 `~/.openclaw/.learnings/`

## Quick Reference / 快速参考

| Topic / 主题 | File |
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

## Learning Signals / 学习信号

**Auto-record learnings** → Append to `experiences.md`, sync to `corrections.md`
**经验诀窍自动记录** → 追加到 `experiences.md`，同步到 `corrections.md`

**Correction signals / 纠正信号**：
- "No, that's not right..." → Learning search missed, keep trying
- "That's wrong..." / "You need to..." → Record correction
- "Remember that I always..." → Confirm preference
- "Why do you keep..." → Identify repeated error patterns

**Learning signals / 经验信号**：
- Succeeded after 2+ failures → Write to experiences.md
- Same Tag 3x → Promote to HOT
- New tech solution effective → Record to domains/

**Ignore / 忽略**：
- One-time instructions ("do X now")
- Context-specific ("in this file...")
- Hypothetical discussions ("what if...")

## Self-Reflection / 自我反思

After completing important work, pause and evaluate / 完成重要工作后暂停评估：

1. **Did it match expectations? / 是否符合预期？** — Compare result vs intent
2. **What could be improved? / 哪里可以改进？** — Identify next improvements
3. **Is this a pattern? / 这是模式吗？** → If yes, record to `corrections.md`

**When to reflect / 何时自我反思**：
- After completing multi-step tasks
- After receiving feedback (positive or negative)
- After fixing bugs or errors
- When noticing output could be better

**Log format / 日志格式**：
```
CONTEXT: [task type / 任务类型]
REFLECTION: [what I noticed / 我注意到的]
LESSON: [what to do differently / 下次要做的不同]
```

Reflection entries follow same promotion rules: 3x successful use → Promote to HOT

## Quick Queries / 快速查询

| User says / 用户说 | Action / 操作 |
|--------|------|
| "搜经验诀窍 X" | Search all layers / 搜索所有层 (search.sh) |
| "查看所有经验" | Display experiences.md / 显示全部 |
| "最近学到了什么？" | Show last 10 from corrections.md |
| "有哪些模式？" | List memory.md (HOT) |
| "查看 [项目] 模式" | Load projects/{name}.md |
| "warm 层有什么？" | List domains/ + projects/ |
| "经验统计" | Show layer counts / 显示每层统计 |
| "忘记 X" | Delete from all layers (confirm first) |
| "导出经验" | ZIP all files |

## Memory Stats / 记忆统计

```
📊 rocky-know-how Learning Stats / 经验诀窍统计

🔥 HOT (always loaded / 始终加载):
  memory.md: X entries

🌡️ WARM (loaded on demand / 按需加载):
  domains/: X files
  projects/: X files

❄️ COLD (archived / 归档):
  archive/: X files

Learnings (v1 compatible / v1兼容):
  experiences.md: X entries
```

## Common Traps / 常见陷阱

| Trap / 陷阱 | Why it fails / 失败原因 | Better approach / 更好做法 |
|------|----------|---------|
| Learning from silence / 从沉默中学习 | Creates wrong rules | Wait for explicit correction |
| Promoting too fast / 晋升太快 | Pollutes HOT memory | Keep tentative until confirmed |
| Reading every namespace / 读取所有命名空间 | Wastes context | Load only HOT + minimal matching |
| Deleting during compaction / 压缩时删除 | Loses history | Merge, summarize, or demote |

## Core Rules / 核心规则

### 1. Learn from corrections and self-reflection / 从纠正和自我反思中学习
- Record explicit user corrections
- Record self-identified work improvements
- Never infer from silence
- Same lesson 3x → Ask user to confirm as rule

### 2. Layered storage / 分层存储
| Layer | Location | Size limit | Behavior |
|-------|----------|-----------|----------|
| HOT | memory.md | ≤100 lines | Always loaded |
| WARM | projects/, domains/ | ≤200 lines | Load on context match |
| COLD | archive/ | Unlimited | Load on explicit query |

### 3. Auto-promotion / demotion / 自动晋升/降级
- Same Tag 3x in 7 days → Promote to HOT
- Unused 30 days → Demote to WARM
- Unused 90 days → Archive to COLD
- Never delete (without asking)

### 4. Namespace isolation / 命名空间隔离
- Project patterns → `projects/{name}.md`
- Global preferences → HOT layer (memory.md)
- Domain patterns (code, infra, dev) → `domains/`
- Cross-namespace inheritance: global → domain → project

### 5. Conflict resolution / 冲突解决
When patterns conflict:
1. Most specific wins (project > domain > global)
2. Most recent wins (same level)
3. Unclear → Ask user

### 6. Compaction / 压缩
When files exceed limits:
1. Merge similar corrections into single rule
2. Archive unused patterns
3. Summarize verbose entries
4. Never lose confirmed preferences

### 7. Transparency / 透明度
- Every action from memory → Quote source: "Using X (from domains/code.md:12)"
- Weekly summary available
- Full export anytime: ZIP all files

### 8. Safety boundaries / 安全边界
See `boundaries.md` — Never store credentials, health data, or third-party info.

### 9. Graceful degradation / 优雅降级
If context limits trigger:
1. Load only memory.md (HOT)
2. Load matching namespaces on demand
3. Never fail silently — Tell user what didn't load

## Scope / 范围

This skill **only does** / 本技能**只做**：
- Learn from user corrections and self-reflection
- Store preferences in local files (`~/.openclaw/.learnings/`)
- Maintain `heartbeat-state.md` on workspace-integrated heartbeat
- Read own memory files when activated

This skill **never does** / 本技能**永不**：
- Access calendars, email, or contacts
- Make network requests
- Read files outside `~/.openclaw/.learnings/`
- Infer preferences from silence or observation
- Delete or blindly overwrite rocky-know-how memory during heartbeat cleanup
- Modify its own SKILL.md

## Data Storage / 数据存储

Local state in `~/.openclaw/.learnings/`:

- `memory.md` — HOT rules and confirmed preferences / HOT 规则和已确认偏好
- `corrections.md` — Explicit corrections and reusable lessons / 纠正日志
- `experiences.md` — v1 format learnings (backward compatible) / v1 格式经验诀窍
- `domains/` — Domain-isolated patterns / 领域隔离模式
- `projects/` — Project-isolated patterns / 项目隔离模式
- `archive/` — Decayed or dormant patterns / 归档
- `heartbeat-state.md` — Cyclic maintenance markers / 循环维护标记

---

## Feedback / 反馈

- Found it useful: `clawhub star rocky-know-how`
- Keep updated: `clawhub sync`
