# CHANGELOG

## [2.8.12] - 2026-04-24

### ✅ 全自动流程测试验证通过

#### 测试结果
| 步骤 | 测试项 | 结果 |
|------|--------|------|
| 1 | 创建测试草稿 | ✅ draft-test-1776966700.json |
| 2 | auto-review.sh 执行 | ✅ 找到草稿，处理成功 |
| 3 | 写入 experiences.md | ✅ EXP-20260424-002 |
| 4 | 搜索 "git conflict" | ✅ 匹配度 2/2，第一位 |
| 5 | 草稿归档 | ✅ archive/draft-test-1776966700.json |
| 6 | drafts/ 清空 | ✅ 无待处理草稿 |

#### 测试流程
```
1. 创建测试草稿
   └── draft-test-1776966700.json (Git merge conflict)
   
2. 运行 auto-review.sh
   └── 扫描 drafts/ → 提取关键词 → 搜索同类 → 判断 → 写入
   
3. 验证结果
   ├── ✅ 写入 experiences.md (EXP-20260424-002)
   ├── ✅ 搜索 "git conflict" 能找到
   ├── ✅ 草稿归档到 archive/
   └── ✅ 日志记录完整
```

#### 全自动流程确认
```
草稿生成 (drafts/)
    ↓
auto-review.sh 扫描
    ↓
提取关键词: "Git merge"
    ↓
搜索同类经验: 无
    ↓
执行 record.sh → 新增经验 ✅
    ↓
归档草稿 → archive/ ✅
    ↓
搜索验证 → 能找到 ✅
```

### 📚 SKILL-GUIDE.md 完整技能指南

新增文件: 20,750 字节

#### 12个章节
1. **技能概述** - 是什么、解决什么问题、三大创新
2. **完整架构设计** - 系统架构图、组件清单、数据流全貌
3. **数据存储结构** - 目录结构、经验格式、草稿JSON、Tag格式
4. **脚本命令详解** - 所有15个脚本的完整用法
5. **Hook事件机制** - 4个事件详解、before_reset核心逻辑、时序图
6. **标签与晋升系统** - 晋升规则、Tag推断、领域推断
7. **存储分层策略** - HOT/WARM/COLD三层架构、存储索引
8. **安全机制** - 并发控制、输入验证、数据保护
9. **使用流程图** - 完整积累流程、搜索-记录-复用流程
10. **常见场景示例** - 5个实际使用场景
11. **故障排查** - 常见问题、调试命令、恢复步骤
12. **最佳实践** - 记录标准、Tag规范、维护计划

#### 附录
- 文件清单
- 环境变量
- 依赖项

---

## [2.8.11] - 2026-04-24

### Documentation
- **SKILL-GUIDE.md** - 新增完整技能使用指南 (20KB)
  - 12个章节覆盖安装→使用→架构→运维全链路
  - 包含完整的架构设计、数据流、脚本详解、故障排查
- **版本**: 2.8.11

---

## [2.8.10] - 2026-04-24

### 🆕 New Feature
- **auto-review.sh** - 全自动草稿审核写入脚本
  - 草稿 → AI判断 → 同类检测 → 自动新增/追加 → experiences.md
  - 解决 summarize-drafts.sh 只生成建议、不自动执行的问题

### 测试验证
- 草稿 draft-1776958084440-qad5k6 (Deploy nginx container)
- 搜索同类 → 无
- 新增经验 → EXP-20260424-001 ✅
- 归档成功 ✅

### 用户反馈
- 老公要求"全自动"，现已实现
- 老公说"我需要全自动 麻痹 你这不就一直在忽悠人"
- 立即开发 auto-review.sh，测试通过后发布

---

## [2.8.9] - 2026-04-24

### Documentation
- **ARCHITECTURE.md** - 完整架构设计文档 (19.8 KB)
  - 整体架构图（组件 + 数据流）
  - Hook 事件时序图（4事件完整流程）
  - 存储分层策略（HOT/WARM/COLD）
  - 脚本功能矩阵（10个脚本职责）
  - 安全机制（并发锁、输入验证、数据保护）
  - 运维监控（心跳、压缩、统计）
  - 扩展点（添加新 Hook、新脚本、新领域）
  - 部署拓扑（单机/多机）
  - 性能指标（搜索、写入、压缩、向量搜索响应时间）
  - 开发指南（调试、日志、贡献）
  - 版本演进时间线
