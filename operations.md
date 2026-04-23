# 操作手册 (v2.8.6)

> 最新版本: 2026-04-24 | 兼容: OpenClaw 2026.4.x+

## 核心命令

| 命令 | 操作 | 版本 |
|------|------|------|
| `search.sh "关键词"` | 搜索经验（相关度排序） | v2.8.6 |
| `record.sh "问题" ...` | 写入经验（**并发安全**） | v2.8.6 |
| `stats.sh` | 统计面板（条目数、Tag/Area分布） | v2.8.6 |
| `promote.sh` | Tag晋升检查（≥3次→TOOLS.md） | v2.8.6 |
| `import.sh` | 从 memory 导入（**路径穿越修复**） | v2.8.6 |
| `archive.sh --auto` | 自动归档（cron/heartbeat） | v2.8.6 |
| `clean.sh` | 清理工具（测试条目/旧索引） | v2.8.6 |
| `update-record.sh` | 更新已有经验（**标签格式对齐**） | v2.8.6 |

## 自动操作

### 会话开始时

1. 加载 memory.md（HOT 层）
2. 检查 index.md 了解上下文提示
3. 检测到项目 → 预加载相关命名空间

### 任务失败处理（v2.8.6 自动搜索）

当任务失败时，Agent 自动执行：

```
第 1 次失败 → 标记任务状态，继续尝试
    ↓
第 2 次失败 → 🔍 自动搜索经验 (search.sh)
    ├── 找到相关经验 → 应用方案
    └── 没找到 → 记录为"待学习"，继续尝试
```

**触发条件**: 同一任务连续失败 ≥2 次
**搜索范围**: 所有层（HOT/WARM/COLD）
**输出**: 相关经验列表，按相关度排序

---

### 任务成功处理（v2.8.6 自动写入）

当任务成功完成后，Agent 自动执行：

```
成功 → 📝 自动写入经验 (record.sh)
    ↓
检查重复（问题文本 + Tags 70%重叠）
    ↓
新经验？ → 生成 ID (EXP-YYYYMMDD-HHMM)
    ↓
持有 .write_lock 目录锁
    ↓
写入 experiences.md
    ↓
同步到 memory/*.md（根据命名空间）
    ↓
同 Tag ≥3 次？ → 触发 promote.sh
```

