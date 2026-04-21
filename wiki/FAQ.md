# 常见问题

## Q: 如何让团队成员都使用？

在 AGENTS.md 中添加规则：
```
遇到问题 → 先搜经验诀窍（search.sh）
解决后 → 写入经验诀窍（record.sh）
```

## Q: 数据存在哪里？

统一在 `~/.openclaw/.learnings/`（所有 agent 共享）。

## Q: 如何导出所有经验？

```bash
zip -r learnings-backup.zip ~/.openclaw/.learnings/
```

## Q: 误删了经验怎么办？

经验只追加不删除（除非手动 clean.sh）。由于 .learnings/ 不是 git 仓库，建议定期备份：
```bash
# 备份
cp -r ~/.openclaw/.learnings ~/learnings-backup-$(date +%Y%m%d)

# 恢复
cp ~/learnings-backup-YYYYMMDD/experiences.md ~/.openclaw/.learnings/
```

## Q: 晋升规则是什么？

7天内同一 Tag 出现 ≥3 次 → 自动晋升 HOT 层（memory.md）。
