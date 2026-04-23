# ❓ 常见问题解答 (FAQ) v2.8.6

## 🚀 安装与配置

### Q1: 安装后如何验证成功？

**A**: 参考 `setup.md` 的"✅ 验证安装"章节，执行以下命令：

```bash
# 1. 检查脚本
ls -la ~/.openclaw/skills/rocky-know-how/scripts/

# 2. 检查 Hook 配置
grep -A 10 "rocky-know-how" ~/.openclaw/openclaw.json

# 3. 测试搜索（应无错误）
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --all

# 4. 测试自动写入
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "安装测试" "测试过程" "测试方案" "测试预防" "test,install" "global"

# 5. 查看统计
bash ~/.openclaw/skills/rocky-know-how/scripts/stats.sh
```

**预期结果**: search.sh 无错误，record.sh 输出 "✅ 记录成功"，stats.sh 显示条目数。

---

### Q2: Hook 配置失败怎么办？

**A**: Hook 配置由 `install.sh` 自动完成。如果失败：

```bash
# 1. 检查 openclaw.json 语法
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# 2. 手动添加 Hook 配置
# 编辑 ~/.openclaw/openclaw.json，在 plugins.entries 中添加：
{
  "rocky-know-how": {
    "enabled": true,
    "handler": "~/.openclaw/skills/rocky-know-how/hooks/handler.js",
    "events": ["agent:bootstrap", "before_compaction", "after_compaction", "before_reset"]
  }
}

# 3. 重启网关
openclaw gateway restart

# 4. 验证 Hook 加载
tail -f ~/.openclaw/logs/gateway.log | grep rocky-know-how
```

**常见问题**:
- JSON 语法错误 → 用 `python3 -m json.tool` 验证
- 路径错误 → 确保 `handler` 路径存在
- 网关未重启 → 必须重启才能生效

---

## 🔍 搜索功能

### Q3: 搜索返回空结果怎么办？

**A**: 可能原因和解决方案：

| 原因 | 检查方法 | 解决方案 |
|------|---------|----------|
| experiences.md 为空 | `wc -l ~/.openclaw/.learnings/experiences.md` | 先手动写入几条测试数据 |
| 关键词不匹配 | `grep -i "关键词" ~/.openclaw/.learnings/experiences.md` | 调整关键词，或使用 `--all` 查看全部 |
| Hook 未加载 | `grep rocky-know-how ~/.openclaw/logs/gateway.log` | 检查 Hook 配置，重启网关 |
| 文件权限问题 | `ls -la ~/.openclaw/.learnings/` | 确保当前用户可读写 |

**调试步骤**:
```bash
# 1. 查看 experiences.md 内容
tail -20 ~/.openclaw/.learnings/experiences.md

# 2. 测试基础搜索（应看到内容）
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --all | head -20

# 3. 检查索引文件
cat ~/.openclaw/.learnings/index.md
```

---

### Q4: 语义搜索 (`--semantic`) 总是降级为关键词搜索？

**A**: 这是正常的，说明 LM Studio 未运行或无 embedding 模型。解决：

```bash
# 1. 启动 LM Studio
open -a "LM Studio"

# 2. 加载 embedding 模型
# 推荐: text-embedding-qwen3-embedding-0.6b (Qwen3 0.6B Embedding)

# 3. 启动 API Server（端口 1234）
# 点击 "Start Server" → 选择 "Embedding Only"

# 4. 验证 API
curl -s http://localhost:1234/v1/models | python3 -m json.tool
# 应看到 embedding 模型列表

# 5. 测试语义搜索
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic "测试"
```

**如果不想用语义搜索**：直接使用默认关键词搜索即可，降级是自动的，不影响使用。

---

## 🤖 自动写入


### Q4.5: 自动草稿和自动写入正式经验有什么区别？

**A**: 核心区别：

| 维度 | 自动草稿 | 自动写入正式经验 |
|------|----------|------------------|
| **触发** | before_reset Hook | ❌ 不再自动触发 |
| **输出** | `drafts/draft-*.json` | ❌ 不直接输出 |
| **状态** | `pending_review`（待审核） | N/A |
| **可见性** | 仅 drafts/ 目录 | ❌ 不可搜索 |
| **后续** | 需人工审核 + record.sh | 审核后才写入 |

**历史版本**:
- v2.8.5 及更早：任务成功 → 直接写入 `experiences.md`（自动）
- v2.8.6+：任务成功 → 生成草稿 → 审核 → 手动写入（质量把关）

**为什么改变？** 防止测试对话、临时问题污染经验库，确保入库经验质量。

---

