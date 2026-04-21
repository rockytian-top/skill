# 📚 rocky-know-how

> OpenClaw 经验诀窍技能 — 失败自动搜，解决自动写，经验跨 agent 共享

[English](./README_EN.md) | 中文

## ✨ 功能特性

- 🔍 **智能搜索** — 多关键词 AND 匹配 + 相关度评分排序
- 🏷️ **标签/领域筛选** — `--tag` `--area` 精确过滤
- 🔄 **自动去重** — 问题文本 + Tags 组合去重
- 📝 **同步原生记忆** — 写入 memory/*.md，memory_search 可搜
- 🌙 **Dreaming 整合** — 标记注释，供 Dreaming 阶段分析
- 📊 **Tag晋升铁律** — 同 Tag ≥3次自动写入 TOOLS.md
- 📥 **历史导入** — 从 memory/*.md 批量提取教训
- 🗄️ **自动归档** — 超过30天自动归档，适合 cron
- 🌐 **跨 agent 共享** — 全局存储，所有 agent 通用

## 🔒 安全保障

| 措施 | 说明 |
|------|------|
| 不执行系统命令 | 只读写本地文件 |
| 无敏感数据收集 | 只存储经验文本 |
| 无网络请求 | 纯本地操作 |
| 代码开源可审查 | MIT 许可证 |
| 路径动态获取 | 不硬编码用户路径 |

## 📦 脚本列表

| 脚本 | 说明 |
|------|------|
| search.sh | 搜索经验（相关度排序、标签/领域筛选、摘要模式） |
| record.sh | 写入经验（去重、dry-run、Dreaming标记） |
| stats.sh | 统计面板（条目数、Area/Tag分布） |
| promote.sh | Tag晋升检查（≥3次自动写TOOLS.md） |
| import.sh | 从 memory/*.md 批量导入历史教训 |
| archive.sh | 归档旧条目（手动/auto模式） |
| clean.sh | 清理工具（测试条目/旧索引） |
| install.sh | 安装脚本 |
| uninstall.sh | 卸载脚本 |

## 🚀 安装

### 架构：一套安装，全团队共享

```
~/.openclaw/.learnings/          ← 数据和脚本，所有 agent 共用一份
├── experiences.md               ← 经验数据库
├── memory.md                    ← HOT 层
├── domains/                    ← 领域隔离
└── projects/                   ← 项目隔离
```

**数据只需安装一次**，所有 agent 共享同一份经验库。

**Hook 配置需要每个 agent 单独做**（如果想让 agent 在对话中自动看到"先搜经验"提醒）。

### ClawHub（推荐）
```bash
openclaw skills install rocky-know-how
```

### 手动安装
```bash
git clone https://github.com/rockytian-top/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

### Hook 自动配置 ✅

install.sh 会自动将 hook 路径添加到 `openclaw.json` 的 `extraDirs`，**无需手动配置**。

配置后重启 gateway：
```bash
openclaw gateway restart
```

如需手动配置（不推荐），参考 rocky-know-how/setup.md。

## 📖 用法

### 搜索经验
```bash
# 多关键词搜索（相关度排序）
bash scripts/search.sh "排查" "网站"

# 按标签搜索（AND逻辑）
bash scripts/search.sh --tag "troubleshooting,vps"

# 按领域搜索
bash scripts/search.sh --area infra

# 摘要模式
bash scripts/search.sh --preview "关键词"

# 查看全部
bash scripts/search.sh --all
```

### 写入经验
```bash
# 正常写入
bash scripts/record.sh "问题" "踩坑过程" "正确方案" "预防措施" "tag1,tag2" "area"

# 预览不写入
bash scripts/record.sh --dry-run "问题" "踩坑" "方案" "预防" "tags"
```

### 导入/归档
```bash
# 从 memory 导入历史教训
bash scripts/import.sh --dry-run    # 先预览
bash scripts/import.sh              # 实际导入

# 手动归档
bash scripts/archive.sh --dry-run   # 先预览
bash scripts/archive.sh             # 实际归档

# 自动归档（适合 cron/heartbeat）
bash scripts/archive.sh --auto
```

## 🔄 核心循环

```
接到任务 → 正常执行
    ↓
失败≥2次 → 搜经验诀窍（search.sh）
    ├── 有答案 → 按答案执行
    └── 没答案 → 继续尝试直到成功
    ↓
成功后 → 写入经验诀窍（record.sh）
    ↓
同步到 memory/*.md → memory_search 可搜到
    ↓
同Tag≥3次 → 晋升到 TOOLS.md（promote.sh）
```

## 📂 存储结构

```
~/.openclaw/.learnings/
├── experiences.md          ← 经验数据（全局共享）
└── archive/                ← 归档目录
    └── YYYY-MM/            ← 按月归档
```

## 🔧 兼容性

- ✅ macOS bash 3.x（不用 `=~`，不用 GNU 扩展）
- ✅ Node.js 18+（CommonJS，无 TypeScript 依赖）
- ✅ macOS / Linux
- ✅ OpenClaw 2026.4.x+

## 📄 许可证

[MIT License](./LICENSE)

## 🔗 链接

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
