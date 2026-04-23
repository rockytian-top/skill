# 心跳规则 (v2.8.6)

## 真实来源

保持 workspace `HEARTBEAT.md` 片段最小化。
将本文件视为 rocky-know-how 心跳行为的稳定契约。
只将可变运行状态存储在 `~/.openclaw/.learnings/heartbeat-state.md`。

## 每次心跳开始 (v2.8.6)

1. 确保 `~/.openclaw/.learnings/heartbeat-state.md` 存在。
2. 立即以 ISO 8601 格式写入 `last_heartbeat_started_at`。
3. 读取之前的 `last_reviewed_change_at`。
4. 扫描 `~/.openclaw/.learnings/` 中该时刻之后变更的文件，排除 `heartbeat-state.md` 本身。
5. **新增 (v2.8.6)**: 检查 `memory.md` 行数，若 >100 则触发压缩。

## 如果没有变更

- 设置 `last_heartbeat_result: HEARTBEAT_OK`
- 如果保持操作日志，追加简短的"无实质性变更"备注
- 返回 `HEARTBEAT_OK`

## 如果有变更

只做保守组织（v2.8.6 增强）：

- 如果计数或文件引用有漂移，刷新 `index.md`
- **通过合并重复或摘要冗余条目来压缩超限文件**（v2.8.6 Bug #3 修复）
- **完成后截断 memory.md 至最新 100 行**（v2.8.6 Bug #4 修复）
- 只有在目标明确无歧义时才将明显放错位置的笔记移动到正确命名空间
- 完全保留已确认规则和明确纠正
- 只在审查干净完成后更新 `last_reviewed_change_at`
- **记录压缩统计**（压缩前/后行数）

## 安全规则 (v2.8.6)

- 大多数心跳运行应该什么都不做
- 优先追加、摘要或索引修复，而非大规模重写
- **永不删除数据、清空文件或覆盖不确定文本**
- 永不重组 `~/.openclaw/.learnings/` 以外的文件
- 如果范围模糊，将文件保持不动，转而记录建议的后续行动
- **新增**: 压缩前触发 `before_compaction` Hook 保存会话状态（生成草稿前身）
- **注意**: Hook 生成的草稿（drafts/）需审核后才写入正式经验，非自动写入

## 状态字段

保持 `~/.openclaw/.learnings/heartbeat-state.md` 简单：

```yaml
last_heartbeat_started_at: 2026-04-24T01:15:00+08:00
last_reviewed_change_at: 2026-04-24T01:10:00+08:00
last_heartbeat_result: COMPACTED  # or OK, ERROR
last_actions:
  - compacted memory.md (111→18 lines)
  - deduped experiences.md (51 duplicates removed)
```

## 行为标准

心跳存在是为了保持记忆系统整洁和可信赖。
如果没有规则被明确违反，**什么都不做**。

---

**版本**: 2.8.3
**最后更新**: 2026-04-24
**关键修复**: Bug #3/Bug #4 (压缩逻辑)、Hook 事件集成