### Q5: 任务成功后为什么没有自动写入正式经验？

**A**: 因为从 v2.8.6 开始采用**两阶段机制**（草稿 → 审核 → 正式）：

```
任务成功 → Hook 生成草稿（drafts/，pending_review）
    ↓
    不直接写入 experiences.md
    ↓
需人工审核 → 执行 record.sh → 才写入正式经验
```

**检查草稿是否生成**:
```bash
ls -la ~/.openclaw/.learnings/drafts/
# 应有 draft-*.json
```

**草稿未生成的可能原因**:
| 原因 | 检查 | 解决 |
|------|------|------|
| Hook 未配置 | `grep rocky-know-how ~/.openclaw/openclaw.json` | 重启网关 |
| 会话未结束 | 无 before_reset 事件 | 结束会话 |
| 纯文档编辑 | `errors` 为空 | 正常（无需记录） |

**手动测试草稿生成**: 安排真实任务，成功后检查 drafts/ 目录。

---

### Q6: 草稿如何转为正式经验？

| 条件 | 说明 | 检查方法 |
|------|------|----------|
| ✅ Hook 已配置 | `openclaw.json` 有 handler 和 events | `grep -A 5 "rocky-know-how" ~/.openclaw/openclaw.json` |
| ✅ 网关已重启 | Hook 需重启生效 | `openclaw gateway status` |
| ✅ 任务确实成功 | Agent 返回成功状态 | 查看会话日志 |
| ✅ 非重复经验 | 去重阈值 70% | 检查 experiences.md 是否已有相似条目 |

**手动测试**:
```bash
# 直接调用 record.sh 验证功能
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "测试问题" "测试过程" "测试方案" "测试预防" "test" "global"

# 查看是否写入
tail -5 ~/.openclaw/.learnings/experiences.md
```

如果手动调用成功但自动不生效 → **Hook 配置问题**，检查网关日志。

---

### Q6: 草稿如何转为正式经验？

**A**: 三步骤流程：

#### 步骤1: 自动草稿（Hook 生成）
任务成功 → before_reset → `drafts/draft-*.json`（状态: pending_review）

#### 步骤2: 审核草稿
**方式A: 批量审核（推荐）**
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/summarize-drafts.sh
cat ~/.openclaw/.learnings/.summarize.log  # 查看建议
# 复制并执行推荐的 record.sh 命令
```
**方式B: 手动处理**
```bash
cat ~/.openclaw/.learnings/drafts/draft-*.json
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "问题" "过程" "方案" "预防" "tags" "area"
```

#### 步骤3: 写入正式经验
执行 `record.sh` → 去重 → 生成 ID → 写入 `experiences.md` → 同步 memory/domains

---

### Q7: 草稿包含什么内容？

**A**: 草稿 JSON 结构：

```markdown
## [EXP-20260424-0121] 问题标题

### 踩坑过程
（任务执行的详细过程、遇到的错误）

### 正确方案
（最终成功的解决方案）

### 预防
（如何避免再次踩坑，最佳实践）

**Tags:** tag1,tag2  # 自动推断或从任务提取
```

**写入位置**:
- `experiences.md` - 主数据库
- `memory.md` - HOT 层摘要（最近7天）
- `domains/{area}.md` - WARM 层（按领域分类，如 infra、wx.newstt）

---

### Q8: 写入的经验如何被搜索到？

**A**: 写入后立即生效（无需重建索引）：

```bash
# 刚写入的经验马上能搜到
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "刚写的问题关键词"

# 向量搜索（如果启用）也会有更新（record.sh 会自动更新向量索引）
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic "相关描述"
```

**注意**: 向量索引更新是实时的，但如果有缓存可能需等待 1-2 秒。

---

## 🏷️ 标签与去重

### Q8: 为什么写入时提示 "已存在相似经验，跳过"？

**A**: 这是去重机制在工作（阈值 70%）：

**去重规则**:
- 问题文本相似度 ≥70% → 拦截
- Tags 完全相同 → 拦截
- 相同 ID → 拦截

**如何绕过**（不推荐）:
```bash
# 如果是不同场景，调整问题描述使其差异化
record.sh "Nginx 502（生产环境）" ...  # vs "Nginx 502（测试环境）"
```

**查看重复项**:
```bash
# 搜索可能重复的经验
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --all | grep -i "502"
```

---

### Q9: Tag 晋升（≥3 次）是如何统计的？

**A**: 统计逻辑：

```bash
# 1. 扫描 experiences.md 和 corrections.md
# 2. 统计每个 Tag 在最近 7 天的使用次数
# 3. ≥3 次 → 触发 promote.sh → 写入 TOOLS.md

