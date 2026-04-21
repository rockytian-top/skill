# HOT Memory — 模板

> 首次使用此技能时在 `~/.openclaw/.learnings/memory.md` 创建。
> 保持 ≤100 行。最常用的模式在这里。

## 示例条目

```markdown
## 偏好
- Code style: Prefer explicit over implicit
- Communication: Direct, no fluff
- Time zone: Asia/Shanghai

## 模式（从纠正晋升）
- Always use TypeScript strict mode
- Prefer pnpm over npm
- Format: ISO 8601 for dates

## 项目默认值
- Tests: Jest with coverage >80%
- Commits: Conventional commits format
```

## 使用

agent 将：
1. 每个会话加载此文件
2. 模式 7 天内使用 3 次 → 晋升 HOT
3. 30 天未使用 → 降级到 WARM
4. 永不超过 100 行（自动压缩）
