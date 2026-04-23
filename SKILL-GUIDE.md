# 📚 rocky-know-how 技能完全使用指南

> 版本: 2.8.10  
> 最后更新: 2026-04-24  
> 维护人: 大颖 (fs-daying)

---

## 📋 目录

1. [技能概述](#1-技能概述)
2. [完整架构设计](#2-完整架构设计)
3. [数据存储结构](#3-数据存储结构)
4. [脚本命令详解](#4-脚本命令详解)
5. [Hook 事件机制](#5-hook-事件机制)
6. [标签与晋升系统](#6-标签与晋升系统)
7. [存储分层策略](#7-存储分层策略)
8. [安全机制](#8-安全机制)
9. [使用流程图](#9-使用流程图)
10. [常见场景示例](#10-常见场景示例)
11. [故障排查](#11-故障排查)
12. [最佳实践](#12-最佳实践)

---

## 1. 技能概述

### 1.1 是什么

`rocky-know-how` 是一个**经验积累技能**，用于在 OpenClaw 多 Agent 团队中自动收集、整理、和复用解决问题的经验。

### 1.2 核心问题解决

| 问题 | 解决方案 |
|------|----------|
| "这个问题我之前解决过，怎么想不起来了" | 自动搜索相似经验 |
| "这个坑踩过一次又踩第二次" | 记录踩坑过程，下次自动提醒 |
| "团队成员各自踩坑，信息不互通" | 共享经验库，所有 Agent 可读 |
| "经验太多难以查找" | 标签系统 + 向量搜索 |
| "过时经验堆积" | 自动归档 + 分层存储 |

### 1.3 三大核心创新

1. **🤖 自动草稿机制** - Hook 自动生成草稿，无需人工记录
2. **🔍 向量搜索** - 基于语义理解，不是简单的关键词匹配
3. **📈 自动晋升** - 频繁使用的经验自动升级为快速访问

### 1.4 与其他技能的区别

| 技能 | 职责 | 数据位置 |
|------|------|----------|
| `rocky-know-how` | **经验积累** | `~/.openclaw/.learnings/` |
| `rocky-memory-tracker` | 记忆追踪 | 内存/会话 |
| `rocky-self-iteration` | 自我迭代 | 代码变更 |
| `rocky-activity-logger` | 活动记录 | 日志文件 |

---

## 2. 完整架构设计

### 2.1 系统架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                         OpenClaw Gateway                            │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   Session Manager                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │   Agent A   │  │   Agent B   │  │   Agent C   │         │  │
│  │  │ (大杰)      │  │ (大梅)      │  │ (大青)      │         │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                            │                                          │
│  ┌─────────────────────────┴──────────────────────────────────────┐ │
│  │               Plugin System (Hook Engine)                     │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  rocky-know-how Handler                                 │ │ │
│  │  │  • agent:bootstrap    - 启动时注入经验提醒               │ │ │
│  │  │  • before_compaction  - 保存会话状态                    │ │ │
│  │  │  • after_compaction   - 记录会话总结                    │ │ │
│  │  │  • before_reset       - 生成草稿（核心）                │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 Shared Data Directory (~/.openclaw/.learnings/)    │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  📁 experiences.md       ← 主经验库                            ││
│  │  📁 memory.md            ← HOT层（最近7天，≤100行）              ││
│  │  📁 domains/             ← WARM层（领域隔离）                    ││
│  │  ├── drafts/             ← 草稿（pending_review）                ││
│  │  │   └── archive/        ← 已处理草稿归档                       ││
│  │  ├── vectors/            ← 向量索引（LM Studio 可用时）         ││
│  │  └── index.md            ← 存储索引                             ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 组件清单

| 组件 | 类型 | 路径 | 职责 |
|------|------|------|------|
| `handler.js` | Hook处理器 | `hooks/openclaw/handler.js` | 响应4个Hook事件 |
| `auto-review.sh` | 审核脚本 | `scripts/auto-review.sh` | 全自动草稿审核 |
| `record.sh` | 记录脚本 | `scripts/record.sh` | 写入新经验 |
| `search.sh` | 搜索脚本 | `scripts/search.sh` | 搜索经验 |
| `summarize-drafts.sh` | 汇总脚本 | `scripts/summarize-drafts.sh` | 扫描草稿生成建议 |
| `append-record.sh` | 追加脚本 | `scripts/append-record.sh` | 追加到已有经验 |
| `update-record.sh` | 更新脚本 | `scripts/update-record.sh` | 更新已有经验 |
| `promote.sh` | 晋升脚本 | `scripts/promote.sh` | Tag晋升到HOT |
| `demote.sh` | 降级脚本 | `scripts/demote.sh` | 降级到COLD |
| `compact.sh` | 压缩脚本 | `scripts/compact.sh` | 压缩去重 |
| `archive.sh` | 归档脚本 | `scripts/archive.sh` | 归档旧数据 |
| `stats.sh` | 统计脚本 | `scripts/stats.sh` | 显示统计 |
| `clean.sh` | 清理脚本 | `scripts/clean.sh` | 清理垃圾数据 |
| `import.sh` | 导入脚本 | `scripts/import.sh` | 导入历史教训 |

### 2.3 数据流全貌

```
用户会话流程：

1. 用户发起任务
   User: "Nginx 502 怎么修复？"
   ↓
2. Agent 尝试解决
   Agent: 尝试方案A → 失败
   Agent: 尝试方案B → 失败
   Agent: 尝试方案C → 成功
   ↓
3. 会话结束 / 压缩（before_reset Hook 触发）
   ↓
4. handler.js 自动提取：
   - task: "修复 Nginx 502"
   - tools: ["search.sh", "edit", "exec"]
   - errors: ["502 Bad Gateway", "php-fpm 连接超时"]
   ↓
5. 生成草稿 JSON → drafts/draft-{sessionKey}.json
   状态: pending_review
   ↓
6. auto-review.sh 全自动审核：
   a) 扫描 drafts/
   b) 提取关键词: ["Nginx", "502"]
   c) 搜索同类: search.sh Nginx 502
   d) 判断: 有同类 → append | 无同类 → record
   ↓
7. 写入 experiences.md
   EXP-20260424-XXX
   ↓
8. Tag 统计
   Tag "nginx" 使用次数 +1
   如果 ≥3次/7天 → 晋升 TOOLS.md
   ↓
9. 后续搜索
   $ search.sh "502 nginx"
   → 找到这条经验 ✅
```

---

## 3. 数据存储结构

### 3.1 目录结构

```
~/.openclaw/.learnings/           # 根目录（所有 agent 共享）
│
├── experiences.md                 # 主经验库（所有正式条目）
│   ## [EXP-20260424-001]
│   ### 问题
│   ### 踩坑过程
│   ### 正确方案
│   ### 预防
│   **Tags**: tag1,tag2
│   **Area**: infra
│
├── memory.md                     # HOT层（最近7天，≤100行）
│   ## 2026-04-24
│   - Tag: nginx (使用3次) → 晋升 TOOLS.md
│   - 问题: Nginx 502 修复
│
├── domains/                      # WARM层（领域隔离）
│   ├── infra.md                 # 运维: nginx, docker, redis...
│   ├── wx.newstt.md            # 公众号: ocr, wechat...
│   ├── code.md                 # 开发: php, mysql...
│   ├── global.md               # 通用: 无明确领域
│   └── test.md                 # 测试: 测试相关
│
├── projects/                     # COLD层（项目隔离，可选）
│   ├── current-app.md
│   └── side-project.md
│
├── drafts/                       # 草稿（待审核）
│   ├── draft-xxx.json         # 待处理草稿
│   └── archive/               # 已处理草稿归档
│       └── draft-xxx.json
│
├── vectors/                      # 向量索引
│   ├── index.faiss            # FAISS 索引文件
│   └── metadata.json          # ID → 内容映射
│
├── corrections.md               # 纠正记录
├── index.md                     # 存储索引
├── heartbeat-state.md           # 心跳状态
├── .write_lock                 # 并发写锁（目录）
└── .auto-review.log           # 自动审核日志
```

### 3.2 经验条目格式（experiences.md）

```markdown
## [EXP-20260424-001] Nginx 502 修复

**Area**: infra
**Failed-Count**: ≥2
**Tags**: nginx,502,php-fpm
**Created**: 2026-04-24 01:44:10
**Namespace**: global

### 问题
Nginx 502 Bad Gateway 错误

### 踩坑过程
1. 重启 nginx → 仍然 502
2. 检查 php-fpm 进程 → 发现进程消失
3. 重启 php-fpm → 恢复

### 正确方案
1. 检查 php-fpm 状态: systemctl status php-fpm
2. 如果进程消失: systemctl restart php-fpm
3. 调整 pm.max_children 避免再次崩溃

### 预防
- 定期监控 php-fpm 进程数
- 设置报警: 进程数 < 2 时通知
```

### 3.3 草稿 JSON 格式

```json
{
  "id": "draft-1776958084440-qad5k6",
  "createdAt": "2026-04-23T15:28:04.440Z",
  "sessionKey": "agent:dajie",
  "shouldCreate": true,
  "problem": "Deploy nginx container",
  "tried": "Error: bind failed: port already in use",
  "solution": "解决方案待补充",
  "tags": ["nginx", "error", "draft"],
  "area": "infra",
  "status": "pending_review",
  "reviewedAt": "2026-04-23T15:31:13Z"
}
```

### 3.4 Tag 格式

```
格式: 小写字母、数字、连字符
正确: nginx, php-fpm, mysql-error
错误: Nginx（大写）, PHP Fpm（空格）, MySQL!（特殊字符）
```

---

## 4. 脚本命令详解

### 4.1 核心脚本

#### record.sh - 写入新经验

```bash
# 基本用法
bash scripts/record.sh "<问题>" "<踩坑过程>" "<正确方案>" "<预防>" "<标签>" [领域]

# 示例
bash scripts/record.sh \
  "Nginx 502 错误" \
  "重启nginx无效，检查php-fpm进程发现消失" \
  "重启php-fpm + 调整max_children" \
  "定期监控php-fpm进程数" \
  "nginx,502,php-fpm" \
  "infra"

# 选项
--dry-run          # 模拟运行，不实际写入
--namespace xxx    # 指定命名空间 (global|domain|project)
```

#### search.sh - 搜索经验

```bash
# 基本用法
bash scripts/search.sh <关键词1> [关键词2] ...

# 示例
bash scripts/search.sh nginx 502
bash scripts/search.sh "mysql connection refused"
bash scripts/search.sh --tag "nginx,docker"
bash scripts/search.sh --area infra
bash scripts/search.sh --since 2026-04-01
bash scripts/search.sh --layer hot
bash scripts/search.sh --semantic "数据库连接失败"
bash scripts/search.sh --preview "nginx"

# 选项
--all              # 显示所有经验
--preview          # 只显示摘要
--tag              # 按标签筛选
--area             # 按领域筛选
--domain           # 按命名空间筛选
--project          # 按项目筛选
--global           # 搜索所有workspace
--since            # 按日期过滤
--layer            # 按层过滤 (hot|warm|cold)
--semantic         # 语义搜索（需LM Studio）
```

#### auto-review.sh - 全自动审核（推荐 ⭐）

```bash
# 一键全自动审核所有草稿
bash scripts/auto-review.sh

# 输出示例
[2026-04-24 01:44:03] Found 1 drafts
[2026-04-24 01:44:04] Problem: Deploy nginx container
[2026-04-24 01:44:04] Tags: nginx,error,draft
[2026-04-24 01:44:04] Keywords: Deploy nginx
[2026-04-24 01:44:09] No similar found, creating new...
✅ 已写入经验诀窍: EXP-20260424-001 [infra]
Done: draft-xxx (new)
```

#### summarize-drafts.sh - 扫描草稿（半自动）

```bash
# 生成建议命令（需人工执行）
bash scripts/summarize-drafts.sh

# 输出位置
~/.openclaw/.learnings/.summarize.log

# 注意：此脚本只生成建议，不自动执行
```

#### append-record.sh - 追加到已有经验

```bash
# 用法
bash scripts/append-record.sh <经验ID> <新方式> <标签>

# 示例
bash scripts/append-record.sh \
  EXP-20260424-001 \
  "新方式: 使用 docker-compose 部署 nginx" \
  "docker,nginx"

# 注意：需要先 search.sh 找到同类经验的 ID
```

#### update-record.sh - 更新已有经验

```bash
# 用法
bash scripts/update-record.sh <经验ID> <新方案> <新预防> [新标签]

# 示例
bash scripts/update-record.sh \
  EXP-20260424-001 \
  "全新方案：使用 systemd 管理 nginx" \
  "新预防：使用 systemctl enable nginx" \
  "nginx,systemd"

# 注意：会替换原有的"正确方案"和"预防"
```

### 4.2 维护脚本

#### promote.sh - Tag 晋升

```bash
# 检查并晋升频繁使用的 Tag
bash scripts/promote.sh

# 晋升规则：7天内同一 Tag 使用 ≥3次 → 写入 TOOLS.md
```

#### demote.sh - 降级不常用经验

```bash
# 降级 30 天未使用的经验到 COLD 层
bash scripts/demote.sh
```

#### compact.sh - 压缩去重

```bash
# 压缩 experiences.md（去重 + 合并相似）
bash scripts/compact.sh

# 自动触发条件
# - memory.md > 100 行
# - experiences.md 重复率 > 50%
```

#### archive.sh - 归档旧数据

```bash
# 归档指定日期之前的经验
bash scripts/archive.sh --before 2026-03-01

# 归档到 archive/YYYY-MM/ 目录
```

#### clean.sh - 清理垃圾

```bash
# 清理测试数据
bash scripts/clean.sh --tag test

# 清理指定日期范围
bash scripts/clean.sh --since 2026-01-01 --before 2026-03-01

# 清理空经验
bash scripts/clean.sh --empty
```

#### stats.sh - 显示统计

```bash
# 显示所有统计
bash scripts/stats.sh

# 输出示例
主数据大小: 31 KB
存储路径: /Users/rocky/.openclaw/.learnings
```

#### import.sh - 导入历史

```bash
# 从 memory/ 目录导入历史教训
bash scripts/import.sh --pattern "错误|失败|问题" --area infra
```

---

## 5. Hook 事件机制

### 5.1 四个事件详解

| 事件 | 触发时机 | Handler 动作 | 输出 |
|------|----------|--------------|------|
| `agent:bootstrap` | Agent 启动 | 注入经验提醒 + 检查草稿 | 虚拟文件（会话上下文） |
| `before_compaction` | 压缩前 | 保存会话状态 | `.compaction-state.tmp` |
| `after_compaction` | 压缩后 | 生成会话总结 | `session-summaries.md` |
| `before_reset` | 重置前 | **生成草稿** | `drafts/draft-*.json` |

### 5.2 before_reset 核心逻辑

```javascript
// handler.js 关键代码
if (event.type === 'before_reset') {
  const messages = event.messages || [];
  
  // 提取关键信息
  const task = extractTask(messages);      // 用户任务
  const tools = extractTools(messages);    // 使用的工具
  const errors = extractErrors(messages);  // 遇到的错误
  
  // 只有"有任务 + 有错误"才生成草稿
  if (task && errors.length > 0) {
    const draft = {
      id: `draft-${Date.now()}-${sessionKey}`,
      problem: task,
      tried: errors.join('; '),
      solution: "待补充",
      tags: inferTags(task, tools),
      area: inferArea(task),
      status: "pending_review"
    };
    
    // 写入草稿文件
    saveDraft(draft);
  }
}
```

### 5.3 事件时序图

```
OpenClaw Session Lifecycle

Agent 启动
    ↓
┌─────────────────────┐
│ agent:bootstrap      │ ← 注入经验提醒
│ - 检查草稿（仅提醒） │
└─────────────────────┘
    ↓
正常对话 + 工具调用
    ↓
压缩开始
    ↓
┌─────────────────────┐
│ before_compaction   │ ← 保存会话状态
└─────────────────────┘
    ↓
┌─────────────────────┐
│ after_compaction    │ ← 生成会话总结
└─────────────────────┘
    ↓
会话结束 / 重置
    ↓
┌─────────────────────┐
│ before_reset        │ ← 生成草稿 ⭐
│ - 提取 task/tools   │
│ - 生成 drafts/JSON  │
└─────────────────────┘
    ↓
下次启动时
┌─────────────────────┐
│ agent:bootstrap     │ ← 提醒审核草稿
└─────────────────────┘
```

---

## 6. 标签与晋升系统

### 6.1 Tag 晋升规则

```
Tag 使用计数：
- 每次 search.sh 命中的经验，其 Tag 计数 +1
- 7 天内同一 Tag 使用 ≥3 次 → 晋升到 TOOLS.md
- 30 天未使用 → 从 TOOLS.md 移除，降级到 WARM
```

### 6.2 Tag 推断逻辑

```bash
# handler.js 中的 Tag 推断
case "$TASK" in
  *nginx*|*apache*|*web*)         AREA="infra" ;;
  *mysql*|*redis*|*mongodb*)      AREA="infra" ;;
  *docker*|*kubernetes*|*k8s*)    AREA="infra" ;;
  *公众号*|*微信*|*wechat*)       AREA="wx.newstt" ;;
  *php*|*java*|*python*)          AREA="code" ;;
  *)                               AREA="global" ;;
esac
```

### 6.3 领域推断规则

| 关键词 | 领域 |
|--------|------|
| nginx, apache, web, server | infra |
| mysql, redis, mongodb, database | infra |
| docker, k8s, kubernetes | infra |
| 公众号, 微信, wechat | wx.newstt |
| php, java, python, code | code |
| test, 测试 | test |
| 无明确匹配 | global |

---

## 7. 存储分层策略

### 7.1 三层架构

```
┌─────────────────────────────────────────────────────────────┐
│                        HOT 层                                │
│  文件: memory.md                                             │
│  大小: ≤100 行                                               │
│  内容: 最近 7 天的关键教训                                    │
│  用途: 快速访问，始终加载                                     │
│  更新: record.sh 同步写入，compact.sh 截断                    │
└─────────────────────────────────────────────────────────────┘
                              ↓ 晋升
┌─────────────────────────────────────────────────────────────┐
│                       WARM 层                                │
│  文件: domains/{area}.md                                     │
│  大小: 无限制                                                │
│  内容: 按领域分类的经验（infra, code, wx.newstt...）          │
│  用途: 中期访问，领域隔离                                     │
│  更新: record.sh 根据 area 写入对应文件                       │
└─────────────────────────────────────────────────────────────┘
                              ↓ 降级
┌─────────────────────────────────────────────────────────────┐
│                       COLD 层                                │
│  文件: archive/YYYY-MM/                                      │
│  大小: 无限制                                                │
│  内容: 超过 30 天的旧经验                                     │
│  用途: 长期归档，不占用 HOT/WARM 空间                         │
│  更新: archive.sh 定时归档                                    │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 存储索引（index.md）

```markdown
# 存储索引

## HOT 层
- memory.md (18 行, 2026-04-24 更新)

## WARM 层
- domains/infra.md (45 条)
- domains/wx.newstt.md (23 条)
- domains/code.md (12 条)
- domains/global.md (8 条)

## COLD 层
- archive/2026-03/ (156 条)
- archive/2026-02/ (89 条)

## Tag 统计
- nginx: 12 次 (最近 7 天 3 次) → 晋升中
- docker: 8 次 (最近 7 天 1 次) → 正常
```

---

## 8. 安全机制

### 8.1 并发控制

```bash
# 写锁机制（目录锁）
if mkdir "$LEARNINGS_DIR/.write_lock" 2>/dev/null; then
  # 获得锁，执行写入
  write_to_experiences
  rmdir "$LEARNINGS_DIR/.write_lock"
else
  echo "⚠️ 锁已被占用，跳过本次写入"
  exit 0
fi

# 锁等待超时: 5 秒
# 失败处理: 跳过，不阻塞
```

### 8.2 输入验证

| 漏洞类型 | 修复方式 | 脚本 |
|----------|----------|------|
| 正则注入 (H1) | 双引号转义 | search.sh |
| 路径穿越 (H2) | 检测 `../` | import.sh |
| 反斜杠穿越 (M1) | `\` 检测 | search.sh |

### 8.3 数据保护

- ✅ **去重检查**: 70% 标签重叠 → 拦截
- ✅ **草稿隔离**: `drafts/` 不参与搜索
- ✅ **日志脱敏**: 不记录密码、密钥
- ✅ **权限控制**: `.learnings/` 目录 `700`

---

## 9. 使用流程图

### 9.1 完整经验积累流程

```
用户发起任务
    ↓
Agent 尝试解决（失败 2 次）
    ↓
自动触发 search.sh（搜索类似问题）
    ↓
┌─────────────────────────────────────┐
│ 找到经验？                          │
├──────────────┬──────────────────────┤
│ 是           │ 否                    │
↓              ↓                       ↓
应用经验      继续尝试                 记录失败过程
    ↓              ↓                       ↓
成功          成功/失败           会话结束
    ↓              ↓                       ↓
结束          结束              before_reset Hook
                                   ↓
                              生成草稿 JSON
                                   ↓
                              drafts/draft-*.json
                                   ↓
                           auto-review.sh 扫描
                                   ↓
                    ┌─────────────────────────┐
                    │ 有同类经验？             │
                    ├─────────┬───────────────┤
                    │ 是      │ 否            │
                    ↓         ↓               ↓
              append      record.sh        record.sh
              record.sh   (新增)          (新增)
                    ↓         ↓               ↓
              更新已有    写入新经验       写入新经验
              经验        ↓               ↓
                    ↓    归档草稿         归档草稿
              归档草稿
```

### 9.2 搜索-记录-复用流程

```
需要解决问题
    ↓
search.sh <关键词>
    ↓
找到经验？
    ↓ 否
继续尝试解决
    ↓ 是
应用经验方案
    ↓
成功？
    ↓ 否
继续尝试（失败+1）
    ↓ 是
记录成功（可选）
    ↓
Tag 计数 +1
    ↓
7天 ≥3次？
    ↓ 是
晋升到 TOOLS.md
```

---

## 10. 常见场景示例

### 场景 1: 遇到问题，搜索经验

```bash
# 用户：Nginx 502 怎么修复？
# Agent 自动执行：
bash scripts/search.sh nginx 502

# 输出：
─── 搜索结果 (nginx, 502) ───
[EXP-20260424-001] Nginx 502 修复
Area: infra | Tags: nginx,502,php-fpm
问题: Nginx 502 Bad Gateway 错误
方案: 重启php-fpm + 调整max_children
───────────────────────────────────
```

### 场景 2: 解决问题后，记录经验

```bash
# Agent 自动记录（Hook 生成草稿）
# 或手动记录：
bash scripts/record.sh \
  "Docker 容器端口冲突" \
  "docker run -p 80:80 报错：port is already allocated" \
  "使用 docker ps | grep 80 查找占用进程，kill 后重试" \
  "部署前先检查端口占用：netstat -tulpn | grep <port>" \
  "docker,port-conflict" \
  "infra"
```

### 场景 3: 发现同类问题，追加方案

```bash
# 先搜索找到同类经验 ID
bash scripts/search.sh docker port

# 输出显示 EXP-20260421-005 是同类
# 追加新方案：
bash scripts/append-record.sh \
  EXP-20260421-005 \
  "新方式：docker-compose 指定端口映射，避免冲突" \
  "docker-compose"
```

### 场景 4: 全自动草稿审核

```bash
# 运行全自动审核
bash scripts/auto-review.sh

# 输出：
Found 2 drafts
Processing draft-xxx-1:
  Problem: MySQL 连接超时
  Keywords: MySQL connection
  Found similar: EXP-20260420-003
  Appending solution... ✅
Processing draft-xxx-2:
  Problem: Git 合并冲突
  Keywords: Git merge
  No similar found, creating new... ✅ EXP-20260424-002
```

### 场景 5: 批量清理测试数据

```bash
# 清理所有测试标签的经验
bash scripts/clean.sh --tag test

# 清理指定日期范围的垃圾
bash scripts/clean.sh --since 2026-01-01 --before 2026-03-01
```

---

## 11. 故障排查

### 11.1 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 草稿未生成 | 会话未触发 before_reset | 确认 Hook 配置正确 |
| 搜索结果为空 | 关键词不匹配 | 使用 --semantic 语义搜索 |
| 写入失败 | 锁被占用 | 等待或检查 .write_lock |
| 经验重复 | 去重逻辑阈值问题 | 调整 70% 相似度阈值 |
| Tag 未晋升 | 使用次数不足 | 确认 7 天内 ≥3 次 |

### 11.2 调试命令

```bash
# 查看 Hook 日志
tail -f ~/.openclaw/logs/gateway.log | grep rocky-know-how

# 查看自动审核日志
cat ~/.openclaw/.learnings/.auto-review.log

# 查看草稿目录
ls -la ~/.openclaw/.learnings/drafts/

# 检查 experiences.md 格式
tail -20 ~/.openclaw/.learnings/experiences.md

# 验证脚本依赖
bash scripts/auto-review.sh --check-deps

# 测试搜索功能
bash scripts/search.sh --all | head -20
```

### 11.3 恢复步骤

```bash
# 如果 experiences.md 损坏
# 1. 从 archive/ 恢复
cp ~/.openclaw/.learnings/archive/2026-03/experiences-*.md \
   ~/.openclaw/.learnings/experiences.md

# 2. 重新索引
bash scripts/compact.sh

# 如果草稿丢失
# 检查 archive/ 目录
ls ~/.openclaw/.learnings/drafts/archive/
```

---

## 12. 最佳实践

### 12.1 经验记录标准

```
✅ 好的经验：
- 问题描述清晰（什么场景/什么错误）
- 踩坑过程详细（尝试了什么/为什么失败）
- 解决方案具体（可操作、可复现）
- 预防措施明确（如何避免再次踩坑）

❌ 差的经验：
- "Nginx 出问题了" - 问题不明确
- "重启就好了" - 无踩坑过程
- "小心点" - 措施不具体
```

### 12.2 Tag 命名规范

```
✅ 推荐：
- nginx, docker, mysql
- 502-error, connection-refused
- deployment, troubleshooting

❌ 不推荐：
- Nginx（N 大写）
- PHP-FPM（特殊字符）
- 运维相关（过于笼统）
```

### 12.3 定期维护

```bash
# 每周执行
bash scripts/compact.sh       # 压缩去重
bash scripts/promote.sh       # 检查晋升
bash scripts/stats.sh         # 查看统计

# 每月执行
bash scripts/archive.sh --before $(date -v-1m +%Y-%m-%d)  # 归档旧数据
bash scripts/demote.sh        # 降级不常用
```

### 12.4 工作流集成

```bash
# 在 Agent 启动时自动检查草稿
# (已通过 Hook 自动完成)

# 在任务失败时自动搜索经验
# (已通过 Hook 自动完成)

# 在任务成功时自动生成草稿
# (已通过 before_reset Hook 自动完成)

# 定期审核草稿（建议每天）
# 手动：bash scripts/auto-review.sh
# 或配置 cron job
```

---

## 附录 A: 文件清单

| 文件 | 大小 | 说明 |
|------|------|------|
| experiences.md | ~30KB | 主经验库 |
| memory.md | ~1KB | HOT层 |
| domains/*.md | ~20KB | WARM层 |
| drafts/archive/ | ~500B | 草稿归档 |
| vectors/ | ~1MB | 向量索引 |

## 附录 B: 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| LEARNINGS_DIR | `~/.openclaw/.learnings/` | 数据根目录 |
| OPENCLAW_STATE_DIR | 自动检测 | 状态目录 |
| OPENCLAW_WORKSPACE | 自动检测 | 工作区 |

## 附录 C: 依赖项

| 依赖 | 版本 | 说明 |
|------|------|------|
| bash | 3.2+ | 脚本解释器 |
| python3 | 3.6+ | JSON 处理 |
| grep/sed/awk | GNU | 文本处理 |
| LM Studio | 可选 | 向量搜索 |

---

**最后更新**: 2026-04-24 v2.8.10  
**维护人**: 大颖 (fs-daying)  
**反馈**: https://gitee.com/rocky_tian/skill/issues
