# 📚 rocky-know-how

> OpenClaw experience & know-how skill v2.8.6 — auto-search on repeated failures, auto-record on success, shared across all agents

[中文](./README.md) | English

## ✨ Features

### 🎯 Three Core Innovations (Unique to This Skill)

1. **🤖 Auto-Record Mechanism** — Auto-search on 2nd failure, auto-write on success
2. **🔍 Auto Vector Search** — Semantic + keyword dual-engine search
3. **⚡ Embedding-less Auto Fallback** — Detects LM Studio, falls back to keyword search

---

### Basic Features
- 🔍 **Smart Search** — Multi-keyword AND matching + relevance scoring + area/project filter
- 🏷️ **Tag/Area Filter** — `--tag` `--area` `--project` precise filtering
- 🔄 **Auto Dedup** — Question text + Tags combination dedup (threshold 70%)
- 📝 **Native Memory Sync** — Writes to memory/*.md, searchable via memory_search
- 🌙 **Dreaming Integration** — Annotated markers for Dreaming phase analysis
- 📊 **Tag Promotion** — Same Tag ≥3 times auto-writes to TOOLS.md
- 📥 **Historical Import** — Batch extract lessons from memory/*.md
- 🗄️ **Auto Archive** — Auto-archive entries older than 30 days
- 🌐 **Cross-Agent Sharing** — Global storage, all agents share the same data
- 🔒 **Security Hardened** — Path traversal detection, regex escaping, input validation
- ⚡ **Concurrent Safe** — Directory lock protects multi-process writes

## 🔒 Security

| Measure | Description |
|---------|-------------|
| ✅ Concurrent write lock | `.write_lock` directory lock prevents data interleave |
| ✅ Input validation | ID format, path, length all validated |
| ✅ Regex escaping | FILTER_DOMAIN/FILTER_PROJECT防注入 |
| ✅ Path traversal detection | `../` and backslash `\`全面拦截 |
| No system commands | Only reads/writes local files |
| No sensitive data | Only stores experience text |
| No network requests | Pure local operations |
| Open source auditable | MIT License |
| Dynamic paths | No hardcoded user paths |

## 📦 Scripts

| Script | Description | Version |
|--------|-------------|---------|
| search.sh | Search experiences (relevance scoring, tag/area/project filter, preview) | v2.8.6 |
| record.sh | Record experience (dedup, dry-run, Dreaming markers, **concurrent lock**) | v2.8.6 |
| stats.sh | Statistics dashboard (entry count, Area/Tag distribution) | v2.8.6 |
| promote.sh | Tag promotion check (≥3 times auto-writes TOOLS.md) | v2.8.6 |
| import.sh | Batch import from memory/*.md (**path traversal fix**) | v2.8.6 |
| archive.sh | Archive old entries (manual/auto mode) | v2.8.6 |
| clean.sh | Cleanup tool (test entries/old index) | v2.8.6 |
| update-record.sh | Update existing experience (**tag format aligned**) | v2.8.6 |
| install.sh | Install script (**auto Hook config**) | v2.8.6 |
| uninstall.sh | Uninstall script | v2.8.6 |

## 🚀 Installation

### ClawHub (Recommended)
```bash
openclaw skills install rocky-know-how
```

### Manual
```bash
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills/rocky-know-how
bash scripts/install.sh
```

## 📖 Usage

### Search
```bash
# Multi-keyword search (relevance scoring)
bash scripts/search.sh "debug" "website"

# By tags (AND logic)
bash scripts/search.sh --tag "troubleshooting,vps"

# By area
bash scripts/search.sh --area infra

# Preview mode
bash scripts/search.sh --preview "keyword"

# List all
bash scripts/search.sh --all
```

### Record

**⚠️ Two-Phase Process**: Auto-draft → Review → Formal write

#### Phase 1: Auto-Draft (Hook)
After task success, Hook automatically analyzes session and generates draft:
```
drafts/draft-{sessionKey}.json
status: "pending_review"
```
No manual action needed.

#### Phase 2: Review Drafts
```bash
# Batch review (recommended): AI-assisted judgment
bash ~/.openclaw/skills/rocky-know-how/scripts/summarize-drafts.sh

# Check suggestions
cat ~/.openclaw/.learnings/.summarize.log
# Output: DRAFT_ID: xxx | Worth recording: Yes/No | record.sh command

# Copy and execute the recommended record.sh command
```

#### Phase 3: Formal Write
```bash
# Direct write (immediate effect)
bash scripts/record.sh "Problem" "What went wrong" "Solution" "Prevention" "tag1,tag2" "area"

# Dry-run (preview only)
bash scripts/record.sh --dry-run "Problem" "Mistakes" "Solution" "Prevention" "tags"
```

### Import / Archive
```bash
# Import from memory
bash scripts/import.sh --dry-run    # Preview first
bash scripts/import.sh              # Actual import

# Manual archive
bash scripts/archive.sh --dry-run   # Preview
bash scripts/archive.sh             # Archive

# Auto archive (for cron/heartbeat)
bash scripts/archive.sh --auto
```

## 🔄 Complete Workflow (with Draft Review)

```
Task received → Execute normally
    ↓
Failed ≥2 times → 🔍 Search experiences (search.sh)
    ├── Found → Follow solution
    └── Not found → Keep trying until success
    ↓
Success → 📝 Trigger before_reset Hook
    ↓
    Handler analyzes session → Extract task/tools/errors
    ↓
    ✅ Problem detected → Generate draft (drafts/draft-*.json)
    ❌ Casual chat/docs → Skip (no draft)
    ↓
Draft status: "pending_review"
    ↓
┌─────────────────────────────────────────┐
│ Review Drafts (2 methods)               │
│ 1. Batch review: summarize-drafts.sh   │
│    → Outputs record.sh command suggestions │
│    → Manual execution of record.sh     │
│ 2. Direct: View draft → Manual record.sh │
└─────────────────────────────────────────┘
    ↓
Write to experiences.md (formal) ✅
    ↓
Sync memory.md + domains/*.md
    ↓
Same Tag ≥3 times → 🚀 Promote to TOOLS.md (promote.sh)
```

**Key Points**:
- ✅ Auto-draft (silent) ≠ Auto-write formal
- ✅ Draft requires review (prevent noise)
- ✅ summarize-drafts.sh only suggests, doesn't auto-execute

---

## 🔄 Simplified Workflow (Emergency)

## 📂 Storage

```
~/.openclaw/.learnings/
├── experiences.md          ← Experience data (globally shared)
└── archive/                ← Archive directory
    └── YYYY-MM/            ← Monthly archives
```

## 🔧 Compatibility

- ✅ macOS bash 3.x (no `=~`, no GNU extensions)
- ✅ Node.js 18+ (CommonJS, no TypeScript dependency)
- ✅ macOS / Linux
- ✅ OpenClaw 2026.4.x+

## 📄 License

[MIT License](./LICENSE)

## 🔗 Links

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/openclaw-rocky-skills)
- [Gitee](https://gitee.com/rocky_tian/skill)
