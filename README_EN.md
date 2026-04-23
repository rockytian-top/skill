# 📚 rocky-know-how

> OpenClaw Learning Knowledge Skill v2.8.14  
> Core: **Search on failure, write after solving, learnings shared across agents**

[English](./README_EN.md) | [Complete Guide](./SKILL-GUIDE.md) | [Architecture](./ARCHITECTURE.md)

---

## 🎯 Core Innovations

### 1. 🤖 Hook Fully Automatic Draft Review (v2.8.14 NEW)

**before_reset Hook automatically triggers**:
```
Task fails → Try solutions → Success
    ↓
before_reset Hook triggers
    ↓
1. Auto generate draft (drafts/draft-*.json)
2. Auto call auto-review.sh
3. Auto review → Search similar → Create/Append
4. Auto write to experiences.md ✅
5. Auto archive draft ✅
```

**Zero manual intervention, fully end-to-end automated!**

### 2. 🔍 Dual Search Engines

- LM Studio available → Vector semantic search
- LM Studio unavailable → Keyword search (auto-fallback)
- Results ranked by relevance

### 3. 📊 Tag Promotion Rule

- Same Tag used ≥3 times in 7 days
- Auto-promote to TOOLS.md
- Fast access to common issues

---

## 🚀 Quick Start

### Install (One-command)
```bash
openclaw skills install rocky-know-how
```

### Search Experience
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh nginx 502
```

### Write Experience (Manual)
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "Problem" "Error encountered" "Solution" "Prevention" "tag1,tag2" "area"
```

### Fully Automatic Draft Review (Hook Auto-triggered)
```bash
# No manual run needed! before_reset Hook triggers automatically
# auto-review.sh: scan → review → write → archive
```

---

## 📦 Script List

| Script | Description | Trigger |
|--------|-------------|---------|
| **auto-review.sh** | 🤖 **Fully Automatic Draft Review** (Recommended) | Hook auto |
| search.sh | Search experiences | Manual |
| record.sh | Write new experience | Manual |
| summarize-drafts.sh | Scan drafts, generate suggestions | Manual |
| append-record.sh | Append to existing experience | Called by auto-review.sh |
| update-record.sh | Update existing experience | Manual |
| promote.sh | Tag promotion check | Cron/Manual |
| compact.sh | Compress & deduplicate | Cron/Manual |
| archive.sh | Archive old data | Cron/Manual |

---

## 🔄 Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Auto Draft Generation (Hook)                       │
├─────────────────────────────────────────────────────────────┤
│ before_reset triggers → generateDraft() → drafts/draft-*.json│
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: Auto Review & Write (Hook calls auto-review.sh)   │
├─────────────────────────────────────────────────────────────┤
│ Scan drafts → Extract keywords → Search similar → Create/Append→Archive │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔒 Security & Performance

| Feature | Description |
|---------|-------------|
| Concurrent Safety | `.write_lock` directory lock |
| Input Validation | ID format, path, length checks |
| Regex Escaping | Prevent injection |
| Path Traversal Detection | `../` and `\` blocked |
| Auto Fallback | Switch to keyword if LM Studio unavailable |

---

## 📂 Storage Structure

```
~/.openclaw/.learnings/
├── experiences.md          ← Main experience database
├── memory.md              ← HOT layer (≤100 lines)
├── domains/               ← WARM layer (domain isolated)
│   ├── infra.md
│   ├── code.md
│   └── global.md
├── drafts/                ← Drafts (Hook auto-generated)
│   └── archive/           ← Processed draft archive
└── vectors/               ← Vector index
```

---

## 📖 Version History

| Version | Date | Highlights |
|---------|------|------------|
| **v2.8.14** | 2026-04-24 | 🤖 **Hook Fully Automatic Integration** |
| v2.8.13 | 2026-04-24 | Root docs update |
| v2.8.12 | 2026-04-24 | Full auto test verified |
| v2.8.11 | 2026-04-24 | SKILL-GUIDE.md complete guide |
| v2.8.10 | 2026-04-24 | auto-review.sh auto review |
| v2.8.9 | 2026-04-24 | ARCHITECTURE.md architecture design |

---

## 🔗 Links

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/skill.git)
- [Gitee](https://gitee.com/rocky_tian/skill.git)

---

**Maintainer**: 大颖 (fs-daying) | **Version**: v2.8.14
