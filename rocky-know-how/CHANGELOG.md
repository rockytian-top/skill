# CHANGELOG

## [1.3.0] - 2026-04-17

### Fixed
- experiences.md duplicate headers (3 → 1)
- Test entry EXP-20260416-007 removed
- promote.sh hardcoded workspace path → dynamic detection

### Added
- **search.sh**: Relevance scoring (`[匹配度: N/M]`)
- **search.sh**: `--tag` filter (AND logic)
- **search.sh**: `--area` filter
- **search.sh**: `--preview` summary mode
- **search.sh**: `--since` date filter
- **record.sh**: `--dry-run` preview mode
- **record.sh**: Enhanced dedup (Tags combo + 80% keyword overlap)
- **record.sh**: Shows existing entry details on dedup hit
- **record.sh**: Dreaming marker sync (`<!-- rocky-know-how:EXP-* -->`)
- **import.sh**: Batch import from memory/*.md (new script)
- **archive.sh**: `--auto` mode for cron/heartbeat
- **handler.js**: Cross-workspace script path detection
- **handler.js**: Dynamic workspace resolution from sessionKey
- README.md and README_EN.md fully updated

### Changed
- All scripts: macOS bash 3.x compatible (no `=~`, no GNU extensions)
- All scripts: `grep --color=never` to prevent ANSI pollution
- promote.sh: Workspace path from env vars (`WORKSPACE`/`OPENCLAW_WORKSPACE`/`OPENCLAW_SESSION_KEY`)

## [1.2.0] - 2026-04-16

### Added
- Initial release as rocky-know-how (renamed from self-improving-agent)
- search.sh: Multi-keyword AND search
- record.sh: Write experience with auto ID generation
- stats.sh: Statistics dashboard
- promote.sh: Tag promotion (≥3 times → TOOLS.md)
- archive.sh: Manual archive old entries
- clean.sh: Cleanup tool
- install.sh / uninstall.sh
- handler.js: Bootstrap hook injection
- Published to ClawHub, GitHub, Gitee

## [1.0.0] - 2026-04-16

### Added
- Forked from pskoett/self-improving-agent v3.0.13
- Renamed to rocky-know-how (经验诀窍)
- Simplified from 400+ lines to ~150 lines
- Chinese localization