**关键规则**:
- ✅ **去重**: 问题文本相似度 ≥70% 或 Tags 完全相同的拦截
- ✅ **并发锁**: `.write_lock` 目录锁确保多进程安全
- ✅ **命名空间**: 根据任务类型自动选择 global/domain/project
- ✅ **同步**: 同时更新 experiences.md 和对应 memory/*.md

**示例**:
```
任务: 修复 Nginx 502 错误
成功方案: 重启 php-fpm，调整 pm.max_children
自动写入:
  → experiences.md (ID: EXP-20260424-0117)
  → domains/infra.md (Tag: nginx,php-fpm)
  → memory.md (摘要: "Nginx 502: restart php-fpm")
```

---

### 收到纠正时（手动/自动）

```
1. 解析纠正类型（偏好、模式、覆盖）
2. 检查是否重复（存在于任何层）
3. 如果新：
   - 添加到 corrections.md（带时间戳）
   - 增加纠正计数
4. 如果重复：
   - 计数+1，更新时间戳
   - 如果计数 ≥3：询问确认作为规则
5. 确定命名空间（global, domain, project）
6. 写入适当文件
7. 更新 index.md 行数
```

---

### Hook 事件自动触发

| 事件 | 触发时机 | 自动操作 | 版本 |
|------|----------|----------|------|
| `agent:bootstrap` | AI 启动 | 加载 memory.md，注入经验提醒 | v2.8.6+ |
| `before_compaction` | 压缩前 | 分析会话，生成经验草稿 | v2.8.6+ |
| `after_compaction` | 压缩后 | 记录会话摘要到 reflections.md | v2.8.6+ |
| `before_reset` | 重置前 | 保存状态，生成最终草稿 | v2.8.6+ |

**Hook 配置**: install.sh 已自动配置到 openclaw.json

---

### 循环维护（心跳）

```
1. 扫描所有文件查找衰减候选
2. 移动 30天+ 未使用的到 WARM
3. 归档 90天+ 未使用的到 COLD
4. 如果任何文件超限则运行压缩
5. 更新 index.md
6. 生成摘要（可选）
```

**心跳触发**: 通过 HEARTBEAT.md 配置，通常每 30 分钟一次
**安全规则**: 大多数心跳运行应该什么都不做，只做保守组织

---

## 自动写入完整流程图示

```
┌─────────────┐
│  任务开始   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 执行任务    │
└──────┬──────┘
       │
       ├─失败1次→继续尝试
       │
       ▼
┌─────────────┐
│ 失败 2 次   │ ← 自动搜索 (search.sh)
└──────┬──────┘      ↓
       │        找到经验？
       │           ├─是 → 按方案执行
       │           └─否 → 继续尝试
       ▼
┌─────────────┐
│  任务成功   │ ← 自动写入 (record.sh)
└──────┬──────┘      ↓
       │        去重检查 (70%)
       │           ├─重复 → 跳过
       │           └─新经验 → 写入
       ▼
┌─────────────┐
│ 经验已记录  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 同 Tag ≥3？ │ ← 自动晋升 (promote.sh)
└──────┬──────┘      ↓
       │        写入 TOOLS.md
       ▼
┌─────────────┐
│  循环完成   │
└─────────────┘
```

---

**关键版本**: v2.8.6+ 完整自动机制
**前置条件**: Hook 正确配置（install.sh 自动配置）

## 典型使用场景 (v2.8.6)

### 场景 1: 调试 Nginx 502 错误

```
1. 任务: 修复网站 502 错误
2. 第 1 次失败 → 继续尝试
3. 第 2 次失败 → 🔍 自动搜索 "502 nginx"
   找到经验: "Nginx 502: restart php-fpm" (EXP-20260420-001)
4. 按方案执行 → 成功 ✅
5. 📝 自动写入（如果经验不存在）：
   问题: Nginx 502 错误
   过程: 检查 upstream 超时，php-fpm 进程数不足
   方案: 重启 php-fpm，调整 pm.max_children=50
   预防: 监控 php-fpm 内存，设置告警
   Tags: nginx,php-fpm,502
   Area: infra
```

### 场景 2: 公众号开发 OCR 识别

```
1. 任务: 实现图片文字识别
2. 失败 2 次 → 自动搜索 "OCR 图片识别"
   找到: "微信公众号 OCR: 使用百度 API，需转 base64" (EXP-20260418-003)
3. 执行 → 成功
4. 自动写入新经验（如果是新问题）
   同步到: domains/wx.newstt.md
   Tag 晋升: 同 Tag "ocr" 使用 3 次后 → TOOLS.md
```

### 场景 3: 用户明确说"记住这个"

```
User: "记住：以后所有 API 响应必须带 error_code 字段"
↓
Agent: 立即记录纠正（手动触发）
  → corrections.md
  → 计数+1
  → 3 次后询问确认
  → 确认后晋升为偏好
```

---

## 自动 vs 手动写入对比

| 特性 | 自动草稿 | 手动写入 |
|------|---------|----------|
| 触发 | 任务成功（Hook） | 用户明确指令 |
| 时机 | 会话压缩时（before_reset） | 随时 |
| 输出 | 草稿 (drafts/draft-*.json) | 正式经验 (experiences.md) |
| 状态 | pending_review（待审核） | 立即生效 |
| 去重 | ❌ 不检查（草稿阶段） | ✅ 自动检查 |
| 锁保护 | ❌ 无（JSON独立文件） | ✅ .write_lock |
| 命名空间 | 自动推断（area） | 用户指定 |
| Hook 集成 | ✅ before_reset | ❌ 无 |
| 适用场景 | 所有任务成功会话 | 特殊经验、手动补充 |

---

## 两阶段完整流程 (v2.8.6+)

### 阶段1: 自动生成草稿

```
任务成功 → before_reset Hook 触发
    ↓
handler.js 提取会话信息
    ├── task: 用户任务描述
    ├── tools: 使用的工具列表
    ├── errors: 遇到的错误（已解决）
    ↓
生成草稿文件: drafts/draft-{sessionKey}.json
    ↓
状态: "pending_review"（待审核）
```

**草稿示例**:
```json
{
  "id": "draft-1776958084440-qad5k6",
  "problem": "Deploy nginx container",
  "tried": "Error: bind failed: port already in use",
  "solution": "解决方案待补充",
  "tags": ["nginx", "error"],
  "area": "infra",
  "status": "pending_review"
}
```

### 阶段2: 草稿审核

**方式1: 批量审核（推荐）**
```bash
# 查看草稿
ls ~/.openclaw/.learnings/drafts/

# 批量生成审核建议（输出 record.sh 命令）
bash ~/.openclaw/skills/rocky-know-how/scripts/summarize-drafts.sh

# 查看生成的命令
cat ~/.openclaw/.learnings/.summarize.log

# 执行推荐的 record.sh 命令
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh "..."
```

**方式2: 手动直接写入**
```bash
# 直接读取草稿内容，手动执行 record.sh
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "问题" "踩坑过程" "正确方案" "预防" "tag1,tag2" "area"
```

### 阶段3: 写入正式经验

`record.sh` 执行后：
```
1. 去重检查（70% 重叠拦截）
2. 生成 ID (EXP-YYYYMMDD-HHMM)
3. 持有 .write_lock 写入 experiences.md
4. 同步 memory.md + domains/{area}.md
5. 释放锁
```

---

## 草稿生命周期

| 状态 | 说明 | 操作 |
|------|------|------|
| `pending_review` | 待审核（刚生成） | 执行 summarize-drafts.sh 或手动处理 |
| `reviewed` | 已审核 | 已执行 record.sh 写入正式经验 |
| `archived` | 已归档 | 超过30天未处理，自动移至 archive/ |
| `discarded` | 已丢弃 | 测试数据或无效经验

**草稿保留时间**: 默认 7 天，超期自动清理

## 草稿审核最佳实践

1. **定期审核**（建议每天）
   ```bash
   # 通过 heartbeat 或 cron 每天执行
   bash ~/.openclaw/skills/rocky-know-how/scripts/summarize-drafts.sh
   ```

2. **批量处理**（减少重复劳动）
   - `summarize-drafts.sh` 一次处理所有草稿
   - 输出多条 `record.sh` 命令，复制执行即可

3. **质量把关**（避免垃圾数据）
   - 检查问题描述是否清晰
   - 方案是否可复用
   - Tags 是否准确

## 为什么需要审核？

### 场景1: 测试对话（应过滤）
```
User: "测试"
Agent: "好的，测试完成"
→ 不应写入经验库
```

### 场景2: 临时问题（应过滤）
```
User: "今天天气怎么样？"
→ 与工作无关，不应写入
```

### 场景3: 真实踩坑（应保留）
```
User: "Nginx 502 怎么修复？"
Agent: 尝试多种方案 → 成功
→ 应转为正式经验
```

**审核机制**: 通过 `drafts/` 中间层，人工或 AI 判断是否值得保留。

---

## 配置检查清单

安装后验证自动写入是否生效：

```bash
# 1. 检查 Hook 配置
grep -A 8 '"rocky-know-how"' ~/.openclaw/openclaw.json

# 期望输出包含：
#   "handler": "~/.openclaw/skills/rocky-know-how/hooks/handler.js"
#   "events": ["agent:bootstrap","before_compaction","after_compaction","before_reset"]

# 2. 测试自动搜索（模拟失败）
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "test"

# 3. 查看 Hook 日志
 tail -f ~/.openclaw/logs/gateway.log | grep rocky-know-how

# 4. 验证自动写入权限
ls -la ~/.openclaw/.learnings/
# 确保目录可写
```

**常见问题**:
- ❌ 自动写入不生效 → 检查 Hook 配置，重启网关
- ❌ 并发写入冲突 → 确保 .write_lock 目录可创建
- ❌ 搜索无结果 → experiences.md 为空，先手动写入几条

---

**最后更新**: 2026-04-24 v2.8.6

### corrections.md

```markdown
# 纠正日志

## 2026-02-15
- [14:32] Changed verbose explanation → bullet summary
  Type: communication
  Context: Telegram response
  Confirmed: pending (1/3)

## 2026-02-14
- [09:15] Use SQLite not Postgres for MVP
  Type: technical
  Context: database discussion
  Confirmed: yes (said "always")
```

### projects/{name}.md

```markdown
# Project: my-app

Inherits: global, domains/code

## 模式
- Use Tailwind (project standard)
- No Prettier (eslint only)
- Deploy via GitLab CI

## 覆盖
- semicolons: yes (覆盖 global no-semi)

## 历史
- Created: 2026-01-15
- Last active: 2026-02-15
- 纠正: 12
```

### experiences.md (v1 向后兼容)

```markdown
## [EXP-20260417-001] Mac迁移后LaunchAgent需重新注册

**Area**: infra
**Failed-Count**: ≥2
**Tags**: migration,launchctl,macOS
**Created**: 2026-04-17 23:39:29

### 问题
Mac迁移后LaunchAgent需重新注册

### 踩坑过程
迁移后网关从终端启动，关了就断

### 正确方案
执行 openclaw gateway install 重新注册 LaunchAgent

### 预防
迁移后必须检查所有 LaunchAgent 注册状态
```

## 边缘情况处理

### 检测到矛盾

```
Pattern A: "Use tabs" (global, confirmed)
Pattern B: "Use spaces" (project, corrected today)

Resolution:
1. Project overrides global → use spaces for this project
2. Log conflict in corrections.md
3. Ask: "Should spaces apply only to this project or everywhere?"
```

### 用户改变主意

```
Old: "Always use formal tone"
New: "Actually, casual is fine"

Action:
1. 归档旧模式（带时间戳）
2. 添加新模式为暂定
3. 保留归档供参考（"You previously preferred formal"）
```

### 上下文模糊

```
User says: "Remember I like X"

But which namespace?
1. Check current context (project? domain?)
2. If unclear, ask: "Should this apply globally or just here?"
3. Default to most specific active context
```
