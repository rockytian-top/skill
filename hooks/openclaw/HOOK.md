---
name: rocky-know-how
description: "经验诀窍技能 Hook v2.9.2 — LLM双判断全自动闭环"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap","before_compaction","after_compaction","before_reset"]}}
---

# rocky-know-how Hook v2.9.2

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 支持的事件

| 事件 | 触发时机 | 功能 |
|------|----------|------|
| agent:bootstrap | AI 启动 | 注入经验提醒 |
| before_compaction | 压缩前 | 提取task/tools/errors保存到pending/ + autoSearch注入相关经验 |
| after_compaction | 压缩后 | LLM判断worth→生成草稿→LLM判断create/append→写入experiences→归档 |
| before_reset | 重置前 | 保存pending（兜底） |

## v2.9.2 全自动闭环流程

### 核心：两次 LLM 判断

```
before_compaction → 提取原始上下文 → pending/*.json
压缩发生
after_compaction → 处理 pending
    ├── LLM1 callLLMJudge() — worth=true/false?
    │       输入: task + tools + errors
    │
    ├── worth=true → 生成草稿 drafts/draft-*.json
    │       ├── searchSimilarExperiences() — 搜索相似经验读全文
    │       └── LLM2 decideCreateOrAppend() — create 还是 append?
    │               输入: 草稿全文 + 相似经验全文（最多3条）
    │
    ├── append → append-record.sh → experiences.md
    ├── create → record.sh → experiences.md
    │
    ├── 归档 draft → drafts/archive/
    └── 归档 pending → pending/archive/
```

### LLM1 判断标准（是否值得写）
- 有实际操作(工具调用) + 有问题或解决方案 → worth=true
- 只有闲聊、无关内容 → worth=false

### LLM2 判断标准（新增还是追加）
- 问题本质相同/高度相似 → append（补充新解决方案）
- 问题独特，无类似经验 → create（新增经验）
- 追加时自动优化 solution 和 prevention

### 为什么这样设计？
- ✅ 压缩前提取原始上下文，不丢失信息
- ✅ 两次 LLM 判断，确保写入质量
- ✅ 直接处理，不依赖 Agent 队列
- ✅ 自动归档，drafts/ 不膨胀

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **跨 workspace** — 支持 shared 目录和全局安装
- **LLM 双判断** — worth 判断 + create/append 判断
- **自动归档** — draft 和 pending 处理后均归档
- **降级策略** — 无 LLM 配置时退回到关键词判断

## 启用方式

```bash
bash install.sh
```

自动完成：目录创建 → 文件初始化 → Hook配置 → 网关重启
