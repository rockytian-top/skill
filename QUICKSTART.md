# 🚀 rocky-know-how 快速入门（v2.8.6）

## 30 秒上手

### 1. 安装（已装跳过）
```bash
openclaw skills install rocky-know-how
```

### 2. 核心工作流（自动）
```
任务失败 2 次 → 自动搜经验 → 成功 → 自动写入 → Tag≥3 → 自动晋升
   ↓              ↓            ↓          ↓           ↓
  search.sh   ← 结果      record.sh  同步       promote.sh
```

### 3. 手动命令
```bash
# 搜经验
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "502" "nginx"

# 写经验（通常自动）
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh "问题" "过程" "方案" "预防" "tag1,tag2" "area"

# 看统计
bash ~/.openclaw/skills/rocky-know-how/scripts/stats.sh
```

---

## 📖 自动写入详解

### 什么是自动写入？

Agent 在任务**成功完成后**，自动将解决方案记录到经验库，无需用户手动执行 `record.sh`。

### 触发条件

| 条件 | 动作 | 说明 |
|------|------|------|
| 任务连续失败 2 次 | 🔍 自动搜索 | 调用 search.sh，查找类似经验 |
| 找到方案并成功 | 📝 自动写入 | 调用 record.sh，写入 experiences.md |
| 同 Tag 使用 ≥3 次 | 🚀 自动晋升 | 调用 promote.sh，写入 TOOLS.md |

### 实际例子

**场景**: 修复 Nginx 502 错误

```
第1次尝试: 改配置 → 失败 ❌
第2次尝试: 重启 php-fpm → 失败 ❌
    ↓ 自动搜索 "502 nginx"
找到经验: EXP-20260420-001 "Nginx 502: restart php-fpm"
    ↓ 按方案执行
第3次尝试: 重启 php-fpm + 调 pm.max_children → 成功 ✅
    ↓ 自动写入（如果是新问题）
写入: experiences.md + memory.md + domains/infra.md
    ↓ 同 Tag "nginx" 使用 3 次后
晋升: TOOLS.md
```

### 配置要求

- ✅ Hook 已配置（install.sh 自动配置）
- ✅ 网关已重启
- ✅ `~/.openclaw/.learnings/` 可写

**验证**:
```bash
grep "rocky-know-how" ~/.openclaw/openclaw.json
# 应看到 handler 和 events 配置
```

---

## 🎯 核心文件

| 文件 | 说明 | 自动更新 |
|------|------|----------|
| `experiences.md` | 主经验库（所有条目） | ✅ record.sh |
| `memory.md` | HOT 层（最近7天，≤100行） | ✅ 同步写入 |
| `domains/*.md` | WARM 层（领域隔离） | ✅ 按 Area 写入 |
| `TOOLS.md` | 晋升经验（Tag≥3） | ✅ promote.sh |
| `index.md` | 索引（行数、更新时间） | ✅ 自动刷新 |

---

## 🔒 安全特性（v2.8.6）

| 特性 | 说明 | 影响 |
|------|------|------|
| 并发锁 | `.write_lock` 目录锁 | 防多进程冲突 |
| 正则转义 | FILTER_DOMAIN 转义 | 防注入 H1 |
| 路径检测 | `../` 和 `\\` 检测 | 防穿越 H2 |
| 标签去重 | 70% 重叠拦截 | 防重复 |

---

## 🛠️ 常用命令速查

```bash
# 搜索
search.sh "关键词"                    # 多关键词 AND
search.sh --tag "tag1,tag2"           # 按标签
search.sh --area infra                # 按领域
search.sh --all                       # 全部

# 写入（通常自动）
record.sh "问题" "过程" "方案" "预防" "tags" "area"

# 管理
stats.sh                              # 统计
promote.sh                            # 晋升检查
compact.sh                            # 压缩
clean.sh --tag test                   # 清理测试数据

# 调试
# 查看 Hook 日志
tail -f ~/.openclaw/logs/gateway.log | grep rocky-know-how

# 查看自动写入记录
tail -50 ~/.openclaw/.learnings/experiences.md
```

---

## 📚 完整文档

- **README.md** - 功能总览 + 版本历史
- **setup.md** - 安装配置 + 验证步骤
- **operations.md** - 操作手册 + 自动流程
- **learning.md** - 学习机制 + 触发条件
- **boundaries.md** - 安全边界 + 红旗警告
- **scaling.md** - 扩展规则 + 压缩策略
- **heartbeat-rules.md** - 心跳规则

---

**版本**: 2.8.3（2026-04-24）  
**状态**: ✅ 生产就绪  
**自动写入**: ✅ 已启用（Hook 集成）
