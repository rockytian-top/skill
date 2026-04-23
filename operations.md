# 操作手册 (v2.8.3)

> 最新版本: 2026-04-24 | 兼容: OpenClaw 2026.4.x+

## 核心命令

| 命令 | 操作 | 版本 |
|------|------|------|
| `search.sh "关键词"` | 搜索经验（相关度排序） | v2.8.3 |
| `record.sh "问题" ...` | 写入经验（**并发安全**） | v2.8.3 |
| `stats.sh` | 统计面板（条目数、Tag/Area分布） | v2.8.3 |
| `promote.sh` | Tag晋升检查（≥3次→TOOLS.md） | v2.8.3 |
| `import.sh` | 从 memory 导入（**路径穿越修复**） | v2.8.3 |
| `archive.sh --auto` | 自动归档（cron/heartbeat） | v2.8.3 |
| `clean.sh` | 清理工具（测试条目/旧索引） | v2.8.3 |
| `update-record.sh` | 更新已有经验（**标签格式对齐**） | v2.8.3 |

## 自动操作

### 会话开始时

1. 加载 memory.md（HOT 层）
2. 检查 index.md 了解上下文提示
3. 检测到项目 → 预加载相关命名空间

### 收到纠正时

```
1. 解析纠正类型（偏好、模式、覆盖）
2. 检查是否重复（存在于任何层）
3. 如果新：
   - 添加到 corrections.md（带时间戳）
   - 增加纠正计数
4. 如果重复：
   - 计数+1，更新时间戳
   - 如果计数 ≥3：询问确认作为规则
5. 确定命名空间（global, domain, project）
6. 写入适当文件
7. 更新 index.md 行数
```

### 模式匹配时

应用学到的模式时：
```
1. 找到模式来源（file:line）
2. 应用模式
3. 引用来源："使用 X（来自 memory.md:15）"
4. 记录使用（用于衰减跟踪）
```

### 循环维护（心跳）

```
1. 扫描所有文件查找衰减候选
2. 移动 30天+ 未使用的到 WARM
3. 归档 90天+ 未使用的到 COLD
4. 如果任何文件超限则运行压缩
5. 更新 index.md
6. 生成摘要（可选）
```

## 文件格式

### memory.md (HOT)

```markdown
# Self-Improving Memory

## 已确认偏好
- format: bullet points over prose (confirmed 2026-01)
- tone: direct, no hedging (confirmed 2026-01)

## 活跃模式
- "looks good" = approval to proceed (used 15x)
- single emoji = acknowledged (used 8x)

## 最近（最近7天）
- prefer SQLite for MVPs (corrected 02-14)
```

### corrections.md

```markdown
# 纠正日志

## 2026-02-15
- [14:32] Changed verbose explanation → bullet summary
  Type: communication
  Context: Telegram response
  Confirmed: pending (1/3)

## 2026-02-14
- [09:15] Use SQLite not Postgres for MVP
  Type: technical
  Context: database discussion
  Confirmed: yes (said "always")
```

### projects/{name}.md

```markdown
# Project: my-app

Inherits: global, domains/code

## 模式
- Use Tailwind (project standard)
- No Prettier (eslint only)
- Deploy via GitLab CI

## 覆盖
- semicolons: yes (覆盖 global no-semi)

## 历史
- Created: 2026-01-15
- Last active: 2026-02-15
- 纠正: 12
```

### experiences.md (v1 向后兼容)

```markdown
## [EXP-20260417-001] Mac迁移后LaunchAgent需重新注册

**Area**: infra
**Failed-Count**: ≥2
**Tags**: migration,launchctl,macOS
**Created**: 2026-04-17 23:39:29

### 问题
Mac迁移后LaunchAgent需重新注册

### 踩坑过程
迁移后网关从终端启动，关了就断

### 正确方案
执行 openclaw gateway install 重新注册 LaunchAgent

### 预防
迁移后必须检查所有 LaunchAgent 注册状态
```

## 边缘情况处理

### 检测到矛盾

```
Pattern A: "Use tabs" (global, confirmed)
Pattern B: "Use spaces" (project, corrected today)

Resolution:
1. Project overrides global → use spaces for this project
2. Log conflict in corrections.md
3. Ask: "Should spaces apply only to this project or everywhere?"
```

### 用户改变主意

```
Old: "Always use formal tone"
New: "Actually, casual is fine"

Action:
1. 归档旧模式（带时间戳）
2. 添加新模式为暂定
3. 保留归档供参考（"You previously preferred formal"）
```

### 上下文模糊

```
User says: "Remember I like X"

But which namespace?
1. Check current context (project? domain?)
2. If unclear, ask: "Should this apply globally or just here?"
3. Default to most specific active context
```
