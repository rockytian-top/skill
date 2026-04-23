# 📑 rocky-know-how 文档导航 (v2.8.14)

## 🚀 快速开始（新用户必读）

| 文档 | 用途 | 阅读时间 |
|------|------|----------|
| **[QUICKSTART.md](./QUICKSTART.md)** | 30 秒了解核心功能 | 5 分钟 |
| **[README.md](./README.md)** | 功能总览 + 安装 + 示例 | 15 分钟 |
| **[setup.md](./setup.md)** | 详细安装配置 + 验证步骤 | 10 分钟 |

**建议顺序**: QUICKSTART → README → setup（验证安装）

---

## 📚 完整文档地图

### 🎯 核心功能详解

| 文档 | 内容 | 适合人群 |
|------|------|----------|
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | 🆕 完整架构设计（组件/数据流/Hook/存储/安全/扩展） | 开发者、架构师 |
| **[SKILL-GUIDE.md](./SKILL-GUIDE.md)** | 🆕 **完整技能使用指南 (20KB)** - 12章节全覆盖 | 所有用户 |
| **[README.md](./README.md)** | 功能特性列表、安全保障、脚本概览 | 所有用户 |
| **[README_EN.md](./README_EN.md)** | English version | 英文用户 |
| **[advanced-features.md](./advanced-features.md)** | 🆕 三大核心创新技术深挖 | 高级用户、开发者 |
| **[QUICKSTART.md](./QUICKSTART.md)** | 快速入门 + 触发条件 + 验证步骤 | 新用户 |

### 🔧 操作与配置

| 文档 | 内容 | 用途 |
|------|------|------|
| **[setup.md](./setup.md)** | 安装指南、Hook 配置、验证方法 | 安装/卸载 |
| **[operations.md](./operations.md)** | 所有命令详解、自动流程、场景示例 | 日常使用 |
| **[learning.md](./learning.md)** | 学习机制、触发条件、标签系统 | 理解原理 |
| **[boundaries.md](./boundaries.md)** | 安全边界、红旗警告、安全更新 | 安全审计 |
| **[scaling.md](./scaling.md)** | 压缩规则、存储策略、规模阈值 | 运维部署 |

### 📊 数据与监控

| 文档 | 内容 | 说明 |
|------|------|------|
| **[heartbeat-rules.md](./heartbeat-rules.md)** | 心跳检查规则、压缩触发逻辑 | 运维人员 |
| **[HEARTBEAT.md](./HEARTBEAT.md)** | Heartbeat 配置模板 | 管理员 |
| **memory.md** | HOT 层经验（≤100 行） | 运行时加载 |
| **experiences.md** | 主经验库（所有历史条目） | 数据存储 |
| **corrections.md** | 纠正日志（用户反馈记录） | 调试用 |

### 📈 版本与变更

| 文档 | 内容 | 更新频率 |
|------|------|----------|
| **[CHANGELOG.md](./CHANGELOG.md)** | 详细版本历史、修复列表 | 每次发布 |
| **[SKILL.md](./SKILL.md)** | 技能元数据（版本、描述、依赖） | 每次发布 |
| **VERSION** | 当前版本号（纯文本） | 每次发布 |
| **_meta.json** | ClawHub 元数据（ownerId、slug） | 每次发布 |

---

## 🎯 按角色查阅

### 👨‍💻 开发工程师（大杰）
```
必读:
1. advanced-features.md - 理解向量搜索和自动降级
2. operations.md - 所有脚本命令
3. boundaries.md - 安全边界（避免踩坑）

选读:
- learning.md - 标签系统
- scaling.md - 压缩策略
```

### 🛠️ 运维工程师（大青）
```
必读:
1. setup.md - 安装部署、Hook 配置
2. heartbeat-rules.md - 心跳监控规则
3. scaling.md - 存储优化、归档策略

选读:
- boundaries.md - 安全检查清单
- CHANGELOG.md - 版本升级内容
```

### 👩‍💼 产品经理/测试（大平、大朵）
```
必读:
1. QUICKSTART.md - 30 秒了解核心价值
2. README.md - 功能特性总览

选读:
- operations.md - 了解使用场景
- advanced-features.md - 理解技术优势
```

---

## 🔍 按任务快速查找

