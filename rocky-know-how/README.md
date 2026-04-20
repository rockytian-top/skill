# 📚 rocky-know-how 经验诀窍技能

> 失败自动搜，成功自动写，经验全团队共享

[![Version](https://img.shields.io/badge/version-3.0-blue.svg)](./CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🎯 解决什么问题？

AI Agent 工作中经常"同一个坑踩两次"——上次花 2 小时排查的 Bug，下次遇到又得从头来。

**rocky-know-how** 解决这个问题：
- **失败≥2次** → 自动搜索历史经验
- **成功后** → 自动写入新经验
- **经验全局共享** → 一人踩坑，全团受益

---

## 📦 目录结构

```
~/.openclaw/.learnings/
├── experiences.md      # 经验源文件（永久存储，所有 agent 共享）
├── experiences.json   # 智能缓存（1000 条经验，毫秒级搜索）
├── pending/          # 待处理的自动记录
│   └── lesson_*.json
└── archive/          # 已处理记录
    └── lesson_*.json
```

---

## 🚀 快速开始

### 1. 失败时搜索
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "SSH超时"
```

### 2. 成功后手动记录
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "SSH连接超时" \
  "排查发现是内存不足导致" \
  "卸载BT-Panel" \
  "小内存VPS不要装重型面板" \
  "ssh,vps" \
  "infra"
```

### 3. 查看缓存状态
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --cache-info
```

---

## 🔧 核心脚本

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `search.sh` | 搜索经验 | 失败时找答案 |
| `record.sh` | 手动记录 | 成功后写经验 |
| `auto-extract.sh` | 自动提取 | 从 pending 自动提取 |
| `rebuild-cache.sh` | 重建缓存 | 缓存损坏时修复 |

---

## 💡 搜索功能

```bash
# 基础搜索
bash search.sh "SSH超时"

# 摘要模式（快速预览）
bash search.sh --preview "SSH"

# 按标签搜索（AND 逻辑）
bash search.sh --tag "ssh,vps"

# 按领域搜索
bash search.sh --area infra

# 显示所有
bash search.sh --all

# 查看缓存状态
bash search.sh --cache-info
```

---

## 🧠 智能缓存 v3.0

### 设计目标
- 支持 **1000 条经验** 秒搜
- 自动淘汰低价值经验
- 版本控制，保留历史
- 混合搜索：向量40% + BM25 60%

### 评分公式
```
综合分数 = 向量相似度 × 0.4 + BM25 × 0.6
```

### 淘汰规则
- 分数 < 0.1 且 使用次数 = 0 → 淘汰
- 超过 1000 条 → 优先淘汰分数低的未使用条目

### 版本控制
- 每个经验保留 v1、v2... 多版本
- 旧版本不删除，可回退
- 示例：`EXP-20260420-ssh_timeout-v1`、`EXP-20260420-ssh_timeout-v2`

---

## 🔄 工作流程

### 自动模式（v3.0）
```
agent 完成任务
    ↓
agent:shutdown 事件触发
    ↓
自动写入 pending/ 队列
    ↓
auto-extract.sh（定时或手动）
    ↓
提取有价值内容 → experiences.md
同时更新 experiences.json 缓存
```

### 手动模式
```
失败 ≥2 次
    ↓
search.sh 搜索经验
    ↓
找到答案 → 按方案执行
没找到 → 继续排查
    ↓
成功后 record.sh 写入经验
```

---

## ⚙️ 技术细节

### 缓存结构 (experiences.json)
```json
{
  "version": "2.5",
  "maxEntries": 1000,
  "lastUpdate": "2026-04-20T12:00:00Z",
  "entries": {
    "EXP-20260420-xxx": {
      "id": "EXP-20260420-xxx",
      "problem": "问题描述",
      "solution": "解决方案",
      "tags": "ssh,vps",
      "area": "infra",
      "useCount": 5,
      "lastUsed": 1713600000,
      "created": 1713500000,
      "score": 0.85,
      "embedding": [0.1, 0.2, ...]
    }
  }
}
```

### Hook 事件监听
- `agent:bootstrap` — 注入使用提醒
- `agent:shutdown` — 记录任务结果到 pending

---

## 🔒 安全与限制

- 经验存储在 `~/.openclaw/.learnings/`，所有 agent 可读
- 子 agent（subagent）不触发自动记录，避免重复
- pending 记录只保留 7 天自动归档

---

## 📝 经验格式

```markdown
## [EXP-20260420-xxx-v1] 问题标题

**Area**: infra
**Tags**: ssh,vps
**Source**: auto-extract
**Created**: 2026-04-20T12:00:00Z
**Version**: v1

### 问题
具体问题描述...

### 解决
解决方案...

### 预防
预防措施...
```

---

## 🤔 常见问题

**Q: 搜索没结果怎么办？**
A: 说明经验库还没有这类经验，继续自己排查，成功后手动 record.sh 写入。

**Q: 缓存和源文件哪个是权威？**
A: experiences.md 是源文件，experiences.json 是缓存。缓存损坏可以 rebuild-cache.sh 重建。

**Q: 如何删除一条经验？**
A: 直接编辑 experiences.md 删除对应条目，然后 rebuild-cache.sh 更新缓存。

---

## 📚 相关文档

- [安装指南](../wiki/Installation.md)
- [使用教程](../wiki/Usage.md)
- [智能缓存](../wiki/Cache.md)
- [自动提取](../wiki/AutoExtract.md)
- [版本控制](../wiki/Versioning.md)
- [API 参考](../wiki/API.md)
- [常见问题](../wiki/FAQ.md)

---

_版本: 3.0_
_更新: 2026-04-20_