# 手动触发晋升检查
bash ~/.openclaw/skills/rocky-know-how/scripts/promote.sh

# 查看 Tag 使用统计
bash ~/.openclaw/skills/rocky-know-how/scripts/stats.sh
```

**Tag 铁律**: 同个 Tag（如 "nginx"）在不同经验中累计出现 ≥3 次，自动晋升为工具诀窍。

---

## ⚡ 向量搜索

### Q10: 向量搜索需要什么环境？

**A**: 需要安装并运行 **LM Studio**：

| 项目 | 要求 |
|------|------|
| 软件 | LM Studio (桌面应用) |
| 模型 | embedding 模型（如 text-embedding-qwen3-embedding-0.6b） |
| 端口 | 1234（默认） |
| API | `http://localhost:1234/v1/embeddings` |

**安装步骤**:
1. 下载 LM Studio (https://lmstudio.ai/)
2. 打开应用 → 搜索 "embedding" 模型
3. 下载 `text-embedding-qwen3-embedding-0.6b` (约 400MB)
4. 点击 "Start Server" → 端口 1234 → Embedding Only 模式

---

### Q11: 向量索引文件在哪里？可以手动删除吗？

**A**: 向量索引位置：
```
~/.openclaw/.learnings/
└── vectors/
    ├── index.json    # 向量索引（ID → embedding）
    ├── meta.json     # 元数据（模型、维度、数量）
    └── tmp/          # 临时目录（重建索引用）
```

**可以删除吗？**
- ✅ 可以删除 `vectors/` 目录（会自动重建）
- 重建命令：`bash ~/.openclaw/skills/rocky-know-how/scripts/clean.sh --rebuild-vectors`
- 注意：重建需重新调用 LM Studio API，耗时较长（每条经验约 0.1-0.3 秒）

---

### Q12: 语义搜索和关键词搜索有什么区别？

**A**: 对比表：

| 维度 | 关键词搜索 | 语义搜索 (`--semantic`) |
|------|-----------|------------------------|
| **匹配方式** | 文本字面匹配 | 向量余弦相似度 |
| **同义词** | ❌ 不匹配 | ✅ "连接不上" ≈ "连接失败" |
| **错误码** | ✅ 精确匹配 | ✅ 也能匹配（语义相近） |
| **速度** | ⚡ 快 (0.1s) | ⏱️ 中 (0.3-0.8s) |
| **依赖** | 无 | LM Studio |
| **推荐场景** | 已知错误码、精确匹配 | 自然语言描述、模糊问题 |

**示例**:
```
查询: "数据库连不上"

关键词搜索:
  ✅ "数据库连接失败"
  ❌ "DB 无法访问"（无"连不上"字眼）

语义搜索:
  ✅ "数据库连接失败"
  ✅ "DB 无法访问"
  ✅ "MySQL 连接被拒绝"
```

---

## 🔒 安全与权限

### Q13: 数据存储在哪里？会泄露隐私吗？

**A**:

**存储位置**:
```
~/.openclaw/.learnings/
├── experiences.md      # 主库（本地文件）
├── memory.md          # HOT 层（本地文件）
├── domains/           # WARM 层（本地文件）
├── vectors/           # 向量索引（本地文件）
└── corrections.md     # 纠正日志（本地文件）
```

**隐私保护**:
- ✅ 纯本地存储，不上传任何数据
- ✅ 无网络请求（除向量搜索调用本地 LM Studio）
- ✅ 只存储经验文本，不收集敏感信息
- ✅ 代码开源可审查（MIT 许可证）

---

### Q14: 多人使用同一台电脑会冲突吗？

**A**: 不会，因为：

1. **文件权限**: `~/.openclaw/` 目录权限为 `700`（仅当前用户可访问）
2. **并发锁**: `.write_lock` 目录锁防止多进程同时写入
3. **命名空间**: 支持 `--area` 和 `--project` 隔离不同项目

**多用户建议**:
- 不同用户使用各自的 Home 目录
- 或使用 `OPENCLAW_STATE_DIR` 环境变量隔离：
  ```bash
  export OPENCLAW_STATE_DIR=/path/to/user1/.openclaw
  ```

---

## 🐛 故障排查

### Q15: 自动写入不生效，如何调试？

**A**: 逐步排查：

```bash
# 1. 检查 Hook 是否加载
grep "rocky-know-how" ~/.openclaw/openclaw.json
# 应看到 handler 和 events

# 2. 查看网关日志
tail -50 ~/.openclaw/logs/gateway.log | grep -i rocky
# 查找错误信息

# 3. 测试手动写入（确认脚本正常）
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "调试测试" "过程" "方案" "预防" "debug" "global"

# 4. 检查写入结果
tail -5 ~/.openclaw/.learnings/experiences.md

# 5. 检查锁目录权限
ls -la ~/.openclaw/.learnings/.write_lock/ 2>/dev/null || echo "无锁（正常）"

# 6. 查看 memory.md 是否同步
tail -5 ~/.openclaw/.learnings/memory.md
```

**常见错误**:
- "❌ 写入冲突" → 有残留锁，删除 `.write_lock/` 目录
- "Permission denied" → 检查目录权限 `chmod 700 ~/.openclaw`
- Hook 未触发 → 重启网关 `openclaw gateway restart`

---

### Q16: `search.sh` 报错 "command not found" 或权限问题？

**A**:

```bash
# 1. 检查脚本是否存在
ls -la ~/.openclaw/skills/rocky-know-how/scripts/search.sh

# 2. 检查执行权限
chmod +x ~/.openclaw/skills/rocky-know-how/scripts/*.sh

# 3. 使用绝对路径调用
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --all
```

---

### Q17: 向量搜索报 "Connection refused" 或超时？

**A**:

```bash
# 1. 检查 LM Studio 是否运行
ps aux | grep -i "LM Studio"

# 2. 测试 API 连通性
curl -v --max-time 3 http://localhost:1234/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model":"text-embedding-qwen3-embedding-0.6b","input":"test"}'

# 3. 查看 LM Studio 日志（应用内）
# 点击 LM Studio 的 "Logs" 标签

# 4. 重启 LM Studio
# 完全退出后重新打开
```

**如果不需要向量搜索**：忽略警告，继续使用关键词搜索即可。

---

## 📊 性能与优化

### Q18: experiences.md 文件太大怎么办？

**A**: rocky-know-how 自动管理：

| 文件 | 大小 | 管理策略 |
|------|------|----------|
| `memory.md` | ≤100 行 | 自动压缩（compact.sh） |
| `experiences.md` | 所有历史 | 不自动删除，可手动清理 |
| `domains/*.md` | 按领域分离 | 避免单文件过大 |
| `archive/` | 30天+未使用 | 自动归档（archive.sh） |

**手动优化**:
```bash
# 1. 压缩 HOT 层
bash ~/.openclaw/skills/rocky-know-how/scripts/compact.sh

# 2. 归档旧条目
bash ~/.openclaw/skills/rocky-know-how/scripts/archive.sh --auto

# 3. 清理测试数据
bash ~/.openclaw/skills/rocky-know-how/scripts/clean.sh --tag test

# 4. 重建向量索引（可选）
bash ~/.openclaw/skills/rocky-know-how/scripts/clean.sh --rebuild-vectors
```

---

### Q19: 搜索速度慢怎么办？

**A**:

**关键词搜索慢**（不应发生）:
```bash
# experiences.md 过大（>10000 行）会影响 grep 速度
# 解决方案：启用向量搜索（--semantic）或归档旧条目
```

**向量搜索慢**:
```bash
# 1. 检查 LM Studio 模型是否在 GPU 上运行
# 推荐使用 GPU 加速的 embedding 模型

# 2. 减少返回结果数
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --semantic --limit 5 "关键词"

# 3. 向量索引过大（>10000 条）时考虑归档
```

---

## 🔄 升级与维护

### Q20: 如何升级到最新版本？

**A**:

```bash
# 方式1: ClawHub 自动升级（推荐）
openclaw skills update rocky-know-how

# 方式2: 手动 git pull
cd ~/.openclaw/skills/rocky-know-how
git pull origin main

# 方式3: 重新安装
cd ~/.openclaw/skills/rocky-know-how
bash scripts/uninstall.sh
# 然后重新克隆/安装

# 无论哪种方式，升级后必须重启网关
openclaw gateway restart
```

---

## 🆘 更多帮助

### 在哪里找到更多信息？

| 资源 | 链接 |
|------|------|
| 技能仓库 | https://gitee.com/rocky_tian/skill |
| 文档索引 | `INDEX.md`（本技能根目录） |
| 版本日志 | `CHANGELOG.md` |
| 问题反馈 | Gitee/GitHub Issues |

### 联系维护者

- **Gitee**: https://gitee.com/rocky_tian/skill
- **GitHub**: https://github.com/rockytian-top/skill
- **ClawHub**: https://clawhub.ai/skills/rocky-know-how

---

**  
**适用版本**: 2.8.0+  
**维护**: rocky-know-how 团队
**最后更新**: 2026-04-24 v2.8.6
