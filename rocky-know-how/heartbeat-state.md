# Self-Improving Heartbeat State

此文件作为 `~/.openclaw/.learnings/heartbeat-state.md` 的基线。
它只存储轻量级运行标记和维护备注。

```markdown
# Self-Improving Heartbeat State

last_heartbeat_started_at: never
last_reviewed_change_at: never
last_heartbeat_result: never

## Last actions
- none yet
```

## 规则

- 在每次心跳开始时更新 `last_heartbeat_started_at`
- 只在文件变更审查干净完成后更新 `last_reviewed_change_at`
- 保持 `last_actions` 简短和事实性
- 永不将此文件变成另一个记忆日志

## 经验诀窍检查

- 读取 `./skills/rocky-know-how/heartbeat-rules.md`
- 使用 `~/.openclaw/.learnings/heartbeat-state.md` 记录运行标记和操作备注
- 如果 `~/.openclaw/.learnings/` 内没有文件变更，返回 `HEARTBEAT_OK`