| 任务 | 查阅文档 | 具体章节 |
|------|---------|---------|
| **安装技能** | setup.md | "🚀 快速安装" |
| **理解架构** | ARCHITECTURE.md | "整体架构图"、"Hook时序"、"数据流" |
| **验证功能** | setup.md | "✅ 验证安装" |
| **搜索经验** | operations.md | "🔍 搜索经验" 表格 |
| **理解自动草稿** | README.md、advanced-features.md | "自动草稿机制"、"两阶段设计" |
| **审核草稿** | operations.md | "草稿审核流程" |
| **写入正式经验** | operations.md | "阶段3: 写入正式经验" |
| **配置向量搜索** | advanced-features.md | 第 2 章 "配置向量搜索" |
| **Hook 配置** | setup.md | "🔧 Hook 配置" |
| **标签晋升** | learning.md | "Tag晋升铁律" |
| **安全加固** | boundaries.md | "🚨 红旗警告" |
| **版本升级** | CHANGELOG.md | 最新版本条目 |
| **心跳检查** | heartbeat-rules.md | "心跳流程" 图示 |
| **压缩触发** | scaling.md | "🗜️ 压缩规则" |

---

## 📖 文档说明

### 文档版本
所有文档版本号与技能版本同步：
- **当前版本**: 2.8.6 (2026-04-24)
- 每次发布更新 `CHANGELOG.md`、`SKILL.md`、`VERSION`

### 文档结构
```
rocky-know-how/
├── README.md              # 入口文档（功能总览）
├── README_EN.md           # 英文版
├── QUICKSTART.md          # 快速入门
├── advanced-features.md   # 高级特性（三大核心创新）
├── setup.md               # 安装配置
├── operations.md          # 操作手册
├── learning.md            # 学习机制
├── boundaries.md          # 安全边界
├── scaling.md             # 扩展规则
├── heartbeat-rules.md     # 心跳规则
├── CHANGELOG.md           # 版本历史
├── SKILL.md               # 技能元数据
├── _meta.json             # ClawHub 元数据
└── VERSION                # 版本号文件
```

### 维护规范
- ✅ 每次功能更新必须同步更新对应文档
- ✅ CHANGELOG.md 必须详细记录修复内容和影响范围
- ✅ README.md 的"功能特性"必须始终与代码一致
- ✅ 新增脚本必须更新 operations.md 的"脚本列表"表格

---

## 💡 核心概念速查

| 概念 | 说明 | 文档 |
|------|------|------|
| **自动写入** | 任务成功后自动记录到 experiences.md | advanced-features.md Ch1 |
| **向量搜索** | 基于 embedding 的语义搜索 | advanced-features.md Ch2 |
| **自动降级** | 无 embedding 模型时切关键词搜索 | advanced-features.md Ch3 |
| **Tag 晋升** | 同 Tag 使用 ≥3 次 → TOOLS.md | learning.md |
| **三层存储** | HOT (memory.md) + WARM (domains/) + COLD (archive/) | scaling.md |
| **Hook 事件** | agent:bootstrap, before_compaction, after_compaction, before_reset | setup.md |
| **并发锁** | .write_lock 目录锁防止多进程冲突 | boundaries.md |
| **去重阈值** | 70% 标签重叠即拦截 | learning.md |

---

## 🆘 获取帮助

| 问题 | 解决方案 | 文档 |
|------|---------|------|
| 安装失败 | 检查 Hook 配置、权限问题 | setup.md "故障排查" |
| 搜索无结果 | experiences.md 为空，先手动写入 | operations.md "写入经验" |
| 向量搜索不可用 | LM Studio 未启动或模型未加载 | advanced-features.md "故障排查" |
| 自动写入不生效 | Hook 未配置或网关未重启 | setup.md "验证安装" |
| 并发写入冲突 | 检查 .write_lock 目录权限 | boundaries.md "并发安全" |
| 版本混乱 | 检查 VERSION、_meta.json、SKILL.md | CHANGELOG.md |

---

## 📝 贡献与反馈

- **Bug 报告**: 在 Gitee/GitHub Issues 提交
- **功能建议**: 提交 Issue 或 PR
- **文档改进**: PR 欢迎，需保持版本号一致

---

**  
**维护者**: rocky-know-how 团队  
**状态**: ✅ 生产就绪
**最后更新**: 2026-04-24 v2.8.14
