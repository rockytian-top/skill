---
name: rocky-know-how
slug: rocky-know-how
version: 2.4.1
homepage: https://clawhub.ai/skills/rocky-know-how
description: "Learning knowledge skill v2 — Aligns with self-improving. Search learnings when failing 2+ times, write after solving. Layered storage (HOT/WARM/COLD), auto-promotion/demotion, namespace isolation, corrections log, reflections, heartbeat integration."
changelog: "v2.4.1: search.sh恢复作为备用，memory_search优先

v2.4.0: 强制使用memory_search工具

v2.3.0: 统一使用memory_search工具(experiences.md通过symlink挂载到memory/目录)

v2.2.1: search.sh默认启用语义搜索

v2.0.0: Full architecture refactor"
metadata: {"openclaw":{"emoji":"📚","requires":{"bins":[]},"os":["darwin","linux","win32"]}}
---

## ⚠️ CRITICAL: Search Via memory_search First

**Primary: Use `memory_search` tool for all experience searches.**

All experiences are indexed via symlink: `memory/experiences.md` → `~/.openclaw/.learnings/experiences.md`

The memory_search tool provides semantic vector search across all memory files.

**Fallback: If memory_search fails, use `search.sh` as backup.**

## When to Use

- Task failed 2+ times → Search learnings: use `memory_search` tool ONLY
- Solved the problem → Write lesson (record.sh)
- Same Tag 3x in 30 days → Promote to HOT (promote.sh)
- Task completed → Self-reflect (reflections.md)
- On heartbeat → Conservative maintenance (heartbeat-rules.md)

## Architecture

Learnings stored at `~/.openclaw/.learnings/`, fully aligned with self-improving layered architecture:

```
~/.openclaw/.learnings/
├── memory.md           # HOT: ≤100 lines, always loaded
├── index.md            # Topic index (line counts)
├── heartbeat-state.md  # Heartbeat state
├── corrections.md      # Corrections log (last 50 entries)
├── reflections.md      # Self-reflection log
├── domains/            # WARM: domain isolation (code, infra, dev)
├── projects/           # WARM: project isolation
└── archive/           # COLD: archive (loaded on explicit query)

~/.openclaw/.learnings/experiences.md  # v1 compatibility: main data file
```

**Storage path**: Shared across all agents at `~/.openclaw/.learnings/`

**Backward compatible**: experiences.md (v1 format) preserved, new layered format added

## Quick Reference

| Topic | File |
|-------|------|
| Setup guide | `setup.md` |
| Heartbeat state template | `heartbeat-state.md` |
| Memory template | `memory-template.md` |
| Heartbeat seed | `HEARTBEAT.md` |
| Heartbeat rules | `heartbeat-rules.md` |
| Learning mechanism | `learning.md` |
| Safety boundaries | `boundaries.md` |
| Scaling rules | `scaling.md` |
| Memory operations | `operations.md` |
| Self-reflection log | `reflections.md` |

## Learning Signals

Auto-record learnings → Append to `experiences.md`, sync to `corrections.md`:

**Correction signals**:
- "No, that's not right..." → Learning search missed, keep trying
- "That's wrong..." / "You need to..." → Record correction
- "Remember that I always..." → Confirm preference
- "Why do you keep..." → Identify repeated error patterns

**Learning signals (after successful solve)**:
- Succeeded after 2+ failures → Write to experiences.md
- Same Tag 3x → Promote to HOT
- New tech solution effective → Record to domains/

**Ignore**:
- One-time instructions ("do X now")
- Context-specific ("in this file...")
- Hypothetical discussions ("what if...")

## Self-Reflection

After completing important work, pause and evaluate:

1. **Did it match expectations?** — Compare result vs intent
2. **What could be improved?** — Identify next improvements
3. **Is this a pattern?** → If yes, record to `corrections.md`

**When to reflect**:
- After completing multi-step tasks
- After receiving feedback (positive or negative)
- After fixing bugs or errors
- When noticing output could be better

**Log format**:
```
CONTEXT: [task type]
REFLECTION: [what I noticed]
LESSON: [what to do differently next time]
```

**Example**:
```
CONTEXT: Debug gateway disconnect after Mac migration
REFLECTION: Works from terminal but fails from LaunchAgent
LESSON: Must check LaunchAgent registration after migration
```

Reflection entries follow same promotion rules: 3x successful use → Promote to HOT.

