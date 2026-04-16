---
name: rocky-know-how
version: 1.2.0
description: "经验诀窍技能 — 失败≥2次自动搜经验诀窍，解决后写入。写入时同步到原生记忆。"
author: rocky
license: MIT
tags:
  - learning
  - experience
  - memory
  - self-improvement
metadata:
  openclaw:
    emoji: "📚"
    events: ["agent:bootstrap"]
---

# rocky-know-how（经验诀窍）

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
写入同时 → 同步到 memory/*.md（原生 memory_search 可搜到）
    ↓
同Tag≥3次 → 晋升铁律（promote.sh）
```

## 存储

**全局共享**: `~/.openclaw/.learnings/experiences.md`
所有 agent 读写同一个文件，经验跨 agent 共享。

## 工具脚本

| 脚本 | 用途 |
|------|------|
| `search.sh "关键词"` | 搜经验诀窍（AND多关键词） |
| `search.sh --preview "关键词"` | 摘要模式 |
| `search.sh --all` | 查看全部 |
| `record.sh "问题" "踩坑" "方案" "预防" "tags" [area]` | 写入+同步到原生记忆 |
| `stats.sh` | 统计面板 |
| `promote.sh` | Tag晋升检查 |
| `archive.sh [--days N]` | 归档旧条目 |
| `clean.sh --test/--old/--reindex` | 清理工具 |

## 安装

```bash
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills
bash scripts/install.sh
```

## 兼容性

- ✅ Node.js 18+（CommonJS，无 TypeScript 依赖）
- ✅ macOS / Linux
- ✅ 所有 OpenClaw 网关实例
