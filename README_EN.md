# 📦 rocky-know-how

> 经验诀窍技能 — 失败自动搜，解决自动写

[English](#english) | [中文](#中文)

---

## 中文

### 核心定位

**遇到问题 → 先搜经验诀窍 → 解决后写入**

大中华 AI 开发团队的核心记忆系统，完全对齐 self-improving 架构。踩过的坑不再踩第二遍。

### 核心功能

| 功能 | 脚本 | 说明 |
|------|------|------|
| 搜索经验 | `search.sh` | 关键词/tag/域名/项目多维搜索 |
| 写入经验 | `record.sh` | 踩坑 → 写入，分全局/领域/项目三层 |
| 自动晋升 | `promote.sh` | 7天同Tag ≥3次 → 晋升HOT层 |
| 保守降级 | `demote.sh` | 30天未用 → 降级到WARM |
| 压缩存储 | `compact.sh` | 按层压缩，控制文件大小 |
| 清理测试 | `clean.sh` | 清理测试条目，精确匹配tag |
| 统计面板 | `stats.sh` | 查看各层经验数量 |
| 导入记忆 | `import.sh` | 从 memory/*.md 导入 |

### 分层存储架构

```
~/.openclaw/.learnings/
├── memory.md           # 🔥 HOT: ≤100行，始终加载
├── index.md            # 主题索引
├── heartbeat-state.md  # 心跳状态
├── corrections.md      # 纠正日志
├── reflections.md       # 自我反思
├── domains/            # 🌡️ WARM: 领域隔离（code, infra, dev）
├── projects/           # 🌡️ WARM: 项目隔离
└── archive/            # ❄️ COLD: 归档

~/.openclaw/.learnings/experiences.md  # v1 兼容格式
```

### 与 self-improving 的区别

| | self-improving | rocky-know-how |
|--|---------------|----------------|
| **架构** | 纯文档，靠 agent 自觉 | 脚本强制，格式统一 |
| **搜索** | agent 自己理解 | 评分排序，精确匹配 |
| **容错** | 低（全靠自觉） | 高（脚本兜底） |
| **分层** | 无 | HOT/WARM/COLD |
| **晋升** | 靠 agent 写 | 自动统计 Tag 频率 |
| **去重** | 无 | 自动检查重复 |
| **团队共享** | 各 agent 独立 | 共享 `.learnings/` |

### 安装

```bash
# ClawHub（推荐）
openclaw skills install rocky-know-how

# 或手动
git clone https://github.com/rockytian-top/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

### 快速开始

**遇到问题** → 搜索经验：
```bash
bash ~/.openclaw/.learnings/scripts/search.sh "Nginx 502"
bash ~/.openclaw/.learnings/scripts/search.sh --tag "nginx"
bash ~/.openclaw/.learnings/scripts/search.sh --domain infra
```

**解决问题** → 写入经验：
```bash
bash ~/.openclaw/.learnings/scripts/record.sh \
  "问题标题" \
  "踩坑过程（第1次...→第2次...→成功）" \
  "正确方案" \
  "预防措施" \
  "tag1,tag2" \
  [infra|code|dev]
```

**查看统计**：
```bash
bash ~/.openclaw/.learnings/scripts/stats.sh
```

### 晋升规则

- **7天内同 Tag ≥3次** → 自动晋升 HOT（memory.md）
- **30天未使用** → 降级到 WARM
- **90天未使用** → 归档到 COLD

### 许可证

MIT License

---

## English

### Core Feature

**Problem → Search first. Solve → Record it.**

Rocky-know-how is a team-wide experience knowledge system aligned with self-improving architecture. Once you solve a problem, record it so you never solve it twice.

### Install

```bash
# ClawHub (Recommended)
openclaw skills install rocky-know-how

# Or manual
git clone https://github.com/rockytian-top/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

### Quick Start

**Search**:
```bash
bash ~/.openclaw/.learnings/scripts/search.sh "keyword"
bash ~/.openclaw/.learnings/scripts/search.sh --tag "nginx"
```

**Record**:
```bash
bash ~/.openclaw/.learnings/scripts/record.sh \
  "Problem title" \
  "Failure process" \
  "Correct solution" \
  "Prevention" \
  "tag1,tag2" \
  [infra|code|dev]
```

### License

MIT License
