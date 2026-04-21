# rocky-know-how 安装指南

## 首次安装

### 1. 创建记忆目录结构

```bash
mkdir -p ~/.openclaw/.learnings/{domains,projects,archive}
```

### 2. 初始化核心文件

创建 `~/.openclaw/.learnings/memory.md`（HOT 层）：

```bash
cat > ~/.openclaw/.learnings/memory.md << 'EOF'
# Memory (HOT Tier)

## 已确认偏好

## 活跃模式

## 最近（最近7天）

EOF
```

创建 `~/.openclaw/.learnings/corrections.md`（纠正日志）：

```bash
cat > ~/.openclaw/.learnings/corrections.md << 'EOF'
# 纠正日志

| 日期 | 我哪里错了 | 正确答案 | 状态 |
|------|-----------|---------|------|
EOF
```

创建 `~/.openclaw/.learnings/index.md`（索引）：

```bash
cat > ~/.openclaw/.learnings/index.md << 'EOF'
# 记忆索引

| 文件 | 行数 | 最后更新 |
|------|------|---------|
| memory.md | 0 | — |
| corrections.md | 0 | — |
EOF
```

创建 `~/.openclaw/.learnings/heartbeat-state.md`（心跳状态）：

```bash
cat > ~/.openclaw/.learnings/heartbeat-state.md << 'EOF'
# Self-Improving Heartbeat State

last_heartbeat_started_at: never
last_reviewed_change_at: never
last_heartbeat_result: never

## Last actions
- none yet
EOF
```

创建 `~/.openclaw/.learnings/reflections.md`（自我反思）：

```bash
cat > ~/.openclaw/.learnings/reflections.md << 'EOF'
# 自我反思日志

## (新条目在此)

EOF
```

### 3. 保留 v1 数据（向后兼容）

如果已有 `experiences.md`，保留不动：

```bash
# 检查是否存在
ls ~/.openclaw/.learnings/experiences.md
```

### 4. 添加 SOUL.md 引导

在 `SOUL.md` 中添加：

```markdown
**经验诀窍 (rocky-know-how)**
失败 ≥2 次 → 搜经验诀窍（~/.openclaw/.learnings/experiences.md）
解决后 → 写入经验诀窍 + 同步到 corrections.md
30 天同 Tag ≥3 次 → 晋升 HOT
重要工作完成后 → 记录自我反思到 reflections.md
使用 ~/.openclaw/.learnings/ 的分层记忆系统。
```

### 5. 验证安装

```bash
# 运行统计面板
bash ~/.openclaw/workspace-fs-daying/skills/rocky-know-how/scripts/stats.sh
```

预期输出：
```
📊 rocky-know-how 经验诀窍统计

🔥 HOT (始终加载):
  memory.md: 0 条目

🌡️ WARM (按需加载):
  domains/: 0 文件
  projects/: 0 文件

❄️ COLD (归档):
  archive/: 0 文件

经验诀窍 (v1兼容):
  experiences.md: X 条
```

### 6. 添加心跳引导

在 `HEARTBEAT.md` 中添加：

```markdown
## 经验诀窍检查 (rocky-know-how)

- 读取 `./skills/rocky-know-how/heartbeat-rules.md`
- 使用 `~/.openclaw/.learnings/heartbeat-state.md` 记录运行标记和操作备注
- 如果 `~/.openclaw/.learnings/` 内没有文件变更，返回 `HEARTBEAT_OK`
```
