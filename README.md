# 📚 rocky-know-how

> OpenClaw 经验积累技能 v2.9.2
> 核心理念：**搜索失败时，记录解决后经验，团队共享复用**

[English](./README_EN.md) | [完整指南](./SKILL-GUIDE.md) | [架构设计](./ARCHITECTURE.md)

---

## 🎯 核心创新（重点突出）

### 1. 🤖 LLM 双判断全自动写入（v2.9.2）

**ctx 阈值触发压缩后自动完成**：
```
压缩触发 → before_compaction 提取原始上下文 → pending/
压缩发生
after_compaction → 处理 pending
    ↓
LLM1 判断 worth — 是否值得写？
    ↓ worth=true
LLM2 判断 create/append — 新增还是追加？
    ↓
写入 experiences.md ✅
归档 pending + draft ✅
```

**无需人工干预，端到端全自动！**

### 2. 🔍 向量搜索双引擎

- LM Studio 可用时 → 向量语义搜索
- LM Studio 不可用 → 关键词搜索（自动降级）
- 搜索结果相关度排序

### 3. 📊 Tag 晋升铁律

- 同一 Tag 7天内使用 ≥3 次
- 自动晋升到 TOOLS.md
- 常用问题快速访问

---

## 🚀 快速开始

### 安装（一键）
```bash
openclaw skills install rocky-know-how
```

### 搜索经验
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh nginx 502
```

### 写入经验（手动）
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "问题描述" "踩坑过程" "正确方案" "预防措施" "tag1,tag2" "area"
```

### 全自动写入（Hook 自动，无需手动）
```bash
# 无需手动运行！ctx 阈值触发压缩后自动完成
# before_compaction → after_compaction → LLM双判断 → 写入 experiences
```

---

## 📦 脚本列表

| 脚本 | 说明 | 触发方式 |
|------|------|----------|
| **auto-review.sh** | 🤖 全自动草稿审核（**推荐**） | Hook 自动调用 |
| search.sh | 搜索经验 | 手动 |
| record.sh | 写入新经验 | 手动 |
| summarize-drafts.sh | 扫描草稿生成建议 | 手动 |
| append-record.sh | 追加到已有经验 | auto-review.sh 调用 |
| update-record.sh | 更新已有经验 | 手动 |
| promote.sh | Tag 晋升检查 | cron/手动 |
| compact.sh | 压缩去重 | cron/手动 |
| archive.sh | 归档旧数据 | cron/手动 |

---

## 🔄 完整工作流

```
┌─────────────────────────────────────────────────────────────┐
│ 阶段1: before_compaction — 提取原始上下文                  │
├─────────────────────────────────────────────────────────────┤
│ 提取 task + tools + errors → pending/*.json               │
│ autoSearch() → 注入相关经验到上下文                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 阶段2: after_compaction — LLM双判断写入                   │
├─────────────────────────────────────────────────────────────┤
│ processPendingItem()                                        │
│   ├── LLM1 callLLMJudge() — worth=true/false?           │
│   ├── 生成草稿 drafts/draft-*.json                         │
│   ├── searchSimilarExperiences() — 读相似经验全文          │
│   └── LLM2 decideCreateOrAppend() — create/append?       │
│         ├── append → append-record.sh                    │
│         └── create → record.sh                            │
│   归档 draft → drafts/archive/                            │
│   归档 pending → pending/archive/                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔒 安全与性能

| 特性 | 说明 |
|------|------|
| 并发安全 | `.write_lock` 目录锁 |
| 输入验证 | ID格式、路径、长度全检查 |
| 正则转义 | 防注入攻击 |
| 路径穿越检测 | `../` 和 `\` 全面拦截 |
| LLM 降级 | 无配置时退回到关键词判断 |
| 自动归档 | draft + pending 处理后均归档 |

---

## 📂 存储结构

```
~/.openclaw/.learnings/
├── experiences.md          ← 主经验库
├── memory.md              ← HOT层（≤100行）
├── domains/               ← WARM层（领域隔离）
│   ├── infra.md           ← 运维相关
│   ├── code.md            ← 开发相关
│   └── global.md          ← 通用
├── drafts/                ← 草稿（处理后归档）
│   └── archive/           ← 已归档草稿
├── pending/                ← 待处理上下文（处理后归档）
│   └── archive/            ← 已归档 pending
└── vectors/               ← 向量索引
```

---

## 📖 版本历史

| 版本 | 日期 | 亮点 |
|------|------|------|
| **v2.9.2** | 2026-04-24 | 🤖 LLM双判断create/append替代关键词匹配 |
| v2.9.2 | 2026-04-24 | draft + pending 双归档避免目录膨胀 |
| v2.9.2 | 2026-04-24 | block regex修复，解析经验正文 |
| v2.9.1 | 2026-04-24 | 🎯 直接处理模式 + 移除硬编码模型 |
| v2.9.1 | 2026-04-24 | after_compaction LLM双判断集成 |
| v2.9.0 | 2026-04-24 | 压缩前生成草稿/压缩后写入正式经验 |

---

## 🔗 链接

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/skill.git)
- [Gitee](https://gitee.com/rocky_tian/skill.git)

---

**维护人**: 大颖 (fs-daying) | **版本**: v2.9.2