## Quick Queries

| User says | Action |
|-----------|--------|
| "search learnings X" | Use `memory_search` tool (built-in vector search, indexes memory/*.md + experiences.md via symlink) |
| "show all learnings" | Display experiences.md |
| "what did I learn recently?" | Show last 10 from corrections.md |
| "what patterns exist?" | List memory.md (HOT) |
| "show [project] patterns" | Load projects/{name}.md |
| "what's in warm layer?" | List domains/ + projects/ |
| "learning stats" | Show layer counts |
| "forget X" | Delete from all layers (confirm first) |
| "export learnings" | ZIP all files |

## Memory Stats

Report when user says "learning stats":

```
📊 rocky-know-how Learning Stats

🔥 HOT (always loaded):
  memory.md: X entries

🌡️ WARM (loaded on demand):
  domains/: X files
  projects/: X files

❄️ COLD (archived):
  archive/: X files

Learnings (v1 compatible):
  experiences.md: X entries

Last 7 days:
  New corrections: X
  Promoted to HOT: X
  Demoted to WARM: X
```

## Common Traps

| Trap | Why it fails | Better approach |
|------|-------------|----------------|
| Learning from silence | Creates wrong rules | Wait for explicit correction or repeated evidence |
| Promoting too fast | Pollutes HOT memory | Keep new lessons tentative until confirmed |
| Reading every namespace | Wastes context | Load only HOT + minimal matching files |
| Deleting during compaction | Loses trust and history | Merge, summarize, or demote |

## Core Rules

### 1. Learn from corrections and self-reflection
- Record explicit user corrections
- Record self-identified work improvements
- Never infer from silence
- Same lesson 3x → Ask user to confirm as rule

### 2. Layered storage
| Layer | Location | Size limit | Behavior |
|-------|----------|-----------|----------|
| HOT | memory.md | ≤100 lines | Always loaded |
| WARM | projects/, domains/ | ≤200 lines | Load on context match |
| COLD | archive/ | Unlimited | Load on explicit query |

### 3. Auto-promotion / demotion
- Same Tag 3x in 7 days → Promote to HOT
- Unused 30 days → Demote to WARM
- Unused 90 days → Archive to COLD
- Never delete (without asking)

### 4. Namespace isolation
- Project patterns → `projects/{name}.md`
- Global preferences → HOT layer (memory.md)
- Domain patterns (code, infra, dev) → `domains/`
- Cross-namespace inheritance: global → domain → project

### 5. Conflict resolution
When patterns conflict:
1. Most specific wins (project > domain > global)
2. Most recent wins (same level)
3. Unclear → Ask user

### 6. Compaction
When files exceed limits:
1. Merge similar corrections into single rule
2. Archive unused patterns
3. Summarize verbose entries
4. Never lose confirmed preferences

### 7. Transparency
- Every action from memory → Quote source: "Using X (from domains/code.md:12)"
- Weekly summary available: learned patterns, demotions, archives
- Full export anytime: ZIP all files

### 8. Safety boundaries
See `boundaries.md` — Never store credentials, health data, or third-party info.

### 9. Graceful degradation
If context limits trigger:
1. Load only memory.md (HOT)
2. Load matching namespaces on demand
3. Never fail silently — Tell user what didn't load

## Scope

This skill **only does**:
- Learn from user corrections and self-reflection
- Store preferences in local files (`~/.openclaw/.learnings/`)
- Maintain `heartbeat-state.md` on workspace-integrated heartbeat
- Read own memory files when activated

This skill **never does**:
- Access calendars, email, or contacts
- Make network requests
- Read files outside `~/.openclaw/.learnings/`
- Infer preferences from silence or observation
- Delete or blindly overwrite rocky-know-how memory during heartbeat cleanup
- Modify its own SKILL.md

## Data Storage

Local state in `~/.openclaw/.learnings/`:

- `memory.md` — HOT rules and confirmed preferences
- `corrections.md` — Explicit corrections and reusable lessons
- `experiences.md` — v1 format learnings (backward compatible)
- `domains/` — Domain-isolated patterns
- `projects/` — Project-isolated patterns
- `archive/` — Decayed or dormant patterns
- `heartbeat-state.md` — Cyclic maintenance markers

---

## Feedback

- Found it useful: `clawhub star rocky-know-how`
- Keep updated: `clawhub sync`
