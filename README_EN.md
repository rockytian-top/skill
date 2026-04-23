# 📚 rocky-know-how

> OpenClaw Learning Knowledge Skill v2.8.12 — Search on failure, write after solving, learnings shared across agents

[English](./README_EN.md) | [完整使用指南](./SKILL-GUIDE.md)

---

## ✨ Features

### 🎯 Three Core Innovations

1. **🤖 Fully Automatic Draft Review** — Hook generates drafts → `auto-review.sh` reviews and writes in one click
2. **🔍 Dual Search Engines** — Semantic search + keyword search, vector enabled when LM Studio available
3. **⚡ Auto Fallback** — Automatically switches to keyword search when LM Studio unavailable

---

### Basic Features

- 🔍 **Smart Search** — Multi-keyword AND matching + relevance scoring + domain/project filtering
- 🤖 **Fully Automatic Review** — `auto-review.sh` draft → review → write → archive all automatic
- 🏷️ **Tag/Domain Filtering** — `--tag` `--area` `--project` precise filtering
- 🔄 **Auto Deduplication** — Problem text + Tags combination deduplication (70% threshold)
- 📝 **Native Memory Sync** — Writes to memory.md, searchable via memory_search
- 🌙 **Dreaming Integration** — Mark comments for Dreaming phase analysis
- 📊 **Tag Promotion Rule** — Same Tag ≥3 times in 7 days auto-promotes to TOOLS.md
- 📥 **History Import** — Batch extract lessons from memory
- 🗄️ **Auto Archive** — Auto archive after 30+ days
- 🌐 **Cross Agent Sharing** — Global storage, all agents share same experience base
- 🔒 **Security Hardening** — Path traversal detection, regex escaping, input validation
- ⚡ **Concurrency Safety** — Directory lock protection, multi-process safe writes

---

## 🔄 Fully Automatic Workflow

```
Task Fails → search.sh search experience
    ↓
Found Answer → Execute → Success
    ↓
before_reset Hook → Auto generate draft (drafts/)
    ↓
auto-review.sh → Scan drafts → Search similar → Auto create/append
    ↓
Write to experiences.md → Archive draft → Done ✅
```

**No manual intervention required**, fully automatic from draft to formal experience.

---

## 📦 Script List

| Script | Description | Priority |
|--------|-------------|----------|
| **auto-review.sh** | 🆕 **Fully Automatic Draft Review** (Recommended) | ⭐⭐⭐ |
| search.sh | Search experiences | ⭐⭐⭐ |
| record.sh | Write new experience | ⭐⭐⭐ |
| summarize-drafts.sh | Scan drafts generate suggestions (semi-auto) | ⭐⭐ |
| append-record.sh | Append to existing experience | ⭐⭐ |
| update-record.sh | Update existing experience | ⭐⭐ |
| promote.sh | Tag promotion check | ⭐⭐ |
| demote.sh | Demote unused experiences | ⭐ |
| compact.sh | Compress deduplication | ⭐⭐ |
| archive.sh | Archive old data | ⭐ |
| stats.sh | Statistics panel | ⭐ |
| clean.sh | Clean garbage | ⭐ |
| import.sh | Import history lessons | ⭐ |

---

## 🚀 Quick Start

### 1. Install

```bash
# ClawHub (Recommended)
openclaw skills install rocky-know-how

# Or manual
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

### 2. Search Experience

```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh nginx 502
```

### 3. Fully Automatic Draft Review

```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/auto-review.sh
```

### 4. Manual Write Experience

```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "Nginx 502 error" \
  "Restart nginx failed, php-fpm process disappeared" \
  "Restart php-fpm + adjust max_children" \
  "Monitor php-fpm process count regularly" \
  "nginx,502,php-fpm" \
  "infra"
```

---

## 🔧 Hook Configuration

install.sh auto-configures, no manual operation needed.

4 Events:
- `agent:bootstrap` — Inject experience reminder on startup
- `before_compaction` — Save session state
- `after_compaction` — Record session summary
- `before_reset` — **Generate draft** (Core)

---

## 🔒 Security

| Measure | Description |
|---------|-------------|
| ✅ Concurrent Write Lock | `.write_lock` directory lock |
| ✅ Strict Input Validation | ID format, path, length checks |
| ✅ Regex Escaping | Prevent injection attacks |
| ✅ Path Traversal Detection | `../` and `\` comprehensive blocking |
| ✅ Open Source | MIT License |

---

## 📂 Storage Structure

```
~/.openclaw/.learnings/
├── experiences.md          ← Main experience database
├── memory.md              ← HOT layer (≤100 lines)
├── domains/               ← WARM layer (domain isolated)
│   ├── infra.md
│   ├── wx.newstt.md
│   ├── code.md
│   └── global.md
├── drafts/                ← Drafts (pending review)
│   └── archive/           ← Processed draft archive
└── vectors/               ← Vector index (LM Studio)
```

---

## 📖 Version History

| Version | Date | Changes |
|---------|------|---------|
| **2.8.12** | 2026-04-24 | ✅ Full auto workflow test verified; SKILL-GUIDE.md (20KB) complete guide |
| **2.8.11** | 2026-04-24 | SKILL-GUIDE.md complete skill guide (12 chapters) |
| **2.8.10** | 2026-04-24 | 🆕 auto-review.sh fully automatic draft review script |
| **2.8.9** | 2026-04-24 | ARCHITECTURE.md complete architecture design (19.8KB) |
| **2.8.8** | 2026-04-24 | Two-phase mechanism documentation fix |
| 2.8.3 | 2026-04-24 | 🔒 Security: H1/H2/M1 vulnerability fixes |
| 2.8.2 | 2026-04-24 | 🔐 Concurrent lock, Hook path dynamic |
| 2.7.1 | 2026-04-21 | Support OpenClaw 2026.4.21 |

---

## 🔗 Links

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
- [Complete Guide](./SKILL-GUIDE.md)
- [Architecture](./ARCHITECTURE.md)

---

**Maintainer**: 大颖 (fs-daying)  
**Version**: v2.8.12
