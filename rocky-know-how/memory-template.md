# 记忆模板

将此结构复制到 `~/.openclaw/.learnings/memory.md` 首次使用。

```markdown
# Self-Improving Memory

## 已确认偏好
<!-- 用户确认的模式，永不衰减 -->

## 活跃模式
<!-- 观察到 3+ 次的模式，服从衰减 -->

## 最近（最近7天）
<!-- 新纠正待确认 -->
```

## 初始目录结构

首次激活时创建：

```bash
mkdir -p ~/.openclaw/.learnings/{projects,domains,archive}
touch ~/.openclaw/.learnings/{memory.md,index.md,corrections.md,heartbeat-state.md,reflections.md}
```

## 索引模板

对于 `~/.openclaw/.learnings/index.md`：

```markdown
# 记忆索引

## HOT
- memory.md: 0 行

## WARM
- （尚无命名空间）

## COLD
- （尚无归档）

Last compaction: never
```

## 纠正日志模板

对于 `~/.openclaw/.learnings/corrections.md`：

```markdown
# 纠正日志

<!-- 格式：
## YYYY-MM-DD
- [HH:MM] Changed X → Y
  Type: format|technical|communication|project
  Context: where correction happened
  Confirmed: pending (N/3) | yes | no
-->
```

## 心跳状态模板

对于 `~/.openclaw/.learnings/heartbeat-state.md`：

```markdown
# Self-Improving Heartbeat State

last_heartbeat_started_at: never
last_reviewed_change_at: never
last_heartbeat_result: never

## Last actions
- none yet
```
