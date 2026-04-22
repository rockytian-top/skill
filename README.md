# 📚 rocky-know-how

> 经验诀窍技能 — 失败自动搜，解决自动写，跨 Agent 共享

**当前版本: v2.5.1**

---

## 核心定位

**遇到问题 → 先搜经验诀窍 → 解决后写入**

大中华 AI 开发团队的核心记忆系统，完全对齐 self-improving 架构。踩过的坑不再踩第二遍。

---

## 核心功能

| 功能 | 脚本 | 说明 |
|------|------|------|
| 搜索经验 | `search.sh` | 关键词/tag/领域/语义多维搜索 |
| 写入经验 | `record.sh` | 踩坑 → 写入，去重检测 |
| 自动晋升 | `promote.sh` | 30天同Tag ≥3次 → 晋升HOT层 |
| 保守降级 | `demote.sh` | 长期未用 → 降级到COLD |
| 压缩存储 | `compact.sh` | 按层压缩，控制文件大小 |
| 清理测试 | `clean.sh` | 清理测试条目 |
| 统计面板 | `stats.sh` | 查看各层经验数量 |
| 归档管理 | `archive.sh` | 手动/自动归档 |
| 历史导入 | `import.sh` | 从 memory/*.md 导入 |
| 安装/卸载 | `install.sh` / `uninstall.sh` | 一键安装 |

---

## 分层存储架构

```
~/.openclaw/.learnings/
├── experiences.md       # 主经验数据库
├── memory.md           # 🔥 HOT: 活跃经验
├── corrections.md      # 纠正日志
├── domains/            # 🌡️ WARM: 领域隔离
├── projects/          # 🌡️ WARM: 项目隔离
└── archive/           # ❄️ COLD: 归档
```

---

## 核心循环

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
同Tag≥3次/30天 → 晋升到 HOT 层（promote.sh）
```

---

## 安装

```bash
# ClawHub（推荐）
openclaw skills install rocky-know-how

# 或手动
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

---

## 快速开始

**搜索经验**：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "关键词"
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --tag "nginx,troubleshooting"
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --area infra
```

**写入经验**：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "问题标题" \
  "踩坑过程" \
  "正确方案" \
  "预防措施" \
  "tag1,tag2" \
  "area"
```

**查看统计**：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/stats.sh
```

---

## 与 self-improving 的区别

| | self-improving | rocky-know-how |
|--|---------------|----------------|
| **架构** | 纯文档，靠 agent 自觉 | 脚本强制，格式统一 |
| **搜索** | agent 自己理解 | 评分排序，精确匹配 |
| **容错** | 低（全靠自觉） | 高（脚本兜底） |
| **分层** | 无 | HOT/WARM/COLD |
| **晋升** | 靠 agent 写 | 自动统计 Tag 频率 |
| **工具** | 0个脚本 | 11个bash脚本 |
| **团队共享** | 各 agent 独立 | 共享 `.learnings/` |

---

## 版本历史

| 版本 | 说明 |
|------|------|
| v2.5.1 | 退回简单版，不使用hook注入 |
| v2.5.0 | 恢复exec+search.sh原版行为 |
| v2.4.1 | search.sh恢复备用，memory_search优先 |
| v2.0.0 | Full architecture refactor |

---

## 链接

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/skill)
- [Gitee](https://gitee.com/rocky_tian/skill)

---

**许可证**: MIT License
