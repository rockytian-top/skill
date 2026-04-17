---
name: rocky-know-how
version: 1.3.6
description: "经验诀窍技能 — 失败≥2次自动搜经验诀窍，解决后写入。支持相关度排序、标签/领域筛选、自动归档、历史导入。"
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

# rocky-know-how（经验诀窍）v1.3.0

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
    ↓         → 添加 Dreaming 标记（<!-- rocky-know-how:EXP-* -->）
    ↓
同Tag≥3次 → 晋升铁律（promote.sh）
```

## 存储

**全局共享**: `~/.openclaw/.learnings/experiences.md`
所有 agent 读写同一个文件，经验跨 agent 共享。

**Dreaming 整合**: 写入 memory 时添加 `<!-- rocky-know-how:EXP-* -->` 注释标记，Dreaming 阶段可识别分析。

## 工具脚本

| 脚本 | 用途 |
|------|------|
| `search.sh "关键词"` | 搜经验诀窍（AND多关键词，相关度排序） |
| `search.sh --tag "tag1,tag2"` | 按标签搜索（AND） |
| `search.sh --area infra` | 按领域搜索 |
| `search.sh --preview "关键词"` | 摘要模式 |
| `search.sh --all` | 查看全部 |
| `search.sh --since YYYY-MM-DD` | 按日期过滤 |
| `record.sh "问题" "踩坑" "方案" "预防" "tags" [area]` | 写入+同步到原生记忆 |
| `record.sh --dry-run ...` | 预览写入内容 |
| `stats.sh` | 统计面板 |
| `promote.sh` | Tag晋升检查 |
| `import.sh [--dir ...] [--dry-run]` | 从 memory/*.md 导入历史教训 |
| `archive.sh [--days N] [--dry-run]` | 手动归档 |
| `archive.sh --auto` | 自动归档（适合 cron） |
| `clean.sh --test/--old/--reindex` | 清理工具 |

## v1.3.0 更新内容

### 修复
- 修复 experiences.md 重复头部问题
- 修复 promote.sh 目标路径硬编码问题
- 清理测试条目

### 增强
- 搜索相关度评分排序
- 新增 `--tag` 按标签搜索
- 新增 `--area` 按领域搜索
- 写入去重增强（Tags 组合 + 问题关键词重叠）
- 去重时显示已有条目详情
- record.sh 新增 `--dry-run` 预览模式
- 新增 import.sh 从 memory 导入历史教训
- archive.sh 新增 `--auto` 自动归档模式
- 与 OpenClaw Dreaming 整合（写入标记）
- 跨 workspace 共享优化

## 兼容性

- ✅ macOS bash 3.x（不用 =~，不用 GNU 扩展）
- ✅ Node.js 18+（CommonJS，无 TypeScript 依赖）
- ✅ macOS / Linux
- ✅ 所有 OpenClaw 网关实例

## 安装

```bash
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills/rocky-know-how
bash scripts/install.sh
```
