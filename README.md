# 📦 OpenClaw Rocky Skills

> Rocky 的 OpenClaw 技能集合 / Rocky's OpenClaw Skill Collection

## 技能列表 / Skills

| 技能 / Skill | 版本 / Version | 说明 / Description |
|------|------|------|
| [rocky-know-how](./rocky-know-how/) | 1.3.5 | 经验诀窍 — 失败自动搜，解决自动写，经验跨 agent 共享 / Experience know-how — auto-search on failures, auto-record on success, shared across all agents |

### rocky-know-how 简介

在 AI Agent 的日常工作中，经常遇到"同一个坑踩两次"的问题。rocky-know-how 解决这个问题：**当 Agent 失败≥2次时，自动搜索历史经验；解决后自动写入新经验。** 下次再碰到类似问题，直接查到答案，不再重复踩坑。

In AI Agent workflows, the same mistakes get repeated. rocky-know-how solves this: **when an Agent fails ≥2 times, it auto-searches historical experiences; after solving, it auto-records the new experience.** Next time, the answer is found instantly.

详细说明请查看 → [rocky-know-how/README.md](./rocky-know-how/README.md)

For details → [rocky-know-how/README.md](./rocky-know-how/README.md)

---

## 安装 / Installation

```bash
# ClawHub（推荐 / Recommended）
openclaw skills install rocky-know-how

# 手动 / Manual
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills/rocky-know-how
bash scripts/install.sh
```

## 许可证 / License

MIT License
