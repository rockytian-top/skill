# 📚 rocky-know-how

> OpenClaw experience & know-how skill — auto-search on repeated failures, auto-record on success, shared across all agents

[中文](./README.md) | English

## ✨ Features

- 🔍 **Smart Search** — Multi-keyword AND matching + relevance scoring
- 🏷️ **Tag/Area Filter** — `--tag` and `--area` for precise filtering
- 🔄 **Auto Dedup** — Question text + Tags combination deduplication
- 📝 **Native Memory Sync** — Writes to memory/*.md, searchable via memory_search
- 🌙 **Dreaming Integration** — Annotated markers for Dreaming phase analysis
- 📊 **Tag Promotion** — Same Tag ≥3 times auto-writes to TOOLS.md
- 📥 **Historical Import** — Batch extract lessons from memory/*.md
- 🗄️ **Auto Archive** — Auto-archive entries older than 30 days
- 🌐 **Cross-Agent Sharing** — Global storage, all agents share the same data

## 🔒 Security

| Measure | Description |
|---------|-------------|
| No system commands | Only reads/writes local files |
| No sensitive data | Only stores experience text |
| No network requests | Pure local operations |
| Open source auditable | MIT License |
| Dynamic paths | No hardcoded user paths |

## 📦 Scripts

| Script | Description |
|--------|-------------|
| search.sh | Search experiences (relevance scoring, tag/area filter, preview mode) |
| record.sh | Record experience (dedup, dry-run, Dreaming markers) |
| stats.sh | Statistics dashboard (entry count, Area/Tag distribution) |
| promote.sh | Tag promotion check (≥3 times auto-writes TOOLS.md) |
| import.sh | Batch import historical lessons from memory/*.md |
| archive.sh | Archive old entries (manual/auto mode) |
| clean.sh | Cleanup tool (test entries/old index) |
| install.sh | Install script |
| uninstall.sh | Uninstall script |

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
```bash
# Normal record
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

## 🔄 Core Loop

```
Task received → Execute normally
    ↓
Failed ≥2 times → Search experiences (search.sh)
    ├── Found → Follow the solution
    └── Not found → Keep trying until success
    ↓
Success → Record experience (record.sh)
    ↓
Sync to memory/*.md → searchable via memory_search
    ↓
Same Tag ≥3 times → Promote to TOOLS.md (promote.sh)
```

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
