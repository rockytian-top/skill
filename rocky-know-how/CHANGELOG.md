# CHANGELOG

## [2.4.1] - 2026-04-22

### 优化

- search.sh 恢复作为备用（memory_search 优先）
- SKILL.md 明确 memory_search 为主，search.sh 为备用

## [2.4.0] - 2026-04-22

### 架构升级

- 强制使用 memory_search 工具
- 删除 search.sh（已恢复为备用）

## [2.3.0] - 2026-04-22

### 统一数据源

- experiences.md 通过 symlink 挂载到 memory/ 目录
- memory_search 同时索引 memory/*.md + experiences.md

## [2.2.1] - 2026-04-22

### 语义搜索

- search.sh 默认启用语义搜索（SEMANTIC=true）

## [2.0.0] - 2026-04-21

### 架构重构（完全对齐 self-improving）

- 新增 **demote.sh**（30天降级）和 **compact.sh**（按层压缩）
- 新增 **boundaries.md**（安全边界）、**scaling.md**（扩展规则）
- 新增 **reflections.md**（自我反思日志）、**corrections.md**（纠正日志）
- 新增 **heartbeat-rules.md**、**heartbeat-state.md**（心跳整合）
- 新增 **index.md**（主题索引）、**memory.md**（HOT模板）
- 新增 **learning.md**（学习机制）、**operations.md**（记忆操作）
- 新增 **memory-template.md**、**setup.md**（安装指南）

### 分层存储

- HOT 层：`memory.md`（≤100行，始终加载）
- WARM 层：`domains/`、`projects/`（按需加载）
- COLD 层：`archive/`（归档）
- v1 兼容：`experiences.md`（向后兼容）

### 脚本更新

- **search.sh**：空格自动拆分关键词（`"SSH 连不上"` → 拆为2个关键词）
- **clean.sh**：reindex 逻辑重写，保留 EXP- 前缀和文件结构
- **record.sh**：支持 namespace 隔离（global/domain/project）
- **promote.sh**：Tag 频率统计，7天≥3次自动晋升 HOT
- **demote.sh**：30天未使用自动降级
- **compact.sh**：按层压缩，控制文件大小
