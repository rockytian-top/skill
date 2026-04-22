# rocky-know-how Complete User Manual

**Version**: v2.6.0 | **OS**: macOS / Linux / Windows

---

## 📚 Overview

rocky-know-how is a learning knowledge skill that helps AI Agents learn from failures and record successes.

Core features:
- 🔍 **Failed 2+ times** → Search the learnings database
- ✍️ **Problem solved** → Record to learnings database
- 📊 **Tag promotion** → Frequent learnings auto-upgrade
- 🧹 **Auto-cleanup** → Test data periodic cleanup

---

## 🚀 Installation

### Method 1: Auto Install

```bash
git clone https://gitee.com/rocky_tian/skill.git
cd skill/rocky-know-how
./scripts/install.sh
```

### Method 2: Manual Install

1. Copy `scripts/` to `~/.openclaw/skills/rocky-know-how/`
2. Configure Hook (optional, OpenClaw 2026.4.21+):
   ```bash
   # Add to openclaw.json:
   "hooks": {
     "internal": {
       "load": {
         "extraDirs": [
           "~/.openclaw/skills/rocky-know-how/hooks"
         ]
       }
     }
   }
   ```

---

## 📁 Data Structure

```
~/.openclaw/.learnings/
├── experiences.md    # Main database (all learnings)
├── corrections.md    # Corrections log
├── memory.md         # HOT layer (frequent, always loaded)
├── domains/          # WARM layer (by domain)
│   ├── code.md
│   ├── general.md
│   └── infra.md
├── projects/         # WARM layer (by project)
└── archive/          # COLD layer (archived)
```

---

## 🎯 Core Commands

### 1. Search Learnings `search.sh`

```bash
# Basic search
bash scripts/search.sh "nginx 502"

# View all
bash scripts/search.sh --all

# Preview mode
bash scripts/search.sh --preview "keyword"

# Filter by tag
bash scripts/search.sh --tag "php-fpm"

# Filter by area
bash scripts/search.sh --area "infra"
```

### 2. Record Lesson `record.sh`

```bash
# Basic record
bash scripts/record.sh "problem" "failures" "solution" "prevention" "tag1,tag2" "area"

# Preview mode (no actual write)
bash scripts/record.sh --dry-run "problem" "failures" "solution" "prevention" "tags" "area"

# Specify namespace
bash scripts/record.sh --namespace "project:myapp" "problem" "failures" "solution" "prevention" "tags" "area"
```

### 3. Stats Dashboard `stats.sh`

```bash
bash scripts/stats.sh
```

Output example:
```
╔════════════════════════════════════════════╗
║  📊 rocky-know-how Stats Dashboard v2.1.0 ║
╚════════════════════════════════════════════╝

🔥 HOT (Always loaded)
  memory.md: 14 entries

🌡️ WARM (On-demand)
  domains/: 3 files
  projects/: 2 files

📚 v1 Main Data (experiences.md)
  Total: 45 entries
```

### 4. Tag Promotion Check `promote.sh`

```bash
bash scripts/promote.sh
```

### 5. Cleanup Test Data `clean.sh`

```bash
# Preview
bash scripts/clean.sh --dry-run

# Execute cleanup
bash scripts/clean.sh
```

---

## 🔄 v2.6.0 Updates

### Support OpenClaw 2026.4.21 New Hooks

| Hook | Trigger | Function |
|------|---------|----------|
| `before_compaction` | Before session compaction | Save current task state to temp file |
| `after_compaction` | After session compaction | Read state, record session summary to session-summaries.md |
| `before_reset` | Before session reset | Save important info |

### Deduplication Logic Optimization

- **Old logic**: Tags overlap ≥60% + text similarity ≥70% blocks
- **New logic**: Tags overlap ≥50% blocks directly
- **Reason**: Chinese text segmentation caused similarity calculation errors

---

## 🏷️ Tag Promotion Rules

| Condition | Result |
|-----------|--------|
| Same Tag appears ≥3 times in 30 days | → HOT layer `memory.md` |
| No access for 30 days | → Auto demote to COLD layer |

---

## 📋 Entry Format

```markdown
## [EXP-20260422-001] Problem Title

**Area**: infra
**Failed-Count**: ≥2
**Tags**: nginx, 502, php-fpm
**Created**: 2026-04-22 10:00:00
**Namespace**: global

### Problem
Problem description

### Failures
1st attempt: ... → Failed
2nd attempt: ... → Failed

### Solution
Correct solution

### Prevention
How to avoid this pitfall
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCLAW_STATE_DIR` | State directory | `~/.openclaw` |
| `OPENCLAW_WORKSPACE` | Workspace directory | Auto-detect |
| `OPENCLAW_SESSION_KEY` | Session key | Auto-get |

### Hook Configuration (Optional)

Add to `openclaw.json`:

```json
{
  "hooks": {
    "internal": {
      "load": {
        "extraDirs": [
          "~/.openclaw/skills/rocky-know-how/hooks"
        ]
      }
    }
  }
}
```

---

## 🔗 Links

- **Gitee**: https://gitee.com/rocky_tian/skill
- **GitHub**: https://github.com/rockytian-top/skill
- **ClawHub**: https://clawhub.ai/skills/rocky-know-how

---

## 📄 License

MIT License

---

_Last updated: 2026-04-22 v2.6.0_
