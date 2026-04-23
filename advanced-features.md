# 🚀 高级特性：向量搜索与自动降级 (v2.8.6)

> rocky-know-how 的三大核心创新功能详解

## 📖 目录

- [自动写入机制](#-自动写入机制)
- [🔍 自动向量搜索](#-自动向量搜索)
- [⚡ 无嵌入模型自动降级](#-无嵌入模型自动降级)
- [🎯 三功能协同工作流](#-三功能协同工作流)
- [🔧 配置与调试](#-配置与调试)

---

## 🤖 自动草稿机制（两阶段设计）

### 核心设计理念

rocky-know-how 的"自动写入"实际上是**两阶段流程**，确保经验质量：

```
阶段1: 自动生成草稿（Hook 触发）
阶段2: 人工/AI 审核草稿
阶段3: 手动写入正式经验（record.sh）
```

**为什么不是全自动？**
- ❌ 防止测试对话、临时问答污染经验库
- ❌ 避免低质量经验入库
- ✅ 质量把关：只有值得复用的经验才保留
- ✅ 可追溯：草稿保留原始上下文

---

### 阶段1: 自动生成草稿

#### 触发条件
- **事件**: `before_reset` Hook（会话压缩/重置前）
- **时机**: 任务成功完成后，会话结束前
- **条件**: 检测到 `task` + `errors`（表示有问题解决过程）

#### 执行流程

```
任务成功
   ↓
before_reset Hook 触发
   ↓
handler.js 分析 messages
   ├── 提取 task（用户目标）
   ├── 提取 tools（使用的工具）
   ├── 提取 errors（遇到的错误）
   ↓
生成草稿文件: ~/.openclaw/.learnings/drafts/draft-{sessionKey}.json
   ↓
草稿状态: "pending_review"（待审核）
```

**handler.js 代码**（L147-165）：
```javascript
if (event.type === 'before_reset') {
  const messages = event.messages || event.context?.messages || [];
  saveCompactionState(sessionKey, env, messages);  // 生成草稿
  return;
}
```

**草稿示例**（draft-1776958084440-qad5k6.json）：
```json
{
  "id": "draft-1776958084440-qad5k6",
  "createdAt": "2026-04-23T15:28:04.440Z",
  "sessionKey": "agent:test",
  "problem": "Deploy nginx container",
  "tried": "Error: bind failed: port already in use",
  "solution": "解决方案待补充",
  "prevention": "记录时间: 2026/4/23 23:28:04",
  "tags": ["nginx", "error", "draft"],
  "area": "infra",
  "status": "pending_review",  // ← 待审核状态
  "reviewedAt": "2026-04-23T15:31:13Z"
}
```

#### 什么情况下不会生成草稿？

| 情况 | 原因 | 结果 |
|------|------|------|
| 纯文档编辑 | `errors` 数组为空 | ❌ 跳过 |
| 闲聊 | 无工具调用、无错误 | ❌ 跳过 |
| 会话未结束 | 无 before_reset 事件 | ❌ 跳过 |
| 子 agent 任务 | `sessionKey` 含 `:subagent:` | ❌ 跳过 |

**今天的案例**: 文档版本统一工作 → 无 errors → 未生成草稿 ✅

---

### 阶段2: 草稿审核

#### 审核方式

**方式1: 批量 AI 辅助审核（推荐）**
```bash
# 扫描所有草稿，生成 AI 判断提示
bash ~/.openclaw/skills/rocky-know-how/scripts/summarize-drafts.sh

# 输出日志：~/.openclaw/.learnings/.summarize.log
# 内容：每个草稿的「值得记录: 是/否」+ 原因 + record.sh 命令
```

**summarize-drafts.sh 工作原理**:
1. 扫描 `drafts/` 所有 `draft-*.json`
2. 提取 problem/solution/tags
3. 生成 AI 提示（判断是否值得记录）
4. 输出建议的 `record.sh` 命令到日志
5. **不自动执行**（需人工确认）

**方式2: 手动直接处理**
```bash
# 1. 查看草稿
cat ~/.openclaw/.learnings/drafts/draft-*.json

# 2. 根据内容手动执行 record.sh
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "问题" "踩坑过程" "正确方案" "预防" "tag1,tag2" "area"
```

---

### 阶段3: 写入正式经验

执行 `record.sh` 后：

```
1. 去重检查（70% 标签重叠拦截）
2. 生成 ID (EXP-YYYYMMDD-HHMM)
3. 持有 .write_lock 写入 experiences.md
4. 同步 memory.md（HOT 层）
5. 同步 domains/{area}.md（WARM 层）
6. 释放锁
```

**写入后**: 经验可被 `search.sh` 搜索到，可被 Tag 晋升机制捕获。

---

### 两阶段设计优势

| 问题 | 单阶段风险 | 两阶段解决方案 |
|------|-----------|---------------|
| 测试对话 | 污染经验库 | 草稿阶段过滤 |
| 临时问题 | 噪音数据 | 审核时丢弃 |
| 低质量经验 | 难以清理 | 人工把关 |
| 误写入 | 无法撤销 | 未审核前无副作用 |
| 批量处理 | 无法追溯 | drafts/ 保留原始上下文 |

---

### 常见误区

#### ❌ 误区1: "自动写入 = 全自动"
**误解**: Hook 触发后直接写入 experiences.md
**真相**: Hook 只生成**草稿**，需审核后才写入

#### ❌ 误区2: "草稿 = 正式经验"
**误解**: drafts/ 目录下的 JSON 可直接搜索
**真相**: 草稿状态 `pending_review`，`search.sh` 只搜 experiences.md

#### ❌ 误区3: "summarize-drafts.sh 会自动写入"
**误解**: 执行脚本就完成记录
**真相**: 只输出建议命令，**仍需人工执行** `record.sh`

#### ✅ 正确理解:
```
任务成功 → Hook 生成草稿（自动，无感）
    ↓
定期执行 summarize-drafts.sh（批量生成建议）
    ↓
人工审核 → 复制 record.sh 命令执行
    ↓
写入 experiences.md（正式入库）
```

---

## 🔍 自动向量搜索

### 概述

rocky-know-how 支持**两种搜索模式**：

1. **关键词搜索**（默认）- 基于文本匹配 + 相关度评分
2. **语义搜索**（`--semantic`）- 基于向量 embedding 的语义相似度

### 向量搜索工作原理

```
用户输入: "Nginx 502 错误怎么修复？"

Step 1: 生成查询向量
   ↓
调用 LM Studio embedding API
   ↓
text-embedding-qwen3-embedding-0.6b 模型
   ↓
输出: [0.123, -0.456, ...] (768维向量)

Step 2: 加载向量索引
   ↓
读取 ~/.openclaw/.learnings/vectors/index.json
   ↓
包含所有经验的 embedding 向量

Step 3: 计算余弦相似度
   ↓
对比查询向量 vs 每个经验向量
   ↓
cosine_similarity = (A·B) / (||A|| * ||B||)

Step 4: 相关度排序
   ↓
相似度 > 0.7 的高相关经验优先展示
```

### 向量索引结构

```json
{
  "vectors": {
    "EXP-20260420-001": {
      "embedding": [0.123, -0.456, ...],
      "area": "infra",
      "tags": ["nginx", "502", "php-fpm"],
      "text": "Nginx 502 错误: 重启 php-fpm",
      "updated_at": "2026-04-20T14:30:00"
    }
  },
  "meta": {
    "model": "text-embedding-qwen3-embedding-0.6b",
    "dimension": 768,
    "count": 1116,
    "last_indexed": "2026-04-24T01:10:00"
  }
}
```

### 使用方式

#### 关键词搜索（默认）
```bash
# 多关键词 AND 匹配
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "502" "nginx"

# 按标签过滤
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --tag "nginx,php-fpm"

# 按领域过滤
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --area infra
```

#### 语义搜索（显式启用）
```bash
# 使用向量相似度搜索
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic "服务器响应超时怎么办"

# 组合：语义搜索 + 标签过滤
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic --tag "timeout,nginx"

# 摘要模式（只显示匹配度）
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic --preview "连接池耗尽"
```

### 向量搜索 vs 关键词搜索

| 特性 | 关键词搜索 | 语义搜索 (`--semantic`) |
|------|-----------|------------------------|
| 匹配方式 | 文本字面匹配 | 向量余弦相似度 |
| 优势 | 精确、快速、无需模型 | 理解同义词、近义词 |
| 示例 | "502" 只匹配含 "502" 的 | "服务器不响应" 可匹配 "502 错误" |
| 依赖 | 无 | LM Studio embedding 模型 |
| 速度 | 快（本地 grep） | 中（需 API 调用） |

**示例对比**：
```
查询: "PHP 进程崩溃"

关键词搜索:
  ✅ 匹配: "php-fpm 进程数不足导致 502"
  ❌ 不匹配: "PHP-FPM 退出代码 255"（无"崩溃"字眼）

语义搜索:
  ✅ 匹配: "PHP-FPM 退出代码 255"（语义相似）
  ✅ 匹配: "FastCGI 进程意外终止"
```

---

## ⚡ 无嵌入模型自动降级

### 问题

向量搜索依赖 LM Studio 的 embedding 模型。如果：
- LM Studio 未启动
- 无 embedding 模型加载
- API 超时或错误

直接使用 `--semantic` 会失败。

### 解决方案：自动降级

rocky-know-how 实现了**智能降级机制**：

```bash
# 用户执行（期望语义搜索）
bash search.sh --semantic "数据库连接失败"

# 内部流程
   ↓
检测 LM Studio 是否可用
   ↓
┌─────────────────────────────────────┐
│ 检测：curl -s --max-time 3 API      │
│ 发送测试文本 "health"               │
│ 期望返回: {"data":[{"embedding":[...]}]}
└─────────────────────────────────────┘
   ↓
    ├─ ✅ 可用 → 使用向量搜索
    │   生成查询向量 → 计算相似度 → 返回语义结果
    │
    └─ ❌ 不可用 → 自动降级为关键词搜索
         echo "⚠️  向量搜索不可用（LM Studio 未运行或无 embedding 模型），使用关键词搜索"
         → 执行普通关键词搜索
         → 返回结果（质量略低但可用）
```

### 降级触发条件

| 条件 | 检测方式 | 结果 |
|------|----------|------|
| LM Studio 未运行 | curl 超时或无响应 | 降级 |
| 无 embedding 模型 | API 返回 404/错误 | 降级 |
| 网络不可达 | curl 失败 | 降级 |
| 向量索引损坏 | 读取 vectors/ 失败 | 降级 |
| 显式 `--no-semantic` | 参数指定 | 直接关键词搜索 |

### 用户体验

```bash
$ bash search.sh --semantic "502 错误"

# 场景1: LM Studio 正常
🔍 语义搜索模式（向量索引: 1116 条）
✅ LM Studio 检测通过 (http://localhost:1234)
📊 计算查询向量... (维度: 768)
🎯 找到 5 条相关经验（相关度 0.72~0.91）
---
[EXP-20260420-001] Nginx 502 错误处理 (相关度: 0.91)
  Area: infra | Tags: nginx,php-fpm,502
  方案: 重启 php-fpm，调整 pm.max_children=50
  来源: memory.md:15

# 场景2: LM Studio 未运行
⚠️  向量搜索不可用（LM Studio 未运行或无 embedding 模型），使用关键词搜索
🔍 关键词搜索模式（1116 条经验）
🎯 找到 3 条匹配结果
---
[EXP-20260420-001] Nginx 502 错误处理
  方案: 重启 php-fpm...
```

### 技术实现

**文件**: `scripts/lib/vectors.sh`

```bash
# 检测向量 API 是否可用
vector_check() {
  curl -s --max-time 3 "$VECTOR_API" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$VECTOR_MODEL\",\"input\":\"health\"}" 2>/dev/null \
    | grep -q '"embedding"'
}

# search.sh 主逻辑
if [ "$SEMANTIC" = true ]; then
  if vector_check; then
    vector_api_available=true
  else
    echo "⚠️  向量搜索不可用，降级为关键词搜索"
    SEMANTIC=false  # 自动切换
  fi
fi

if [ "$SEMANTIC" = true ]; then
  # 使用向量搜索
  vector_search "$QUERY_TEXT"
else
  # 使用关键词搜索
  keyword_search "$KEYWORDS"
fi
```

### 配置向量搜索

#### 1. 启动 LM Studio
```bash
# 打开 LM Studio
open -a "LM Studio"

# 加载 embedding 模型
# 推荐: text-embedding-qwen3-embedding-0.6b (Qwen3 0.6B Embedding)
# 或: BGE-M3 (多语言)

# 启动 API 服务器
# 端口: 1234 (默认)
# 模式: embedding only (无需 LLM)
```

#### 2. 验证向量搜索
```bash
# 测试向量 API
curl -s http://localhost:1234/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model":"text-embedding-qwen3-embedding-0.6b","input":"test"}' \
  | python3 -m json.tool | head -5

# 预期输出包含 "embedding" 数组
```

#### 3. 测试语义搜索
```bash
# 启用语义搜索
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic "连接池耗尽"

# 如果 LM Studio 未运行，应看到降级提示
```

---

## 🎯 三功能协同工作流

### 完整自动化流程

```
┌─────────────────────────────────────────────────────────────┐
│                     Agent 执行任务                           │
│           （例如：修复公众号图片上传 Bug）                     │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ 第 1 次失败      │ ← 继续尝试
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ 第 2 次失败      │ ← 触发 🔍
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │ 自动搜索经验 (search.sh)     │
              │ 检测向量 API 是否可用        │
              │   ├─ 可用 → 语义搜索          │
              │   └─ 不可用 → 降级关键词搜索  │
              └──────────────┬──────────────┘
                             │
              ┌──────────────┴──────────────┐
              │ 找到相关经验？                │
              └──────────────┬──────────────┘
                 ├─ 是        └─ 否
                 │               │
                 ▼               ▼
        ┌─────────────┐  ┌─────────────┐
        │ 按方案执行   │  │ 继续尝试     │
        └─────────────┘  └─────────────┘
                 │               │
                 └───────┬───────┘
                         │
                         ▼
                  ┌─────────────────┐
                  │ 任务成功 ✅       │ ← 触发 📝
                  └────────┬────────┘
                           │
                  ┌────────┴────────┐
                  │ 自动写入经验     │
                  │ (record.sh)     │
                  │  1. 去重检查     │
                  │  2. 获取锁       │
                  │  3. 生成 ID      │
                  │  4. 写入文件     │
                  │  5. 向量索引     │ ← 同时更新向量库
                  │  6. 同步记忆     │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ 同 Tag ≥3 次？   │ ← 触发 🚀
                  └────────┬────────┘
                           │
                  ┌────────┴────────┐
                  │ 自动晋升        │
                  │ (promote.sh)    │
                  │ → TOOLS.md      │
                  └─────────────────┘
```

### 三功能对比表

| 功能 | 触发条件 | 自动/手动 | 依赖条件 | 输出 |
|------|---------|-----------|----------|------|
| **自动写入** | 任务成功 | 自动 | Hook 配置 | experiences.md |
| **向量搜索** | `--semantic` 参数 | 手动 | LM Studio | 语义匹配结果 |
| **自动降级** | 向量 API 不可用 | 自动 | 检测失败 | 关键词搜索结果 |

### 故障场景

#### 场景 1: 向量搜索失败自动降级
```
User: search.sh --semantic "数据库连接失败"
   ↓
检测 LM Studio → 未运行
   ↓
输出: "⚠️  向量搜索不可用，降级为关键词搜索"
   ↓
执行关键词搜索 → 返回结果
   ✅ 用户体验不受影响
```

#### 场景 2: 自动写入并发冲突
```
Agent A 和 Agent B 同时成功任务
   ↓
同时调用 record.sh
   ↓
A 创建 .write_lock 成功 → 持有锁
B 创建 .write_lock 失败 → 等待 1 秒 → 重试
   ↓
A 写入完成 → 释放锁
B 获取锁 → 写入
   ✅ 文件不交错
```

#### 场景 3: 写入重复经验
```
任务: 修复 Nginx 502（已记录过 EXP-20260420-001）
   ↓
自动写入检测: 问题文本相似度 75% > 70%
   ↓
跳过写入，输出: "⚠️  已存在相似经验，跳过"
   ✅ 避免重复
```

---

## 🔧 配置与调试

### 1. 启用向量搜索

```bash
# 1. 启动 LM Studio
open -a "LM Studio"

# 2. 加载 embedding 模型
# 推荐模型: text-embedding-qwen3-embedding-0.6b (约 400MB)
# 或: BGE-M3 (多语言，约 2GB)

# 3. 启动 API Server
# 点击 "Start Server" → 端口 1234
# 模式: Embedding Only（不需要 LLM）

# 4. 验证 API
curl -s http://localhost:1234/v1/models | python3 -m json.tool
# 应看到 embedding 模型列表
```

### 2. 调试自动降级

```bash
# 查看向量搜索状态
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic "test" 2>&1 | head -5

# 测试向量 API 连通性
curl -v --max-time 3 http://localhost:1234/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model":"text-embedding-qwen3-embedding-0.6b","input":"hello"}'

# 查看向量索引
ls -la ~/.openclaw/.learnings/vectors/

# 重建向量索引（如果损坏）
bash ~/.openclaw/skills/rocky-know-how/scripts/clean.sh --rebuild-vectors
```

### 3. 验证自动写入

```bash
# 测试自动写入（模拟任务成功）
# 方法1: 手动调用 record.sh
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "测试自动写入" "测试过程" "测试方案" "测试预防" "test,auto" "global"

# 验证写入
tail -5 ~/.openclaw/.learnings/experiences.md
tail -5 ~/.openclaw/.learnings/memory.md

# 检查锁文件（应不存在）
ls -la ~/.openclaw/.learnings/.write_lock/ 2>/dev/null || echo "无锁（正常）"

# 并发测试（两个终端同时执行）
# 应看到 "❌ 写入冲突，请稍后重试" 提示
```

### 4. 查看 Hook 日志

```bash
# 实时监控 Hook 事件
tail -f ~/.openclaw/logs/gateway.log | grep -E "rocky|before_reset"

# 检查 Hook 配置
grep -A 10 "rocky-know-how" ~/.openclaw/openclaw.json

# 预期配置：
# "handler": "~/.openclaw/skills/rocky-know-how/hooks/handler.js",
# "events": ["agent:bootstrap", "before_compaction", "after_compaction", "before_reset"]
```

---

## 📊 性能对比

| 搜索模式 | 速度 | 精度 | 资源消耗 | 适用场景 |
|---------|------|------|---------|----------|
| **关键词搜索** | ⚡ 快 (0.1s) | 高（精确匹配） | 低 | 已知关键词、错误码 |
| **语义搜索** | ⏱️ 中 (0.5s) | 高（语义理解） | 中 | 自然语言描述、同义词 |
| **降级搜索** | ⚡ 快 | 中（仅字面） | 低 | 向量不可用时的备选 |

**推荐使用策略**：
- 日常调试 → 关键词搜索（默认）
- 模糊问题描述 → `--semantic` 语义搜索
- LM Studio 未运行 → 自动降级（无感知）

---

## 🎓 最佳实践

### 何时使用语义搜索？

✅ **适合**：
- 问题描述是自然语言（"数据库连不上"）
- 不确定具体错误码
- 想找相似问题的解决方案

❌ **不适合**：
- 已知精确错误码（"SQLSTATE[HY000] [2002] Connection refused"）
- 性能敏感场景
- 离线环境（无 LM Studio）

### 如何优化向量质量？

1. **丰富经验文本**：
   ```bash
   # 坏例子: "502 错误"
   # 好例子: "Nginx 502 Bad Gateway: upstream 响应超时，php-fpm 进程池满"
   record.sh "Nginx 502 错误" "..." "重启 php-fpm" "..." "nginx,502" "infra"
   ```

2. **添加多维度标签**：
   ```bash
   Tags: "nginx,502,php-fpm,timeout,upstream"
   # 越多维度，语义搜索越精准
   ```

3. **定期重建向量索引**：
   ```bash
   # 大量写入后重建
   bash ~/.openclaw/skills/rocky-know-how/scripts/clean.sh --rebuild-vectors
   ```

---

## 🔍 技术细节

### 向量索引更新机制

```bash
# record.sh 写入经验时同时更新向量库
record.sh "问题" "过程" "方案" "预防" "tags" "area"
   ↓
写入 experiences.md ✅
   ↓
检查向量功能
   ↓
if vector_api_available; then
  # 生成文本向量
  VECTOR_TEXT="问题\n方案\n预防"
  embedding=$(vector_embed "$VECTOR_TEXT")
   ↓
  # 添加到索引
  vector_index_add "$ID" "$embedding" "$AREA" "$NAMESPACE" "$TAGS"
   ↓
  # 保存到 vectors/index.json
  echo "$ID $embedding" >> vectors/index.json
fi
```

### 自动降级检测频率

- **每次 `search.sh --semantic` 执行时检测**
- 检测耗时: ≤ 3 秒（`curl --max-time 3`）
- 缓存结果: 不缓存，每次实时检测（确保状态准确）

### 向量索引文件位置

```
~/.openclaw/.learnings/
├── experiences.md          # 主数据库
├── vectors/
│   ├── index.json         # 向量索引（ID → embedding）
│   ├── meta.json          # 元数据（模型、维度、数量）
│   └── tmp/               # 临时文件（重建索引用）
```

---

## 🚨 故障排查

| 问题 | 可能原因 | 解决方案 |
|------|---------|----------|
| `--semantic` 总是降级 | LM Studio 未启动 | 启动 LM Studio，加载 embedding 模型 |
| 向量搜索报 429 | API 并发限制 | 减少并发请求，或增加 LM Studio 最大连接数 |
| 语义结果不相关 | 向量索引未更新 | 重建索引: `clean.sh --rebuild-vectors` |
| 写入后向量搜索不到 | 向量索引异步更新 | 等待 1-2 秒，或手动触发 `vector_reindex_all` |
| curl 命令找不到 | 网络异常 | 检查 localhost:1234 是否可达 |

### 诊断命令

```bash
# 1. 检查 LM Studio 状态
curl -s http://localhost:1234/v1/models | python3 -m json.tool

# 2. 测试 embedding API
curl -s http://localhost:1234/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model":"text-embedding-qwen3-embedding-0.6b","input":"test"}' \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print('维度:', len(d['data'][0]['embedding']))"

# 3. 查看向量索引统计
wc -l ~/.openclaw/.learnings/vectors/index.json

# 4. 强制重建索引
rm -rf ~/.openclaw/.learnings/vectors/
bash ~/.openclaw/skills/rocky-know-how/scripts/clean.sh --rebuild-vectors
```

---

## 📈 版本历史

| 版本 | 日期 | 更新 |
|------|------|------|
| **2.8.4** | 2026-04-24 | 📚 完整文档化自动写入、向量搜索、自动降级 |
| 2.8.3 | 2026-04-24 | 🔒 H1/H2 安全修复，memory.md 压缩优化 |
| 2.8.2 | 2026-04-24 | 🔐 并发锁、Hook 路径动态化 |
| 2.7.1 | 2026-04-21 | 支持 4 个 Hook 事件 |
| 2.6.0 | 2026-04-15 | 🆕 首次引入向量搜索 + 自动降级 |

---

**最后更新**: 2026-04-24 v2.8.6  
**维护**: rocky-know-how 团队  
**状态**: ✅ 生产就绪