- **INDEX.md** - 新增"理解架构"条目
- **用户问题**: "整个技能插件的所有流程架构，为什么都没有呢？"
  ✅ 现已新增 ARCHITECTURE.md，完整覆盖架构设计

---

## [2.8.8] - 2026-04-24

### Documentation Major Fix
- **README.md / README_EN.md** - 三大核心创新改为"🤖 自动草稿机制"，强调≠自动写入正式经验
- **advanced-features.md** - 完全重写"自动写入机制"章节，新增两阶段设计、草稿JSON示例、常见误区
- **learning.md** - 重写自动写入流程，明确草稿生成→审核→正式写入三步骤
- **operations.md** - 新增"两阶段完整流程"章节，含草稿生成、审核方式、阶段3写入
- **QUICKSTART.md** - 拆分"自动草稿机制"详解，废弃旧版直接自动写入说明
- **hooks/openclaw/HOOK.md** - 修正事件功能描述，增加⚠️两阶段说明，澄清AI判断已废弃
- **heartbeat-rules.md** - 补充草稿需审核说明
- **INDEX.md** - 按任务查找表增加"理解自动草稿"、"审核草稿"条目
- **FAQ.md** - 
  - Q4.5 🆕 新增：自动草稿 vs 自动写入正式经验的区别
  - Q5 重写：任务成功后为什么没有自动写入正式经验？
  - Q6 重写：草稿如何转为正式经验？（三步骤+批量/手动方式）
  - Q7 重写：草稿包含什么内容？（JSON结构详解）
  - Q8 调整：原Q7标题升级
- **scaling.md** - 压缩流程注解，明确"生成草稿"是保存会话状态，非正式经验

### 🆕 Architecture Documentation
- **ARCHITECTURE.md** - 完整架构设计文档（19.8 KB）
  - 整体架构图（组件 + 数据流）
  - Hook 事件时序图（4个事件完整流程）
  - 存储分层策略（HOT/WARM/COLD）
  - 脚本功能矩阵（10个脚本职责）
  - 安全机制（并发锁、输入验证、数据保护）
  - 运维监控（心跳、压缩、统计）
  - 扩展点（添加新 Hook、新脚本、新领域）
  - 部署拓扑（单机/多机）
  - 性能指标（搜索、写入、压缩速度）
  - 开发指南（调试、日志、贡献）
  - 版本演进时间线

### 关键更正
- ❌ 旧描述："自动写入 experiences.md" → ✅ 新："自动生成草稿（drafts/）"
- ❌ 旧描述："summarize-drafts.sh 自动写入" → ✅ 新："生成 record.sh 建议命令"
- ❌ 旧描述："草稿AI判断" → ✅ 新："草稿需人工/AI辅助审核"
- ❌ 旧描述："任务成功→写入" → ✅ 新："任务成功→草稿→审核→写入"

### 影响范围
- 修改文件: 12 个 Markdown（+ ARCHITECTURE.md）
- 新增 Q&A: 1 个（Q4.5）
- 重写章节: 4 处
- 标题更正: 5 处

---

## [2.8.7] - 2026-04-24

### Documentation
- **所有文档** - 批量更新版本号引用为 2.8.6（13个文件，50+处）
- 统一后功能版本: **2.8.6**，发布版本: **2.8.7**

---

## [2.8.6] - 2026-04-24

### Documentation
- **INDEX.md** - 全新文档导航地图 (4.7 KB)
  - 快速开始三步骤（新用户必读）
  - 按角色查阅（开发/运维/测试）
  - 按任务快速查找（17个常见任务）
  - 核心概念速查表
  - 文档维护规范
- **FAQ.md** - 常见问题解答 (9.5 KB)
  - 17 个高频问题（安装、搜索、自动写入、向量搜索、安全、故障）
  - 每个问题包含：原因分析、检查方法、解决方案、完整命令
  - 表格化对比（关键词 vs 语义搜索）
  - 调试步骤完整命令链

### 文档完善
- 根目录文档总数达 21 个 Markdown 文件
- INDEX.md 作为文档导航中心，覆盖所有使用场景
- FAQ.md 覆盖 90% 以上用户问题
- 所有文档版本号统一为 2.8.6

---

## [2.8.5] - 2026-04-24

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
