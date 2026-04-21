# 架构说明

## 分层存储

```
~/.openclaw/.learnings/
├── memory.md           # 🔥 HOT: ≤100行，始终加载
├── index.md            # 主题索引
├── heartbeat-state.md  # 心跳状态
├── corrections.md      # 纠正日志
├── reflections.md      # 自我反思
├── domains/            # 🌡️ WARM: 领域隔离
│   ├── infra.md
│   └── code.md
├── projects/           # 🌡️ WARM: 项目隔离
│   └── wx.newstt.md
└── archive/            # ❄️ COLD: 归档
```

## 数据流

```
用户反馈 / 任务完成
        ↓
   记录纠正 → corrections.md
        ↓
   经验写入 → experiences.md (v1兼容)
        ↓
   Tag统计 → promote.sh → 晋升HOT → memory.md
        ↓
   定期心跳 → demote.sh/compact.sh → 降级/压缩
```

## 与 self-improving 对比

| | self-improving | rocky-know-how |
|--|---------------|----------------|
| 存储 | 纯文档 | 脚本驱动 |
| 搜索 | agent 理解 | 精确匹配 |
| 分层 | 无 | HOT/WARM/COLD |
| 晋升 | 手动 | 自动统计 |
