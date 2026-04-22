# rocky-know-how 经验诀窍技能库

**版本**: v2.7.0 | **适用系统**: macOS / Linux / Windows

---

## 📚 简介

rocky-know-how 是一个经验诀窍技能，帮助 AI Agent 在失败中学习、在成功后记录。

核心功能：
- 🔍 **失败≥2次时** → 自动搜索经验库
- ✍️ **问题解决后** → 自动记录到经验库
- 📊 **Tag晋升机制** → 常用经验自动升级
- 🧹 **自动清理** → 测试数据定期清理

---

## 🚀 快速开始

### 安装

```bash
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
./scripts/install.sh
```

### 核心命令

| 命令 | 用途 |
|------|------|
| `search.sh "关键词"` | 搜索经验库 |
| `record.sh "问题" "踩坑" "方案" "预防" "tags"` | 记录新经验 |
| `stats.sh` | 查看统计面板 |
| `promote.sh` | 检查Tag晋升 |
| `clean.sh` | 清理测试数据 |

---

## 📁 数据结构

```
~/.openclaw/.learnings/
├── experiences.md    # 主经验库（所有经验）
├── memory.md        # HOT层（频繁使用）
├── domains/         # WARM层（按领域分类）
├── projects/        # WARM层（按项目分类）
└── archive/         # COLD层（归档）
```

---

## 🔄 v2.7.0 更新

### 支持 OpenClaw 2026.4.21 新 Hook

| Hook | 触发时机 | 功能 |
|------|----------|------|
| `before_compaction` | 会话压缩前 | 保存当前任务状态 |
| `after_compaction` | 会话压缩后 | 记录会话总结 |
| `before_reset` | 会话重置前 | 保存重要信息 |

### 修复

- **去重逻辑优化**：Tags重叠≥50%直接拦截，避免中文词汇分割问题

---

## 📖 详细文档

- [rocky-know-how/SKILL.md](./rocky-know-how/SKILL.md) - 技能配置说明
- [rocky-know-how/README.md](./rocky-know-how/README.md) - 完整使用手册
- [rocky-know-how/setup.md](./rocky-know-how/setup.md) - 安装配置指南
- [rocky-know-how/operations.md](./rocky-know-how/operations.md) - 操作手册

---

## 🏷️ Tag 晋升规则

| 条件 | 晋升结果 |
|------|----------|
| 30天内同一Tag出现≥3次 | → HOT层 `memory.md` |

---

## 📊 统计面板

```
╔════════════════════════════════════════════╗
║  📊 rocky-know-how 经验诀窍统计面板 v2.1.0 ║
╚════════════════════════════════════════════╝

🔥 HOT (始终加载)
  memory.md: 14 条目

🌡️ WARM (按需加载)
  domains/: 3 文件
  projects/: 2 文件

❄️ COLD (归档)
  archive/: 1 文件

📚 v1 主数据 (experiences.md)
  总条目: 45
  本月新增: 45
```

---

## 🔗 相关链接

- **Gitee**: https://gitee.com/rocky_tian/skill
- **GitHub**: https://github.com/rockytian-top/skill
- **ClawHub**: https://clawhub.ai/skills/rocky-know-how

---

_最后更新: 2026-04-22 v2.7.0_
