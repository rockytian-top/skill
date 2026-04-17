# 📚 rocky-know-how

> OpenClaw 经验诀窍技能 — 失败自动搜，解决自动写，经验跨 agent 共享
>
> OpenClaw experience & know-how skill — auto-search on repeated failures, auto-record on success, shared across all agents.

---

## 🤔 这是什么？/ What is this?

在 AI Agent 的日常工作中，经常遇到"同一个坑踩两次"的问题——上次花了2小时排查的 Bug，下次遇到又得从头来。

rocky-know-how 解决这个问题：**当 Agent 失败≥2次时，自动搜索历史经验；解决后自动写入新经验。** 下次再碰到类似问题，直接查到答案，不再重复踩坑。

所有经验存储在全局共享文件 `~/.openclaw/.learnings/experiences.md`，所有 Agent（如你的团队里有开发、运维、测试等不同角色）都能读写同一份经验库，真正实现"一人踩坑，全团受益"。

---

In daily AI Agent workflows, the same mistakes get repeated — a bug that took 2 hours to debug last time has to be debugged from scratch again.

rocky-know-how solves this: **when an Agent fails ≥2 times, it automatically searches historical experiences; after solving, it automatically records the new experience.** Next time a similar issue arises, the answer is found instantly.

All experiences are stored in a globally shared file `~/.openclaw/.learnings/experiences.md`. Every Agent (e.g., developers, ops, testers in your team) reads and writes the same experience library — truly "one person's lesson, everyone's gain."

---

## 🔄 工作原理 / How it works

```
接到任务 → 正常执行
    ↓
失败≥2次 → 搜经验诀窍（search.sh）
    ├── 有答案 → 按答案执行，跳过弯路
    └── 没答案 → 继续尝试直到成功
    ↓
成功后 → 写入经验（record.sh）
    ├── 自动生成唯一 ID（EXP-YYYYMMDD-NNN）
    ├── 自动去重（问题文本 + Tags 组合）
    ├── 同步到 memory/*.md（原生 memory_search 可搜到）
    └── 添加 Dreaming 标记（供 Dreaming 阶段分析）
    ↓
同 Tag ≥3次 → 自动晋升到 TOOLS.md（promote.sh）
```

```
Task → Execute normally
    ↓
Failed ≥2 times → Search experiences (search.sh)
    ├── Found → Follow solution, skip the detour
    └── Not found → Keep trying until success
    ↓
Success → Record experience (record.sh)
    ├── Auto-generate unique ID (EXP-YYYYMMDD-NNN)
    ├── Auto-dedup (question text + Tags combination)
    ├── Sync to memory/*.md (searchable via native memory_search)
    └── Add Dreaming markers (for Dreaming phase analysis)
    ↓
Same Tag ≥3 times → Auto-promote to TOOLS.md (promote.sh)
```

---

## 📋 经验条目长什么样？/ What does an entry look like?

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

每条经验包含四个关键部分 / Each entry has four key parts：
- **问题 / Problem** — 一句话描述问题 / One-line problem description
- **踩坑过程 / What went wrong** — 失败了几次、每次犯了什么错 / How many failures and what went wrong
- **正确方案 / Solution** — 最终怎么解决的 / How it was finally solved
- **预防 / Prevention** — 下次如何避免 / How to prevent next time

---

## ✨ 功能特性 / Features

