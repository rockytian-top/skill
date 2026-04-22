# rocky-know-how 完整使用手册

**版本**: v2.6.0 | **适用系统**: macOS / Linux / Windows

---

## 📚 简介

rocky-know-how 是一个经验诀窍技能，帮助 AI Agent 在失败中学习、在成功后记录。

核心功能：
- 🔍 **失败≥2次时** → 自动搜索经验库
- ✍️ **问题解决后** → 自动记录到经验库
- 📊 **Tag晋升机制** → 常用经验自动升级
- 🧹 **自动清理** → 测试数据定期清理

---

## 🚀 安装

### 方式一：自动安装

```bash
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
./scripts/install.sh
```

### 方式二：手动安装

1. 复制 `scripts/` 目录到 `~/.openclaw/skills/rocky-know-how/`
2. 配置 Hook（可选，支持 OpenClaw 2026.4.21+）：
   ```bash
   # 在 openclaw.json 中添加：
   "hooks": {
     "internal": {
       "load": {
         "extraDirs": [
           "~/.openclaw/skills/rocky-know-how/hooks"
         ]
       }
     }
   }
   ```

---

## 📁 数据结构

```
~/.openclaw/.learnings/
├── experiences.md    # 主经验库（所有经验）
├── corrections.md    # 纠正日志
├── memory.md         # HOT层（频繁使用，始终加载）
├── domains/          # WARM层（按领域分类）
│   ├── code.md
│   ├── general.md
│   └── infra.md
├── projects/         # WARM层（按项目分类）
└── archive/          # COLD层（归档）
```

---

## 🎯 核心命令

### 1. 搜索经验 `search.sh`

```bash
# 基本搜索
bash scripts/search.sh "nginx 502"

# 查看全部
bash scripts/search.sh --all

# 摘要模式
bash scripts/search.sh --preview "关键词"

# 按标签筛选
bash scripts/search.sh --tag "php-fpm"

# 按领域筛选
bash scripts/search.sh --area "infra"
```

### 2. 记录经验 `record.sh`

```bash
# 基本记录
bash scripts/record.sh "问题描述" "踩坑过程" "正确方案" "预防措施" "tag1,tag2" "area"

# 预览模式（不实际写入）
bash scripts/record.sh --dry-run "问题" "踩坑" "方案" "预防" "tags" "area"

# 指定命名空间
bash scripts/record.sh --namespace "project:myapp" "问题" "踩坑" "方案" "预防" "tags" "area"
```

### 3. 统计面板 `stats.sh`

```bash
bash scripts/stats.sh
```

输出示例：
```
╔════════════════════════════════════════════╗
║  📊 rocky-know-how 经验诀窍统计面板 v2.1.0 ║
╚════════════════════════════════════════════╝

🔥 HOT (始终加载)
  memory.md: 14 条目

🌡️ WARM (按需加载)
  domains/: 3 文件
  projects/: 2 文件

📚 v1 主数据 (experiences.md)
  总条目: 45
```

### 4. Tag晋升检查 `promote.sh`

```bash
bash scripts/promote.sh
```

### 5. 清理测试数据 `clean.sh`

```bash
# 预览
bash scripts/clean.sh --dry-run

# 执行清理
bash scripts/clean.sh
```

---

## 🔄 v2.6.0 更新

### 支持 OpenClaw 2026.4.21 新 Hook

| Hook | 触发时机 | 功能 |
|------|----------|------|
| `before_compaction` | 会话压缩前 | 保存当前任务状态到临时文件 |
| `after_compaction` | 会话压缩后 | 读取状态，记录会话总结到 session-summaries.md |
| `before_reset` | 会话重置前 | 保存重要信息 |

### 去重逻辑优化

- **旧逻辑**：Tags重叠≥60% + 文字相似度≥70% 才拦截
- **新逻辑**：Tags重叠≥50% 直接拦截
- **原因**：中文词汇分割导致相似度计算错误

---

## 🏷️ Tag 晋升规则

| 条件 | 晋升结果 |
|------|----------|
| 30天内同一Tag出现≥3次 | → HOT层 `memory.md` |
| 30天无访问 | → 自动降级到COLD层 |

---

## 📋 经验条目格式

```markdown
## [EXP-20260422-001] 问题标题

**Area**: infra
**Failed-Count**: ≥2
**Tags**: nginx, 502, php-fpm
**Created**: 2026-04-22 10:00:00
**Namespace**: global

### 问题
问题描述

### 踩坑过程
第1次: ... → 失败
第2次: ... → 失败

### 正确方案
正确的解决方法

### 预防
如何避免再次踩坑
```

---

## ⚙️ 配置

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `OPENCLAW_STATE_DIR` | 状态目录 | `~/.openclaw` |
| `OPENCLAW_WORKSPACE` | 工作区目录 | 自动推断 |
| `OPENCLAW_SESSION_KEY` | 会话Key | 自动获取 |

### Hook 配置（可选）

在 `openclaw.json` 中添加：

```json
{
  "hooks": {
    "internal": {
      "load": {
        "extraDirs": [
          "~/.openclaw/skills/rocky-know-how/hooks"
        ]
      }
    }
  }
}
```

---

## 🔗 相关链接

- **Gitee**: https://gitee.com/rocky_tian/skill
- **GitHub**: https://github.com/rockytian-top/skill
- **ClawHub**: https://clawhub.ai/skills/rocky-know-how

---

## 📄 许可

MIT License

---

_最后更新: 2026-04-22 v2.6.0_
