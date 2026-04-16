# rocky-know-how — OpenClaw Experience & Know-How Skill

**Version**: 1.2.0 | **Type**: OpenClaw Skill + Hook | **License**: MIT

## Introduction

Fail ≥2 times → search know-how. Succeed → write it down. Writing syncs to native memory, so **native `memory_search` can find it**.

## Core Logic

```
Receive task → Execute
    ↓
Fail ≥2 times → Search know-how
    ├── Found → Execute answer
    └── Not found → Keep trying
    ↓
After success → Write know-how + sync to memory/*.md
    ↓
Same Tag ≥3 times → Promote to golden rule
```

## Storage

**Global shared**: `~/.openclaw/.learnings/experiences.md`

## Scripts

| Script | Purpose |
|--------|---------|
| `search.sh "keyword"` | Search know-how |
| `record.sh "problem" "failure" "solution" "prevention" "tags"` | Write + sync |
| `stats.sh` | Statistics |
| `promote.sh` | Tag promotion |
| `archive.sh [--days N]` | Archive old entries |

## Installation

```bash
git clone https://github.com/rockytian-top/openclaw-rocky-skills.git
cd openclaw-rocky-skills
bash scripts/install.sh
```

## Compatibility

- ✅ Node.js 18+ (CommonJS)
- ✅ macOS / Linux

## License

MIT