- 🔍 **智能搜索 / Smart Search** — 多关键词 AND 匹配 + 相关度评分排序，命中越多排越前 / Multi-keyword AND matching + relevance scoring
- 🏷️ **标签/领域筛选 / Tag & Area Filter** — `--tag` `--area` 精确匹配过滤 / Precise comma-delimited matching
- 🔄 **自动去重 / Auto Dedup** — 问题文本 + Tags 组合去重，写入时显示已有条目 / Question + Tags dedup with existing entry info
- 📝 **原生记忆同步 / Native Memory Sync** — 写入 memory/*.md，OpenClaw 原生 memory_search 可搜到 / Syncs to memory/*.md
- 🌙 **Dreaming 整合 / Dreaming Integration** — `<!-- rocky-know-how:EXP-* -->` 标记，供 Dreaming 阶段识别分析 / Markers for Dreaming phase
- 📊 **Tag 晋升 / Tag Promotion** — 30天内同一 Tag 出现≥3次，自动写入 TOOLS.md 成为铁律 / Auto-promote frequently seen Tags
- 📥 **历史导入 / Historical Import** — 从 memory/*.md 按关键词批量提取教训 / Batch import by keyword matching
- 🗄️ **自动归档 / Auto Archive** — 超过30天的条目自动归档，适合 cron 调用 / Auto-archive old entries
- 🌐 **跨 Agent 共享 / Cross-Agent Sharing** — 全局存储 `~/.openclaw/.learnings/`，所有 Agent 读写同一份 / Global shared storage

---

## 🔒 安全保障 / Security

| 措施 / Measure | 说明 / Description |
|------|------|
| 不执行系统命令 / No system commands | 只读写本地文件 / Only reads/writes local files |
| 无敏感数据 / No sensitive data | 只存储经验文本 / Only stores experience text |
| 无网络请求 / No network requests | 纯本地操作 / Pure local operations |
| 代码开源可审查 / Open source | MIT 许可证 / MIT License |
| 路径动态获取 / Dynamic paths | 不硬编码用户路径，所有用户下载即用 / No hardcoded paths |
| macOS bash 3.x 兼容 / Compatible | 不用 `=~`，不用 GNU 扩展 / No `=~`, no GNU extensions |

---

## 🚀 安装 / Installation

### ClawHub（推荐 / Recommended）
```bash
openclaw skills install rocky-know-how
```

### 手动 / Manual
```bash
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills/rocky-know-how
bash scripts/install.sh
```

安装后 Agent 启动时会自动注入使用提醒，无需手动配置。
After installation, usage reminders are automatically injected on Agent bootstrap — no manual config needed.

---

## 📖 用法 / Usage

### 搜索 / Search

```bash
# 多关键词搜索（相关度排序）/ Multi-keyword (relevance scoring)
bash scripts/search.sh "排查" "网站"

# 按标签搜索（AND逻辑，精确匹配）/ By tags (AND, exact match)
bash scripts/search.sh --tag "troubleshooting,vps"

# 按领域搜索 / By area
bash scripts/search.sh --area infra

# 摘要模式（只看问题和方案）/ Preview mode
bash scripts/search.sh --preview "关键词"

# 按日期过滤 / Date filter
bash scripts/search.sh --since 2026-04-01 "关键词"

# 查看全部 / List all
bash scripts/search.sh --all
```

### 写入 / Record

```bash
# 正常写入 / Normal
bash scripts/record.sh "问题" "踩坑过程" "正确方案" "预防措施" "tag1,tag2" "area"

# 先预览不写入 / Dry-run first
bash scripts/record.sh --dry-run "问题" "踩坑" "方案" "预防" "tags"

# area 可选值: frontend | backend | infra | tests | docs | config (默认: infra)
```

### 导入 / Import

```bash
# 从 memory/*.md 批量导入历史教训 / Batch import from memory files
bash scripts/import.sh --dry-run    # 先预览 / Preview first
bash scripts/import.sh              # 实际导入 / Import

# 指定目录 / Custom directory
bash scripts/import.sh --dir /path/to/memory --dry-run

# 添加自定义关键词 / Add custom keywords
bash scripts/import.sh --keywords "踩坑,教训,Bug" --dry-run
```

### 归档 / Archive

```bash
# 手动归档30天前的条目 / Manual archive (30 days)
bash scripts/archive.sh --dry-run   # 先预览
bash scripts/archive.sh             # 实际归档

# 自定义天数 / Custom days
bash scripts/archive.sh --days 60

# 自动模式（适合 cron/heartbeat）/ Auto mode (for cron)
bash scripts/archive.sh --auto
```

### 其他 / Other

```bash
bash scripts/stats.sh               # 统计面板 / Statistics dashboard
bash scripts/promote.sh             # Tag晋升检查 / Tag promotion check
bash scripts/clean.sh --test-dry-run # 清理测试条目 / Clean test entries
bash scripts/clean.sh --reindex      # 重新编号 / Re-index entries
```

---

## 📦 脚本列表 / Scripts

| 脚本 / Script | 说明 / Description |
|------|------|
| search.sh | 搜索经验（相关度排序、标签/领域筛选、摘要模式） / Search with scoring, tag/area filter, preview |
| record.sh | 写入经验（去重、dry-run、Dreaming标记、同步memory） / Record with dedup, dry-run, markers |
| stats.sh | 统计面板（条目数、Area/Tag分布） / Statistics dashboard |
| promote.sh | Tag晋升检查（≥3次写TOOLS.md） / Tag promotion (≥3 → TOOLS.md) |
| import.sh | 从 memory/*.md 批量导入 / Batch import from memory |
| archive.sh | 归档旧条目（手动/auto） / Archive old entries |
| clean.sh | 清理工具（测试条目/旧索引/重编号） / Cleanup utility |
| install.sh | 安装脚本（自动配置Hook） / Install (auto-configures Hook) |
| uninstall.sh | 卸载脚本 / Uninstall |

---

## 📂 存储结构 / Storage

```
~/.openclaw/.learnings/
├── experiences.md          ← 经验数据（全局共享）/ Experience data (globally shared)
└── archive/                ← 归档目录 / Archive directory
    └── YYYY-MM/            ← 按月归档 / Monthly archives

~/.openclaw/workspace-{agent}/memory/YYYY-MM-DD.md
    └── 包含 <!-- rocky-know-how:EXP-* --> 标记 / Contains markers
```

---

## 🔧 兼容性 / Compatibility

- ✅ macOS bash 3.x（不用 `=~`，不用 GNU 扩展 / No `=~`, no GNU extensions）
- ✅ Node.js 18+（CommonJS，无 TypeScript 依赖 / CommonJS, no TypeScript）
- ✅ macOS / Linux
- ✅ OpenClaw 2026.4.x+

---

## 📄 许可证 / License

[MIT License](./LICENSE)

## 🔗 链接 / Links

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
