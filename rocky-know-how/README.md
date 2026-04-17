# 📚 rocky-know-how

> OpenClaw 经验诀窍技能 — 失败自动搜，解决自动写，经验跨 agent 共享

> OpenClaw experience & know-how skill — auto-search on repeated failures, auto-record on success, shared across all agents.

---

## ✨ 功能特性 / Features

- 🔍 **智能搜索 / Smart Search** — 多关键词 AND 匹配 + 相关度评分排序 / Multi-keyword AND matching + relevance scoring
- 🏷️ **标签/领域筛选 / Tag & Area Filter** — `--tag` `--area` 精确过滤 / Precise filtering
- 🔄 **自动去重 / Auto Dedup** — 问题文本 + Tags 组合去重 / Question + Tags combination dedup
- 📝 **同步原生记忆 / Native Memory Sync** — 写入 memory/*.md，memory_search 可搜 / Syncs to memory/*.md for native search
- 🌙 **Dreaming 整合 / Dreaming Integration** — 标记注释供分析 / Annotated markers for analysis
- 📊 **Tag晋升 / Tag Promotion** — 同 Tag ≥3次自动写入 TOOLS.md / Auto-writes to TOOLS.md
- 📥 **历史导入 / Historical Import** — 从 memory/*.md 批量提取 / Batch import from memory files
- 🗄️ **自动归档 / Auto Archive** — 超过30天自动归档 / Auto-archive entries older than 30 days
- 🌐 **跨 agent 共享 / Cross-Agent Sharing** — 全局存储，所有 agent 通用 / Global storage for all agents

## 🔒 安全保障 / Security

| 措施 / Measure | 说明 / Description |
|------|------|
| 不执行系统命令 / No system commands | 只读写本地文件 / Only reads/writes local files |
| 无敏感数据 / No sensitive data | 只存储经验文本 / Only stores experience text |
| 无网络请求 / No network requests | 纯本地操作 / Pure local operations |
| 代码开源可审查 / Open source | MIT 许可证 / MIT License |
| 路径动态获取 / Dynamic paths | 不硬编码用户路径 / No hardcoded user paths |

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

## 📖 用法 / Usage

### 搜索 / Search
```bash
# 多关键词搜索（相关度排序）/ Multi-keyword search (relevance scoring)
bash scripts/search.sh "排查" "网站"

# 按标签搜索（AND逻辑）/ By tags (AND logic)
bash scripts/search.sh --tag "troubleshooting,vps"

# 按领域搜索 / By area
bash scripts/search.sh --area infra

# 摘要模式 / Preview mode
bash scripts/search.sh --preview "关键词"

# 查看全部 / List all
bash scripts/search.sh --all
```

### 写入 / Record
```bash
# 正常写入 / Normal record
bash scripts/record.sh "问题/Problem" "踩坑过程/What went wrong" "正确方案/Solution" "预防/Prevention" "tag1,tag2" "area"

# 预览不写入 / Dry-run (preview only)
bash scripts/record.sh --dry-run "问题" "踩坑" "方案" "预防" "tags"
```

**area 可选值 / area options**: `frontend` `backend` `infra` `tests` `docs` `config`（默认/default: `infra`）

### 导入/归档 / Import & Archive
```bash
# 从 memory 导入历史教训 / Import historical lessons
bash scripts/import.sh --dry-run    # 先预览 / Preview first
bash scripts/import.sh              # 实际导入 / Actual import

# 手动归档 / Manual archive
bash scripts/archive.sh --dry-run   # 先预览 / Preview
bash scripts/archive.sh             # 实际归档 / Archive

# 自动归档（适合 cron/heartbeat）/ Auto (for cron/heartbeat)
bash scripts/archive.sh --auto
```

### 其他 / Other
```bash
bash scripts/stats.sh               # 统计面板 / Statistics dashboard
bash scripts/promote.sh             # Tag晋升检查 / Tag promotion check
bash scripts/clean.sh --test-dry-run # 清理测试条目 / Clean test entries
```

## 🔄 核心循环 / Core Loop

```
接到任务 → 正常执行 / Task → Execute normally
    ↓
失败≥2次 → 搜经验诀窍 / Failed ≥2 times → Search experiences
    ├── 有答案 → 按答案执行 / Found → Follow solution
    └── 没答案 → 继续尝试 / Not found → Keep trying
    ↓
成功后 → 写入经验 / Success → Record experience
    ↓
同步到 memory/*.md → memory_search 可搜 / Sync to memory
    ↓
同Tag≥3次 → 晋升到 TOOLS.md / Same Tag ≥3 → Promote
```

## 📦 脚本列表 / Scripts

| 脚本 / Script | 说明 / Description |
|------|------|
| search.sh | 搜索经验（相关度排序、标签/领域筛选） / Search with scoring & filters |
| record.sh | 写入经验（去重、dry-run、Dreaming标记） / Record with dedup & markers |
| stats.sh | 统计面板（条目数、Area/Tag分布） / Statistics dashboard |
| promote.sh | Tag晋升检查（≥3次写TOOLS.md） / Tag promotion check |
| import.sh | 从 memory/*.md 批量导入 / Batch import from memory |
| archive.sh | 归档旧条目（手动/auto） / Archive old entries |
| clean.sh | 清理工具（测试条目/旧索引） / Cleanup utility |
| install.sh | 安装脚本 / Install script |
| uninstall.sh | 卸载脚本 / Uninstall script |

## 📂 存储结构 / Storage

```
~/.openclaw/.learnings/
├── experiences.md          ← 经验数据（全局共享）/ Experience data (globally shared)
└── archive/                ← 归档目录 / Archive directory
    └── YYYY-MM/            ← 按月归档 / Monthly archives
```

## 🔧 兼容性 / Compatibility

- ✅ macOS bash 3.x（不用 `=~`，不用 GNU 扩展 / No `=~`, no GNU extensions）
- ✅ Node.js 18+（CommonJS，无 TypeScript 依赖 / No TypeScript dependency）
- ✅ macOS / Linux
- ✅ OpenClaw 2026.4.x+

## 📄 许可证 / License

[MIT License](./LICENSE)

## 🔗 链接 / Links

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
