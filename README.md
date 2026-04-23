# 📚 rocky-know-how

> OpenClaw 经验积累技能 v2.8.14  
> 核心理念：**搜索失败时，记录解决后经验，团队共享复用**

[English](./README_EN.md) | [完整指南](./SKILL-GUIDE.md) | [架构设计](./ARCHITECTURE.md)

---

## 🎯 核心创新（重点突出）

### 1. 🤖 Hook 全自动草稿审核（v2.8.14 新增）

**before_reset Hook 触发后自动完成**：
```
任务失败 → 尝试解决 → 成功
    ↓
before_reset Hook 触发
    ↓
1. 自动生成草稿 (drafts/draft-*.json)
2. 自动调用 auto-review.sh
3. 自动审核 → 搜索同类 → 新增/追加
4. 自动写入 experiences.md ✅
5. 自动归档草稿 ✅
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

### 全自动草稿审核（Hook 自动调用）
```bash
# 无需手动运行！before_reset Hook 自动触发
# auto-review.sh 扫描草稿 → 审核 → 写入 → 归档
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
│ 阶段1: 自动草稿生成（Hook）                                 │
├─────────────────────────────────────────────────────────────┤
│ before_reset 触发 → generateDraft() → drafts/draft-*.json │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ 阶段2: 自动审核写入（Hook 调用 auto-review.sh）           │
├─────────────────────────────────────────────────────────────┤
│ 扫描草稿 → 提取关键词 → 搜索同类 → 新增/追加 → 归档      │
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
| 自动降级 | LM Studio 不可用自动切关键词 |

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
├── drafts/                ← 草稿（Hook 自动生成）
│   └── archive/           ← 已处理草稿归档
└── vectors/               ← 向量索引
```

---

## 📖 版本历史

| 版本 | 日期 | 亮点 |
|------|------|------|
| **v2.8.14** | 2026-04-24 | 🤖 **Hook 全自动集成**（核心创新） |
| v2.8.13 | 2026-04-24 | 根目录文档更新 |
| v2.8.12 | 2026-04-24 | 全自动测试验证通过 |
| v2.8.11 | 2026-04-24 | SKILL-GUIDE.md 完整指南 |
| v2.8.10 | 2026-04-24 | auto-review.sh 全自动审核 |
| v2.8.9 | 2026-04-24 | ARCHITECTURE.md 架构设计 |

---

## 🔗 链接

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/skill.git)
- [Gitee](https://gitee.com/rocky_tian/skill.git)

---

**维护人**: 大颖 (fs-daying) | **版本**: v2.8.14
