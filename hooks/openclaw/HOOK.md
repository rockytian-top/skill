---
name: rocky-know-how
description: "经验诀窍技能 Hook v2.8.3 — 对齐 OpenClaw 2026.4.21，4事件Hook集成"
metadata: {"openclaw":{"emoji":"📚","events":["agent:bootstrap","before_compaction","after_compaction","before_reset"]}}
---

# rocky-know-how Hook v2.8.3

Agent 启动时自动注入经验诀窍提醒到 bootstrap 上下文。

## 支持的事件

| 事件 | 触发时机 | 功能 |
|------|----------|------|
| agent:bootstrap | AI 启动 | 注入经验提醒 + AI 判断草稿 |
| before_compaction | 压缩前 | 分析会话，生成经验草稿 |
| after_compaction | 压缩后 | 记录会话摘要 |
| before_reset | 重置前 | 生成经验草稿 |

## 功能

- **自动注入** — agent:bootstrap 事件触发
- **动态工作区** — 自动从 sessionKey 推导 workspace 路径
- **跨 workspace** — 支持 shared 目录和全局安装
- **数据检测** — 自动检测经验数据状态和 v2 分层存储
- **子agent跳过** — 避免重复注入
- **虚拟文件** — 不污染工作区文件
- **草稿AI判断** — 下次bootstrap时AI判断是否写入经验库

## v2.8.1 更新

- **一键安装** — install.sh 自动配置4个Hook事件
- **自动重启网关** — 配置完成后自动重启使配置生效
- **修复append-record.sh** — 修正AWK逻辑，精确插入到预防之后

## v2.7.1 更新

- 支持 OpenClaw 2026.4.21 新 Hook
- 草稿生成后 AI 自动判断是否写入经验库
- 支持更新旧经验、追加新方式
- 超过3天草稿自动清理

## 工作流程

```
1. agent:bootstrap → 注入经验提醒 + AI 判断草稿
2. before_compaction → 分析会话，生成草稿
3. after_compaction → 记录会话摘要
4. before_reset → 生成经验草稿
5. 下次 bootstrap → AI 判断草稿，写入/更新/跳过
```

## 启用方式

```bash
bash install.sh
```

自动完成：目录创建 → 文件初始化 → Hook配置 → 网关重启

## 一键安装 v2.8.1

```bash
git clone <repo> ~/.openclaw/skills/rocky-know-how
bash ~/.openclaw/skills/rocky-know-how/scripts/install.sh
```
