# CHANGELOG

## [2.6.0] - 2026-04-22

### OpenClaw 2026.4.21 新 Hook 支持

- 新增 **before_compaction hook**：压缩前保存任务状态到临时文件
- 新增 **after_compaction hook**：压缩后记录会话总结到 session-summaries.md
- 新增 **before_reset hook**：重置前保存重要信息
- Hook handler: `hooks/handler.js` v2.6.0

### 去重逻辑优化

- **修复**：Tags重叠≥50% 直接拦截，无需文字相似度检查
- **原因**：中文词汇分割导致相似度计算错误
- **影响**：避免了重复经验条目的产生

### 文档更新

- 更新 README.md / README_EN.md（完整说明书）
- 更新根目录 README.md（技能库总览）
- 修正注释（60%→50%）

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

### 搜索能力增强

- 多关键词 AND 匹配 + 自动拆分空格分隔的关键词
- `--tag`（精确标签）、`--domain`（领域）、`--project`（项目）过滤
- `--all`（跨层搜索）、`--preview`（摘要模式）
- 匹配度评分排序

### 安装/卸载

- **install.sh**：自动安装到 `~/.openclaw/.learnings/scripts/`
- **uninstall.sh**：完整清理（保留数据）

## [1.3.0] - 2026-04-17

### Fixed
- experiences.md 重复头部（3→1）
- Test entry EXP-20260416-007 removed
- promote.sh 硬编码路径 → 动态检测

### Added
- search.sh 相关度评分
- search.sh --tag / --area / --preview / --since 过滤
- record.sh --dry-run 预览模式
- record.sh 增强去重（Tags组合 + 80%关键词重叠）
- record.sh Dreaming 标记同步
- import.sh 批量导入
- archive.sh --auto 自动归档
- 跨 workspace 共享优化

## [1.2.0] - 2026-04-16

### Added
- Initial release as rocky-know-how
- search.sh 多关键词搜索
- record.sh 写入经验
- stats.sh 统计面板
- promote.sh Tag 晋升
- archive.sh 手动归档
- clean.sh 清理工具
- install.sh / uninstall.sh
- handler.js Bootstrap Hook

## [1.0.0] - 2026-04-16

### Added
- Forked from pskoett/self-improving-agent v3.0.13
- Renamed to rocky-know-how（经验诀窍）
- Chinese localization
