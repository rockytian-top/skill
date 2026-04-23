# 📚 rocky-know-how

> OpenClaw Learning Knowledge Skill v2.8.12 — Search on failure, write after solving, learnings shared across agents

[English](./README_EN.md) | [完整使用指南](./SKILL-GUIDE.md)

---

## ✨ 功能特性

### 🎯 三大核心创新

1. **🤖 全自动草稿审核** — Hook 自动生成草稿 → `auto-review.sh` 一键审核写入
2. **🔍 向量搜索双引擎** — 语义搜索 + 关键词搜索，LM Studio 可用时启用向量
3. **⚡ 自动降级** — LM Studio 不可用自动切回关键词搜索

---

### 基础功能

- 🔍 **智能搜索** — 多关键词 AND 匹配 + 相关度评分排序 + 领域/项目过滤
- 🤖 **全自动审核** — `auto-review.sh` 草稿→审核→写入→归档全自动
- 🏷️ **标签/领域筛选** — `--tag` `--area` `--project` 精确过滤
- 🔄 **自动去重** — 问题文本 + Tags 组合去重（阈值 70%）
- 📝 **同步原生记忆** — 写入 memory.md，memory_search 可搜
- 🌙 **Dreaming 整合** — 标记注释，供 Dreaming 阶段分析
- 📊 **Tag晋升铁律** — 同 Tag ≥3次/7天自动写入 TOOLS.md
- 📥 **历史导入** — 从 memory 批量提取教训
- 🗄️ **自动归档** — 超过30天自动归档
- 🌐 **跨 agent 共享** — 全局存储，所有 agent 通用
- 🔒 **安全加固** — 路径穿越检测、正则转义、输入验证
- ⚡ **并发安全** — 目录锁保护，多进程写入不冲突

---

## 🔄 全自动工作流

```
任务失败 → search.sh 搜索经验
    ↓
找到答案 → 按方案执行 → 成功
    ↓
before_reset Hook → 自动生成草稿 (drafts/)
    ↓
auto-review.sh → 扫描草稿 → 搜索同类 → 自动新增/追加
    ↓
写入 experiences.md → 归档草稿 → 完成 ✅
```

**无需人工干预**，从草稿到正式经验全自动完成。

---

## 📦 脚本列表

| 脚本 | 说明 | 优先级 |
|------|------|--------|
| **auto-review.sh** | 🆕 **全自动草稿审核**（推荐） | ⭐⭐⭐ |
| search.sh | 搜索经验 | ⭐⭐⭐ |
| record.sh | 写入新经验 | ⭐⭐⭐ |
| summarize-drafts.sh | 扫描草稿生成建议（半自动） | ⭐⭐ |
| append-record.sh | 追加到已有经验 | ⭐⭐ |
| update-record.sh | 更新已有经验 | ⭐⭐ |
| promote.sh | Tag晋升检查 | ⭐⭐ |
| demote.sh | 降级不常用经验 | ⭐ |
| compact.sh | 压缩去重 | ⭐⭐ |
| archive.sh | 归档旧数据 | ⭐ |
| stats.sh | 统计面板 | ⭐ |
| clean.sh | 清理垃圾 | ⭐ |
| import.sh | 导入历史教训 | ⭐ |

---

## 🚀 快速开始

### 1. 安装

```bash
# ClawHub（推荐）
openclaw skills install rocky-know-how

# 或手动
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

### 2. 搜索经验

```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh nginx 502
```

### 3. 全自动审核草稿

```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/auto-review.sh
```

### 4. 手动写入经验

```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "Nginx 502 错误" \
  "重启nginx无效，检查php-fpm进程发现消失" \
  "重启php-fpm + 调整max_children" \
  "定期监控php-fpm进程数" \
  "nginx,502,php-fpm" \
  "infra"
```

---

## 🔧 Hook 配置

install.sh 会自动配置，无需手动操作。

4个事件：
- `agent:bootstrap` — 启动时注入经验提醒
- `before_compaction` — 保存会话状态
- `after_compaction` — 记录会话总结
- `before_reset` — **生成草稿**（核心）

---

## 🔒 安全保障

| 措施 | 说明 |
|------|------|
| ✅ 并发写入锁 | `.write_lock` 目录锁 |
| ✅ 输入严格验证 | ID 格式、路径、长度全检查 |
| ✅ 正则元字符转义 | 防注入攻击 |
| ✅ 路径穿越检测 | `../` 和 `\` 全面拦截 |
| ✅ 代码开源 | MIT 许可证 |

---

## 📂 存储结构

```
~/.openclaw/.learnings/
├── experiences.md          ← 主经验库
├── memory.md              ← HOT层（≤100行）
├── domains/               ← WARM层（领域隔离）
│   ├── infra.md
│   ├── wx.newstt.md
│   ├── code.md
│   └── global.md
├── drafts/                ← 草稿（待审核）
│   └── archive/           ← 已处理草稿归档
└── vectors/               ← 向量索引（LM Studio）
```

---

## 📖 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| **2.8.12** | 2026-04-24 | ✅ 全自动流程测试验证通过；SKILL-GUIDE.md (20KB) 完整指南 |
| **2.8.11** | 2026-04-24 | SKILL-GUIDE.md 完整技能使用指南 (12章节) |
| **2.8.10** | 2026-04-24 | 🆕 auto-review.sh 全自动草稿审核脚本 |
| **2.8.9** | 2026-04-24 | ARCHITECTURE.md 完整架构设计 (19.8KB) |
| **2.8.8** | 2026-04-24 | 两阶段机制文档更正 |
| 2.8.3 | 2026-04-24 | 🔒 安全加固：H1/H2/M1 漏洞修复 |
| 2.8.2 | 2026-04-24 | 🔐 并发锁、Hook 路径动态化 |
| 2.7.1 | 2026-04-21 | 支持 OpenClaw 2026.4.21 |

---

## 🔗 链接

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
- [完整使用指南](./SKILL-GUIDE.md)
- [架构设计](./ARCHITECTURE.md)

---

**维护人**: 大颖 (fs-daying)  
**版本**: v2.8.12
