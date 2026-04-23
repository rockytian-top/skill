# 自我反思日志

记录已完成工作的自我反思。每个条目捕捉 agent 从评估自己输出中学到了什么。

## 格式

```
## [日期] — [任务类型]

**What I did:** 简要描述
**Outcome:** 发生了什么（成功、部分、失败）
**Reflection:** 我注意到关于我工作的什么
**Lesson:** 下次要做的不同
**Status:** ⏳ candidate | ✅ promoted | 📦 archived
```

## 示例条目

```
## 2026-02-25 — Mac 迁移后网关配置

**What I did:** 配置 Mac 迁移后的 OpenClaw 网关
**Outcome:** 从终端启动正常，但从 LaunchAgent 启动失败
**Reflection:** 我专注于进程存在，没有检查 LaunchAgent 注册状态
**Lesson:** 迁移后必须检查 LaunchAgent 注册状态，执行 gateway install
**Status:** ✅ promoted to domains/infra.md
```

## 条目

（新条目在此）
