# CHANGELOG

## [2.8.5] - 2026-04-24

### Documentation
- **advanced-features.md** - 全新高级特性文档 (13.7 KB)
  - 🤖 自动写入机制：完整触发链条、并发锁、去重、命名空间
  - 🔍 自动向量搜索：向量索引结构、语义 vs 关键词对比、LM Studio 集成
  - ⚡ 自动降级：检测机制、降级逻辑、故障排查、诊断命令
  - 三功能协同工作流（完整流程图）
  - 配置调试指南 + 性能对比表
- **README.md / README_EN.md** - 顶部突出三大核心创新（其他技能没有）

### 文档完善
- 三大核心创新功能完整技术细节
- 向量搜索: embedding 模型配置、API 测试、索引重建
- 自动降级: 3秒超时检测、降级提示、用户体验
- 并发安全: .write_lock 目录锁机制详解
- 实际场景: Nginx 502、公众号 OCR 完整流程

---

## [2.8.4] - 2026-04-24

### Security Fixes
- **search.sh** — 修复 FILTER_DOMAIN/FILTER_PROJECT 正则元字符未转义漏洞 (H1)
  - 双引号转义后传入 awk -v，防止破坏脚本结构
  - 影响范围：--domain / --project 带特殊字符时 awk 报错或错误匹配
- **import.sh** — 修复 agentId 路径穿越漏洞 (H2)
  - 新增 agentId 的 `../` 检测，防止通过 OPENCLAW_SESSION_KEY 路径穿越
  - 影响范围：恶意的 OPENCLAW_SESSION_KEY 可读取任意目录

### Security
- **search.sh** — validate_name() 增加反斜杠路径穿越检测 (M1)

## [2.8.2] - 2026-04-24

### Bug Fixes
- **record.sh** — 并发写入原子锁 (R6 fix)
  - 新增 `.write_lock` 目录锁保护 experiences.md 写入
  - 生成 ID 和写入操作分离，但写入本身有锁保护
- **search.sh** — format_all 函数健壮性增强
  - 添加 `next` 忽略无法解析的行，避免 awk 中断
  - 修复 `--all` 偶发空显示问题
- **handler.js** — OPENCLAW_STATE_DIR 环境变量支持
  - 动态使用 `OPENCLAW_STATE_DIR` 或 `~/.openclaw/` 路径
  - 修复 Hook 路径硬编码问题
- **update-record.sh** — 标签格式对齐
  - 修复 `### Tags` → `**Tags**:` 与 record.sh 格式一致
- **record.sh** — 标签去重阈值调整
  - 50% → 70%，减少误拦截
- **experiences.md** — 清理重复条目
  - 清理 51 个重复 ID，保留首次出现
  - 文件从 2231 行压缩至 1116 行

## [2.8.1] - 2026-04-23

### 安全修复
- **search.sh** — 关键词正则转义，防止正则注入 DoS
  - 新增 `escape_grep()` 函数转义特殊字符
  - 新增 `MAX_INPUT_LEN=1000` 限制输入长度
  - grep 调用全部使用转义后的关键词
- **record.sh** — 参数路径穿越验证
  - 新增 PROBLEM/TAGS/NS_VALUE 的 `..` 检测
- **experiences.md** — 清理51个重复条目，保留首次出现

### 文档
- SKILL.md 更新至 v2.8.1
- HOOK.md 更新至 v2.8.1
- CHANGELOG 更新

## [2.8.0] - 2026-04-23

### 一键安装
- **install.sh v2.8.0** — 一键安装，自动完成所有配置

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
