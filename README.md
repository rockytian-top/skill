# 📚 rocky-know-how

> OpenClaw Learning Knowledge Skill v2.8.3 — Search on failure, write after solving, learnings shared across agents

[English](./README_EN.md) | 中文

## ✨ 功能特性

### 🎯 三大核心创新（其他技能没有）

1. **🤖 自动写入机制** — 任务失败 2 次自动搜索，成功自动记录
2. **🔍 自动向量搜索** — 语义搜索 + 关键词搜索双引擎
3. **⚡ 无嵌入模型自动降级** — 检测 LM Studio，不可用自动切关键词

---

### 基础功能
- 🔍 **智能搜索** — 多关键词 AND 匹配 + 相关度评分排序 + 领域/项目过滤
- 🏷️ **标签/领域筛选** — `--tag` `--area` `--project` 精确过滤
- 🔄 **自动去重** — 问题文本 + Tags 组合去重（阈值 70%）
- 📝 **同步原生记忆** — 写入 memory/*.md，memory_search 可搜
- 🌙 **Dreaming 整合** — 标记注释，供 Dreaming 阶段分析
- 📊 **Tag晋升铁律** — 同 Tag ≥3次自动写入 TOOLS.md
- 📥 **历史导入** — 从 memory/*.md 批量提取教训
- 🗄️ **自动归档** — 超过30天自动归档，适合 cron
- 🌐 **跨 agent 共享** — 全局存储，所有 agent 通用
- 🔒 **安全加固** — 路径穿越检测、正则转义、输入验证
- ⚡ **并发安全** — 目录锁保护，多进程写入不冲突

## 🔒 安全保障

| 措施 | 说明 |
|------|------|
| ✅ 并发写入锁 | `.write_lock` 目录锁，防数据交错 |
| ✅ 输入严格验证 | ID 格式、路径、长度全检查 |
| ✅ 正则元字符转义 | FILTER_DOMAIN/FILTER_PROJECT 防注入 |
| ✅ 路径穿越检测 | `../` 和反斜杠 `\` 全面拦截 |
| 不执行系统命令 | 只读写本地文件 |
| 无敏感数据收集 | 只存储经验文本 |
| 无网络请求 | 纯本地操作 |
| 代码开源可审查 | MIT 许可证 |
| 路径动态获取 | 不硬编码用户路径 |

## 📦 脚本列表

| 脚本 | 说明 | 版本 |
|------|------|------|
| search.sh | 搜索经验（相关度排序、标签/领域/项目筛选、摘要模式） | v2.8.3 |
| record.sh | 写入经验（去重、dry-run、Dreaming标记、**并发锁**） | v2.8.3 |
| stats.sh | 统计面板（条目数、Area/Tag分布） | v2.8.3 |
| promote.sh | Tag晋升检查（≥3次自动写TOOLS.md） | v2.8.3 |
| import.sh | 从 memory/*.md 批量导入历史教训（**路径穿越修复**） | v2.8.3 |
| archive.sh | 归档旧条目（手动/auto模式） | v2.8.3 |
| clean.sh | 清理工具（测试条目/旧索引） | v2.8.3 |
| update-record.sh | 更新已有经验（**标签格式对齐**） | v2.8.3 |
| install.sh | 安装脚本（**Hook自动配置**） | v2.8.3 |
| uninstall.sh | 卸载脚本 | v2.8.3 |

## 🔧 配置

### Hook 自动配置 ✅

install.sh 会自动将 hook 路径添加到 `openclaw.json` 的 `plugins.entries`，**无需手动配置**。

配置后重启 gateway：
```bash
openclaw gateway restart
```

### 手动 Hook 配置（不推荐）

如需手动配置，在 `openclaw.json` 中添加：

```json
{
  "plugins": {
    "entries": {
      "rocky-know-how": {
        "enabled": true,
        "handler": "~/.openclaw/skills/rocky-know-how/hooks/handler.js",
        "events": ["agent:bootstrap", "before_compaction", "after_compaction", "before_reset"],
        "env": {
          "OPENCLAW_STATE_DIR": "~/.openclaw"
        }
      }
    }
  }
}
```

**注意**：
- `handler` 路径支持 `~` 展开和 `OPENCLAW_STATE_DIR` 环境变量
- 事件列表：`agent:bootstrap`、`before_compaction`、`after_compaction`、`before_reset`
- 重启网关后生效

---

## 📖 用法

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
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

安装脚本会：
1. 复制脚本到 `~/.openclaw/skills/rocky-know-how/`
2. 创建符号链接到 `~/.openclaw/.learnings/`
3. 自动配置 Hook 到 `openclaw.json`
4. 提示重启网关

---

## 📖 用法

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

## 📖 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| **2.8.3** | 2026-04-24 | 🔒 **安全加固**: H1/H2 漏洞修复 + M1 路径检测；Bug #4 修复 (memory.md 压缩)；全部脚本优化 |
| 2.8.2 | 2026-04-24 | 🔐 并发写入原子锁、Hook 路径动态化、标签格式统一、标签阈值调整、数据清理 |
| 2.8.1 | 2026-04-23 | 🔒 正则转义防注入、输入验证强化、Hook 自动配置 |
| 2.7.1 | 2026-04-21 | 支持 OpenClaw 2026.4.21 新 Hook 事件 |
| 2.5.1 | 2026-04-15 | 退回简单版，移除 hook 注入 |

### 2.8.3 详细更新

#### 🔒 安全修复 (Critical)
- **H1**: search.sh — FILTER_DOMAIN/FILTER_PROJECT 正则元字符未转义漏洞
  - 双引号转义后传入 awk -v，防止破坏脚本结构
  - 影响: `--domain`/`--project` 带特殊字符时可能导致 awk 报错或错误匹配
- **H2**: import.sh — agentId 路径穿越漏洞
  - 新增 `../` 检测，防止通过 OPENCLAW_SESSION_KEY 读取任意目录
- **M1**: search.sh — validate_name() 增加反斜杠 `\` 路径穿越检测

#### 🐛 Bug 修复
- **Bug #4** (Medium): compact.sh — memory.md 行数截断（111→18行）
- **Bug #3** (Medium): compact.sh — 压缩统计逻辑优化

#### ✨ 性能优化
- 所有脚本最后一次修改: **2026-04-24 01:10**
- memory.md 压缩至 **18 行**（≤100 行标准）

---

## 🚀 安装

## 🔗 链接

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
