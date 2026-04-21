# 心跳规则

使用心跳保持 `~/.openclaw/.learnings/` 有序，不会产生混乱或丢失数据。

## 真实来源

保持 workspace `HEARTBEAT.md` 片段最小化。
将本文件视为 rocky-know-how 心跳行为的稳定契约。
只将可变运行状态存储在 `~/.openclaw/.learnings/heartbeat-state.md`。

## 每次心跳开始

1. 确保 `~/.openclaw/.learnings/heartbeat-state.md` 存在。
2. 立即以 ISO 8601 格式写入 `last_heartbeat_started_at`。
3. 读取之前的 `last_reviewed_change_at`。
4. 扫描 `~/.openclaw/.learnings/` 中该时刻之后变更的文件，排除 `heartbeat-state.md` 本身。

## 如果没有变更

- 设置 `last_heartbeat_result: HEARTBEAT_OK`
- 如果保持操作日志，追加简短的"无实质性变更"备注
- 返回 `HEARTBEAT_OK`

## 如果有变更

只做保守组织：

- 如果计数或文件引用有漂移，刷新 `index.md`
- 通过合并重复或摘要冗余条目来压缩超限文件
- 只有在目标明确无歧义时才将明显放错位置的笔记移动到正确命名空间
- 完全保留已确认规则和明确纠正
- 只在审查干净完成后更新 `last_reviewed_change_at`

## 安全规则

- 大多数心跳运行应该什么都不做
- 优先追加、摘要或索引修复，而非大规模重写
- 永不删除数据、清空文件或覆盖不确定文本
- 永不重组 `~/.openclaw/.learnings/` 以外的文件
- 如果范围模糊，将文件保持不动，转而记录建议的后续行动

## 状态字段

保持 `~/.openclaw/.learnings/heartbeat-state.md` 简单：

- `last_heartbeat_started_at`
- `last_reviewed_change_at`
- `last_heartbeat_result`
- `last_actions`

## 行为标准

心跳存在是为了保持记忆系统整洁和可信赖。
如果没有规则被明确违反，什么都不做。
