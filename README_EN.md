# rocky-know-how Learning Knowledge Skill

**Version**: v2.7.0 | **OS**: macOS / Linux / Windows

---

## 📚 Overview

rocky-know-how is a learning knowledge skill that helps AI Agents learn from failures and record successes.

Core features:
- 🔍 **Failed 2+ times** → Search the learnings database
- ✍️ **Problem solved** → Record to learnings database
- 📊 **Tag promotion** → Frequent learnings auto-upgrade
- 🧹 **Auto-cleanup** → Test data periodic cleanup

---

## 🚀 Quick Start

### Install

```bash
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
./scripts/install.sh
```

### Core Commands

| Command | Usage |
|---------|-------|
| `search.sh "keyword"` | Search learnings |
| `record.sh "problem" "failures" "solution" "prevention" "tags"` | Record new lesson |
| `stats.sh` | View stats dashboard |
| `promote.sh` | Check tag promotion |
| `clean.sh` | Cleanup test data |

---

## 📁 Data Structure

```
~/.openclaw/.learnings/
├── experiences.md    # Main database (all learnings)
├── memory.md         # HOT layer (frequent)
├── domains/          # WARM layer (by domain)
├── projects/         # WARM layer (by project)
└── archive/          # COLD layer (archived)
```

---

## 🔄 v2.7.0 Updates

### Support OpenClaw 2026.4.21 New Hooks

| Hook | Trigger | Function |
|------|---------|----------|
| `before_compaction` | Before session compaction | Save current task state |
| `after_compaction` | After session compaction | Record session summary |
| `before_reset` | Before session reset | Save important info |

### Fixes

- **Deduplication logic**: Tags overlap ≥50% blocks directly, avoiding Chinese text segmentation issues

---

## 📖 Documentation

- [rocky-know-how/SKILL.md](./rocky-know-how/SKILL.md) - Skill config
- [rocky-know-how/README.md](./rocky-know-how/README.md) - Full manual
- [rocky-know-how/setup.md](./rocky-know-how/setup.md) - Setup guide
- [rocky-know-how/operations.md](./rocky-know-how/operations.md) - Operations

---

## 🏷️ Tag Promotion Rules

| Condition | Result |
|-----------|--------|
| Same Tag appears ≥3 times in 30 days | → HOT layer `memory.md` |

---

## 📊 Stats Dashboard

```
╔════════════════════════════════════════════╗
║  📊 rocky-know-how Stats Dashboard v2.1.0 ║
╚════════════════════════════════════════════╝

🔥 HOT (Always loaded)
  memory.md: 14 entries

🌡️ WARM (On-demand)
  domains/: 3 files
  projects/: 2 files

❄️ COLD (Archived)
  archive/: 1 file

📚 v1 Main Data (experiences.md)
  Total: 45 entries
  This month: 45
```

---

## 🔗 Links

- **Gitee**: https://gitee.com/rocky_tian/skill
- **GitHub**: https://github.com/rockytian-top/skill
- **ClawHub**: https://clawhub.ai/skills/rocky-know-how

---

_Last updated: 2026-04-22 v2.7.0_
