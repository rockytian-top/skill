# 扩展规则 (v2.8.6)

## 规模阈值

| 规模 | 条目数 | 策略 |
|------|--------|------|
| 小 | <100 | 单一 memory.md（≤100 行），无需命名空间 |
| 中 | 100-500 | 拆分到 domains/，基本索引 |
| 大 | 500-2000 | 完整命名空间层级，积极压缩（**v2.8.6+ memory.md 自动截断**） |
| 超大 | >2000 | 按年归档，HOT 层只保留摘要 |

## 何时拆分

创建新命名空间文件当：
- 单文件超过 200 行
- 主题有 10+ 个不同纠正
- 用户明确分离上下文（"for work..."，"in this project..."）

## 压缩规则 (v2.8.6)

### 合并相似纠正

```
之前（3条）：
- [02-01] Use tabs not spaces
- [02-03] Indent with tabs
- [02-05] Tab indentation please

之后（1条）：
- Indentation: tabs (confirmed 3x, 02-01 to 02-05)
```

### 摘要冗长模式

```
之前：
- When writing emails to Marcus, use bullet points, keep under 5 items,
  no jargon, bottom-line first, he prefers morning sends

之后：
- Marcus emails: bullets ≤5, no jargon, BLUF, AM preferred
```

### 带上下文归档 (v2.8.6)

当移动到 COLD 时，保留项目上下文：
```markdown
## Archived 2026-02

### Project: old-app (inactive since 2025-08)
- Used Vue 2 patterns
- Preferred Vuex over Pinia
- CI on Jenkins (deprecated)

Reason: Project completed, patterns unlikely to apply
```

### memory.md 自动截断 (v2.8.6 Bug #4 修复)

compact.sh 完成后，自动截断 memory.md 至最新 **100 行**：
```bash
# 保留尾部 100 行
tail -100 memory.md > memory.md.tmp && mv memory.md.tmp memory.md
```

当前状态：memory.md = **18 行**（符合 ≤100 标准）✅

---

## 索引维护

`index.md` 跟踪所有命名空间：

| 文件 | 行数 | 最后更新 | 状态 |
|------|------|---------|------|
| memory.md | 18 | 2026-04-24 | HOT |
| experiences.md | 1116 | 2026-04-24 | COLD |
| domains/infra.md | 32 | 2026-04-23 | WARM |
| ... | ... | ... | ... |

---

## 压缩时机

- **手动**: 运行 `compact.sh`
- **自动**: 心跳检查（如果 memory.md >100 行）
- **会话结束**: before_reset Hook 触发

## 压缩流程 (v2.8.6)

1. 分析 experiences.md（去重、合并）
2. **生成草稿**（before_compaction Hook）
   → 保存会话状态到 `.compaction-state.tmp`
3. 压缩 experiences.md（去重 51 个条目）
4. **截断 memory.md 至 ≤100 行**（Bug #4 修复）
5. 更新 index.md
6. **记录会话总结**（after_compaction Hook）→ `session-summaries.md`

> **注意**: "生成草稿" 指保存会话上下文，不是最终经验。正式经验需通过 `record.sh` 手动写入。

---

**最后更新**: 2026-04-24 v2.8.6
```markdown
# 记忆索引

## HOT（始终加载）
- memory.md: 87 行, updated 2026-02-15

## WARM（按匹配加载）
- projects/current-app.md: 45 行
- projects/side-project.md: 23 行
- domains/code.md: 112 行
- domains/writing.md: 34 行

## COLD（归档）
- archive/2025.md: 234 行
- archive/2024.md: 189 行

Last compaction: 2026-02-01
Next scheduled: 2026-03-01
```

## 多项目模式

### 继承链

```
global (memory.md)
  └── domain (domains/code.md)
       └── project (projects/app.md)
```

### 覆盖语法

在项目文件中：
```markdown
## 覆盖
- indentation: spaces (覆盖 global tabs)
- Reason: Project eslint config requires spaces
```

### 冲突检测

加载时检查：
1. 构建继承链
2. 检测矛盾
3. 最具体优先
4. 记录冲突供后续审查

## 用户类型适应

| 用户类型 | 记忆策略 |
|---------|---------|
| 高级用户 | 积极学习，最少确认 |
| 普通用户 | 保守学习，频繁确认 |
| 团队共享 | 每用户命名空间，共享项目空间 |
| 注重隐私 | 仅本地，明确同意每个类别 |

## 恢复模式

### 上下文丢失

如果 agent 会话中丢失上下文：
1. 重新读取 memory.md
2. 检查 index.md 了解相关命名空间
3. 加载活跃项目命名空间
4. 继续恢复的模式

### 损坏恢复

如果记忆文件损坏：
1. 检查 archive/ 获取最近备份
2. 从 corrections.md 重建
3. 询问用户重新确认关键偏好
4. 记录事件用于调试
