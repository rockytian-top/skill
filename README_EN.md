# 📚 rocky-know-how

> Experience Knowledge Skill — Search on failure, write after solving, shared across agents

**Current Version: v2.5.1**

---

## Core Feature

**Problem → Search first. Solve → Record it.**

Rocky-know-how is a team-wide experience knowledge system aligned with self-improving architecture. Once you solve a problem, record it so you never solve it twice.

---

## Core Functions

| Function | Script | Description |
|----------|--------|-------------|
| Search | `search.sh` | Multi-dimensional search (keyword/tag/area/semantic) |
| Record | `record.sh` | Write lessons, deduplication |
| Promote | `promote.sh` | Same Tag ≥3x in 30 days → HOT layer |
| Demote | `demote.sh` | Long unused → COLD layer |
| Compact | `compact.sh` | Compress by layer |
| Clean | `clean.sh` | Clean test entries |
| Stats | `stats.sh` | View statistics |
| Archive | `archive.sh` | Manual/auto archive |
| Import | `import.sh` | Import from memory/*.md |
| Install/Uninstall | `install.sh` / `uninstall.sh` | One-click setup |

---

## Layered Storage

```
~/.openclaw/.learnings/
├── experiences.md       # Main experience database
├── memory.md           # 🔥 HOT: Active experiences
├── corrections.md      # Corrections log
├── domains/            # 🌡️ WARM: Domain isolation
├── projects/          # 🌡️ WARM: Project isolation
└── archive/           # ❄️ COLD: Archive
```

---

## Core Loop

```
Task → Execute normally
    ↓
Failed 2+ times → Search learnings (search.sh)
    ├── Found → Execute solution
    └── Not found → Keep trying until success
    ↓
Success → Write lesson (record.sh)
    ↓
Sync to memory/*.md → searchable via memory_search
    ↓
Same Tag ≥3x/30days → Promote to HOT (promote.sh)
```

---

## Install

```bash
# ClawHub (Recommended)
openclaw skills install rocky-know-how

# Or manual
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
bash scripts/install.sh
```

---

## Quick Start

**Search**：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh "keyword"
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --tag "nginx,troubleshooting"
bash ~/.openclaw/skills/rocky-know-how/scripts/search.sh --area infra
```

**Record**：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/record.sh \
  "Problem title" \
  "Failure process" \
  "Correct solution" \
  "Prevention" \
  "tag1,tag2" \
  "area"
```

**Stats**：
```bash
bash ~/.openclaw/skills/rocky-know-how/scripts/stats.sh
```

---

## vs self-improving

| | self-improving | rocky-know-how |
|--|---------------|----------------|
| **Architecture** | Pure docs, relies on agent discipline | Scripts enforce, unified format |
| **Search** | Agent interprets | Score ranking, precise match |
| **Fault tolerance** | Low (relies on discipline) | High (script fallback) |
| **Layering** | None | HOT/WARM/COLD |
| **Promotion** | Relies on agent writing | Auto Tag frequency stats |
| **Tools** | 0 scripts | 11 bash scripts |
| **Team sharing** | Per-agent isolated | Shared `.learnings/` |

---

## Version History

| Version | Description |
|---------|-------------|
| v2.5.1 | Reverted to simple version, no hook injection |
| v2.5.0 | Restored exec+search.sh original behavior |
| v2.4.1 | search.sh restored as backup, memory_search preferred |
| v2.0.0 | Full architecture refactor |

---

## Links

- [ClawHub](https://clawhub.ai/skills/rocky-know-how)
- [GitHub](https://github.com/rockytian-top/skill)
- [Gitee](https://gitee.com/rocky_tian/skill)

---

**License**: MIT License
